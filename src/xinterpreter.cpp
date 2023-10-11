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

extern Rboolean R_Visible;

namespace xeus_r {

static interpreter* p_interpreter = nullptr;

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
        p_interpreter->capture_stream << output;
    } else {
        p_interpreter->capture_stream << output;
    }
}

namespace {

SEXP try_parse(const std::string& code, int execution_counter) {
    // call in R:
    // > tryCatch(parse(text = <code>, srcfile = "<cell [<execution_counter>]"), error = identity)
    //
    // the assumption is that this either gives:
    // - and error when the code can't be parsed for some reason
    // - the parsed expressions, as a EXPRSXP vector
    //
    SEXP smb_tryCatch = Rf_install("tryCatch");
    SEXP smb_identity = Rf_install("identity");
    SEXP smb_parse    = Rf_install("parse");
    SEXP smb_text     = Rf_install("text");
    SEXP smb_error    = Rf_install("error");
    SEXP smb_srcfile  = Rf_install("srcfile");
    
    SEXP str_code = PROTECT(Rf_mkString(code.c_str()));
    
    std::stringstream ss;
    ss << "<cell [" << execution_counter << "]>";

    SEXP str_cell = PROTECT(Rf_mkString(ss.str().c_str()));
    SEXP call_parse = PROTECT(Rf_lang3(smb_parse, str_code, str_cell));
    SET_TAG(CDR(call_parse), smb_text);
    SET_TAG(CDDR(call_parse), smb_srcfile);

    SEXP call_tryCatch = PROTECT(Rf_lang3(smb_tryCatch, call_parse, smb_identity));
    SET_TAG(CDDR(call_tryCatch), smb_error);

    SEXP parsed = Rf_eval(call_tryCatch, R_BaseEnv);

    UNPROTECT(4);
    return parsed;
}

}

    interpreter::interpreter(int argc, char* argv[])
    {
        Rf_initEmbeddedR(argc, argv);

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
        // TODO: maybe .xeus_try_catch() could just receive code and we deal with parsing on the R side 
        
        // First we need to parse the code
        SEXP parsed = PROTECT(try_parse(code, execution_counter));
        if (Rf_inherits(parsed, "error")) {
            auto err_msg = CHAR(STRING_ELT(VECTOR_ELT(parsed, 0),0));
            publish_execution_error("ParseError", err_msg, {code});

            UNPROTECT(1); // parsed
            return xeus::create_error_reply();
        }

        SEXP smb_xeus_try_catch = Rf_install(".xeus_try_catch");
        SEXP call_xeus_try_catch = PROTECT(Rf_lang2(smb_xeus_try_catch, parsed));
        SEXP result = PROTECT(Rf_eval(call_xeus_try_catch, R_GlobalEnv));

        if (Rf_inherits(result, "xeus_error")) {
            // This was an error
            
            // SEXP condition = VECTOR_ELT(result, 0);
            // SEXP calls = VECTOR_ELT(result, 1);

            // do something with condition and calls
            publish_execution_error("EvalError", "ouch ouch", {"ouch", "aie"});
        } else {
            // handle visibility
            SEXP value = VECTOR_ELT(result, 0);
            bool visible = LOGICAL(VECTOR_ELT(result, 1))[0];
            if (visible) {
                capture_stream.str("");
                ptr_R_WriteConsoleEx = capture_WriteConsoleEx;
                Rf_PrintValue(value);
                ptr_R_WriteConsoleEx = WriteConsoleEx;

                nl::json pub_data;
                pub_data["text/plain"] = capture_stream.str();
                publish_execution_result(execution_counter, std::move(pub_data), nl::json::object());
            }
        }

        UNPROTECT(3);
        return xeus::create_successful_reply(/*payload, user_expressions*/);
    }

    void interpreter::configure_impl()
    {
        // TODO: .xeus_try_catch or something similar belongs in a package
        const char* try_catch = ".xeus_try_catch <- function(expr) {.xeus_sys_calls <- NULL; tryCatch(withCallingHandlers(withVisible(eval(expr)), error = function(condition){sys_calls <- sys.calls();sys_calls <- sys_calls[seq(10, length(sys_calls) - 2)];.xeus_sys_calls <<- sys_calls}), error = function(condition) { structure(list(condition = condition, calls = .xeus_sys_calls), class = 'xeus_error')})}";
        R_ParseEvalString(try_catch, R_GlobalEnv);
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
        const std::string  banner = "xr";const bool         debugger = false;
        
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
