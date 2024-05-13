/***************************************************************************
* Copyright (c) 2023, QuantStack
*                                                                          
* Distributed under the terms of the GNU General Public License v3.                 
*                                                                          
* The full license is in the file LICENSE, distributed with this software. 
****************************************************************************/

#include <string>
#include <vector>
#include <iostream>

#include "nlohmann/json.hpp"

#include "xeus/xinput.hpp"
#include "xeus/xinterpreter.hpp"
#include "xeus/xhelper.hpp"

#include "xeus-r/xinterpreter.hpp"

#define R_NO_REMAP
#define R_INTERFACE_PTRS

#include "R.h"
#include "Rinternals.h"
#include "Rembedded.h"
#include "R_ext/Parse.h"
#include "Rinterface.h"
#include "rtools.hpp"

namespace xeus_r {

static interpreter* p_interpreter = nullptr;
static SEXP env_hera = nullptr;

#define CHECK_HERA_AVAILABLE()                    \
    if (env_hera == nullptr) {                    \
        return xeus::create_error_reply(          \
            "R package {hera} is not available",  \
            "R package {hera} is not available",  \
            {}                                    \
        );                                        \
    }

template <class... Types>
SEXP invoke_hera_fn(const char* f, Types... args){

    SEXP fn = PROTECT(Rf_findVarInFrame(env_hera, Rf_install(f)));
    SEXP call = PROTECT(r::r_call(fn, args...));
    SEXP result = Rf_eval(call, R_GlobalEnv);

    UNPROTECT(2);

    return result;
}

interpreter* get_interpreter() {
    return p_interpreter;
}

void WriteConsoleEx(const char *buf, int buflen, int otype) {
    std::string output(buf, buflen);
    if (otype == 1) {
        p_interpreter->publish_stream("stderr", output);
    } else {
        p_interpreter->publish_stream("stdout", output);
    }
}

void capture_WriteConsoleEx(const char *buf, int buflen, int otype) {
    std::string output(buf, buflen);
    if (otype == 1) {
        // do nothing
    } else {
        p_interpreter->capture_stream << output;
    }
}

interpreter::interpreter(int argc, char* argv[])
{
    Rf_initEmbeddedR(argc, argv);
    register_r_routines();

    R_Outputfile = NULL;
    R_Consolefile = NULL;

    ptr_R_WriteConsole = nullptr;
    ptr_R_WriteConsoleEx = WriteConsoleEx;
    
    xeus::register_interpreter(this);
    p_interpreter = this;
}

std::unique_ptr<interpreter> make_interpreter(int argc, char* argv[]) {
    return std::unique_ptr<interpreter>(new interpreter(argc, argv));
}

nl::json interpreter::execute_request_impl(int execution_counter,    // Typically the cell number
                                            const std::string & code, // Code to execute
                                            bool silent,
                                            bool store_history,
                                            nl::json /*user_expressions*/,
                                            bool /*allow_stdin*/)
{
    CHECK_HERA_AVAILABLE()
    
    if (store_history) {
        const_cast<xeus::xhistory_manager&>(get_history_manager()).store_inputs(0, execution_counter, code);
    }

    SEXP code_ = PROTECT(Rf_mkString(code.c_str()));
    SEXP execution_counter_ = PROTECT(Rf_ScalarInteger(execution_counter));
    SEXP silent_ = PROTECT(Rf_ScalarLogical(silent));

    SEXP result = invoke_hera_fn("execute", code_, execution_counter_, silent_);
    
    if (Rf_inherits(result, "error_reply")) {
        std::string evalue = CHAR(STRING_ELT(VECTOR_ELT(result, 0), 0));
        std::string ename = CHAR(STRING_ELT(VECTOR_ELT(result, 1), 0));

        std::vector<std::string> trace_back;
        if (XLENGTH(result) > 2) {
            SEXP trace_back_ = VECTOR_ELT(result, 2);
            auto n = XLENGTH(trace_back_);
            for (decltype(n) i = 0; i < n; i++) {
                trace_back.push_back(CHAR(STRING_ELT(trace_back_, i)));
            }
        }

        publish_execution_error(evalue, ename, trace_back);

        UNPROTECT(3);
        return xeus::create_error_reply(evalue, ename, std::move(trace_back));
    }
    
    if (Rf_inherits(result, "execution_result")) {
        SEXP data_ = VECTOR_ELT(result, 0);
        SEXP metadata_ = VECTOR_ELT(result, 1);
        auto data = nl::json::parse(CHAR(STRING_ELT(data_, 0)));
        auto metadata = nl::json::parse(CHAR(STRING_ELT(metadata_, 0)));
        publish_execution_result(execution_counter, data, metadata);
    }

    UNPROTECT(3);
    return xeus::create_successful_reply(/*payload, user_expressions*/);
}

void interpreter::configure_impl()
{
    SEXP sym_library = Rf_install("library");
    SEXP chr_hera = PROTECT(Rf_mkString("hera"));
    SEXP call_library_hera = PROTECT(Rf_lang2(sym_library, chr_hera));

    SEXP sym_try = Rf_install("try");
    SEXP sym_silent = Rf_install("silent");
    SEXP call_try = PROTECT(Rf_lang3(sym_try, call_library_hera, Rf_ScalarLogical(TRUE)));
    SET_TAG(CDDR(call_try), sym_silent);

    SEXP loaded = PROTECT(Rf_eval(call_try, R_GlobalEnv));
    if (!Rf_inherits(loaded, "try-error")) {
        SEXP sym_asNamespace = Rf_install("asNamespace");
        SEXP call_as_Namespace = PROTECT(Rf_lang2(sym_asNamespace, chr_hera));

        env_hera = PROTECT(Rf_eval(call_as_Namespace, R_GlobalEnv));
        R_PreserveObject(env_hera);
        UNPROTECT(2);
    }

    UNPROTECT(4);
}

nl::json interpreter::is_complete_request_impl(const std::string& code_)
{
    // initially code holds the string, but then it is being 
    // replaced by incomplete, invalid or complete either in the 
    // body handler or the error handler
    SEXP code = PROTECT(Rf_mkString(code_.c_str()));

    // we can't simply use an R callback because the R parse(text =)
    // approach does not distinguish between invalid code and
    // incomplete: they both just throw an error
    R_tryCatchError(
        [](void* void_code) { // body
            ParseStatus status;
            SEXP code = reinterpret_cast<SEXP>(void_code);

            R_ParseVector(code, -1, &status, R_NilValue);

            switch(status) {
                case PARSE_INCOMPLETE:
                    SET_STRING_ELT(code, 0, Rf_mkChar("incomplete"));
                    break;
                    
                case PARSE_ERROR:
                    SET_STRING_ELT(code, 0, Rf_mkChar("invalid"));
                    break;

                default:
                    SET_STRING_ELT(code, 0, Rf_mkChar("complete"));
            }

            return R_NilValue;
        }, 
        reinterpret_cast<void*>(code), 

        [](SEXP, void* void_code) { // handler
            // some parse error cases are not propagated to PARSE_ERROR
            // but rather throw an error, so we need to catch it 
            // and set the result to invalid
            SEXP code = reinterpret_cast<SEXP>(void_code);
            SET_STRING_ELT(code, 0, Rf_mkChar("invalid"));

            return R_NilValue;
        }, 
        reinterpret_cast<void*>(code)
    );

    // eventually we just have to extract the string from code (which has been replaced)
    auto result = xeus::create_is_complete_reply(CHAR(STRING_ELT(code, 0)), "");
    UNPROTECT(1);
    return result;
}

nl::json json_from_character_vector(SEXP x) {
    auto n = XLENGTH(x);
    std::vector<std::string> vec(n);

    for (decltype(n) i = 0; i < n; i++) {
        vec[i] = std::string(CHAR(STRING_ELT(x, i)));
    }
    return nl::json(vec);
}

nl::json interpreter::complete_request_impl(const std::string& code, int cursor_pos)
{
    CHECK_HERA_AVAILABLE()

    SEXP code_ = PROTECT(Rf_mkString(code.c_str()));
    SEXP cursor_pos_ = PROTECT(Rf_ScalarInteger(cursor_pos));

    SEXP result = PROTECT(invoke_hera_fn("complete", code_, cursor_pos_));

    auto matches = json_from_character_vector(VECTOR_ELT(result, 0));
    int cursor_start = INTEGER_ELT(VECTOR_ELT(result, 1), 0);
    int cursor_end = INTEGER_ELT(VECTOR_ELT(result, 1), 1);

    auto reply = xeus::create_complete_reply(
        matches, cursor_start, cursor_end
    );

    UNPROTECT(3); // result, cursor_pos_, code_
    return reply;
}

nl::json interpreter::inspect_request_impl(const std::string& code, int cursor_pos, int /*detail_level*/)
{
    CHECK_HERA_AVAILABLE()

    SEXP code_ = PROTECT(Rf_mkString(code.c_str()));
    SEXP cursor_pos_ = PROTECT(Rf_ScalarInteger(cursor_pos));

    SEXP result = PROTECT(invoke_hera_fn("inspect", code_, cursor_pos_));
    bool found = LOGICAL_ELT(VECTOR_ELT(result, 0), 0);
    if (!found) {
        UNPROTECT(3);
        return xeus::create_inspect_reply(false);
    }

    auto data = nl::json::parse(CHAR(STRING_ELT(VECTOR_ELT(result, 1), 0)));
    
    UNPROTECT(3); // result, code_, cursor_pos_
    return xeus::create_inspect_reply(found, data);
}

void interpreter::shutdown_request_impl() {
    Rf_endEmbeddedR(0);
    std::cout << "Bye!!" << std::endl;
}

nl::json interpreter::kernel_info_request_impl()
{

    const std::string  protocol_version = "5.3";
    const std::string  implementation = "xr";
    const std::string  implementation_version = XEUS_R_VERSION;
    const std::string  language_name = "R";
    const std::string  language_version = "4.3.1";
    const std::string  language_mimetype = "text/x-R";;
    const std::string  language_file_extension = "R";;
    const std::string  language_pygments_lexer = "";
    const std::string  language_codemirror_mode = "";
    const std::string  language_nbconvert_exporter = "";
    const std::string  banner = "xr";
    const bool         debugger = false;
    const nl::json     help_links = nl::json::array();

    return xeus::create_info_reply(
        protocol_version,
        implementation,
        implementation_version,
        language_name,
        language_version,
        language_mimetype,
        language_file_extension,
        language_pygments_lexer,
        language_codemirror_mode,
        language_nbconvert_exporter,
        banner,
        debugger,
        help_links
    );
}

}
