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
#include "xeus-r/rtools.hpp"

namespace xeus_r {

static interpreter* p_interpreter = nullptr;

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

nl::json interpreter::execute_request_impl(int execution_counter,    // Typically the cell number
                                            const std::string & code, // Code to execute
                                            bool /*silent*/,
                                            bool /*store_history*/,
                                            nl::json /*user_expressions*/,
                                            bool /*allow_stdin*/)
{
    SEXP code_ = PROTECT(Rf_mkString(code.c_str()));
    SEXP execution_counter_ = PROTECT(Rf_ScalarInteger(execution_counter));

    SEXP result = r::invoke_xeusr_fn("execute", code_, execution_counter_);

    UNPROTECT(2);

    return xeus::create_successful_reply(/*payload, user_expressions*/);
}

void interpreter::configure_impl()
{
    SEXP sym_Sys_which = Rf_install("Sys.which");
    SEXP sym_dirname = Rf_install("dirname");
    SEXP str_xr = Rf_mkString("xr");
    SEXP call_Sys_which = PROTECT(Rf_lang2(sym_Sys_which, str_xr));
    SEXP call = PROTECT(Rf_lang2(sym_dirname, call_Sys_which));
    SEXP dir_xr = Rf_eval(call, R_GlobalEnv);
    
    std::stringstream ss;
    ss << CHAR(STRING_ELT(dir_xr, 0)) << "/../share/jupyter/kernels/xr/resources/setup.R";
    SEXP setup_R_code_path = PROTECT(Rf_mkString(ss.str().c_str()));

    SEXP sym_source = Rf_install("source");
    SEXP call_source = PROTECT(Rf_lang2(sym_source, setup_R_code_path));
    Rf_eval(call_source, R_GlobalEnv);

    UNPROTECT(4);

    r::invoke_xeusr_fn("configure");
}

nl::json interpreter::is_complete_request_impl(const std::string& /*code*/)
{
    // Insert code here to validate the ``code``
    // and use `create_is_complete_reply` with the corresponding status
    // "unknown", "incomplete", "invalid", "complete"
    return xeus::create_is_complete_reply("complete"/*status*/, "   "/*indent*/);
}

nl::json interpreter::complete_request_impl(const std::string&  code,
                                                    int cursor_pos)
{
    // Should be replaced with code performing the completion
    // and use the returned `matches` to `create_complete_reply`
    // i.e if the code starts with 'H', it could be the following completion
    if (code[0] == 'H')
    {
    
        return xeus::create_complete_reply(
            {
                std::string("Hello"), 
                std::string("Hey"), 
                std::string("Howdy")
            },          /*matches*/
            5,          /*cursor_start*/
            cursor_pos  /*cursor_end*/
        );
    }

    // No completion result
    else
    {

        return xeus::create_complete_reply(
            nl::json::array(),  /*matches*/
            cursor_pos,         /*cursor_start*/
            cursor_pos          /*cursor_end*/
        );
    }
}

nl::json interpreter::inspect_request_impl(const std::string& /*code*/,
                                                    int /*cursor_pos*/,
                                                    int /*detail_level*/)
{
    
    return xeus::create_inspect_reply(true/*found*/, 
        {{std::string("text/plain"), std::string("hello!")}}, /*data*/
        {{std::string("text/plain"), std::string("hello!")}}  /*meta-data*/
    );
        
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
