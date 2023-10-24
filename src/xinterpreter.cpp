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
#include <unistd.h> 

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
        // do nothing
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
        // First we need to parse the code
        SEXP parsed = PROTECT(try_parse(code, execution_counter));
        if (Rf_inherits(parsed, "error")) {
            auto err_msg = CHAR(STRING_ELT(VECTOR_ELT(parsed, 0),0));
            publish_execution_error("ParseError", err_msg, {err_msg});

            UNPROTECT(1); // parsed
            return xeus::create_error_reply();
        }

        R_xlen_t i = 0;
        R_xlen_t n = XLENGTH(parsed);
        
        // first evaluate all expressions but the last
        for (; i < n - 1; i++) {
            SEXP expr = VECTOR_ELT(parsed, i);

            int ErrorOccurred;
            SEXP result = PROTECT(R_tryEval(expr, R_GlobalEnv, &ErrorOccurred));

            if (ErrorOccurred) {
                // the error has been printed as part of stderr, at least until we
                // figure out a way to handle it and propagate it with publish_execution_error()
                // so there is nothing further to do

                UNPROTECT(2); // result, expr

                // TODO: replace with some sort of traceback with publish_execution_error()
                UNPROTECT(2); // out, parsed
                return xeus::create_successful_reply(/*payload, user_expressions*/);
            }

        }
        
        // for the last expression, we *might* need to print the result
        // so we wrap the call in a `withVisible()` so that we can figure out 
        // its visibility. It seems we cannot use the internal R way of 
        // doing this with the R_Visible extern variable :shrug:
        // 
        // The downside of this is that this injects a `withVisible()` call
        // in the call stack (#10). So we need to deal with it later, e.g.
        // when dealing with the traceback 
        SEXP smb_withVisible = Rf_install("withVisible");
        SEXP expr = PROTECT(Rf_lang2(smb_withVisible, VECTOR_ELT(parsed, i)));
            
        int ErrorOccurred;
        SEXP result = PROTECT(R_tryEval(expr, R_GlobalEnv, &ErrorOccurred));

        if (ErrorOccurred) {
            // the error has been printed as part of stderr, at least until we
            // figure out a way to handle it and propagate it with publish_execution_error()
            // so there is nothing further to do

            UNPROTECT(2); // result, expr
        } else {
            // there was no error - so print the result if it is visible
            // We get a list of two things: 
            // 1) the result: can be any R object
            SEXP value = PROTECT(VECTOR_ELT(result, 0));

            // 2) whether it is visible: a scalar LGLSXP
            bool visible = LOGICAL(VECTOR_ELT(result, 1))[0];

            if (visible) {
                // the code did not generate an uncaught error and 
                // the result is visible, so we need to display it
                //
                // For now, this means print() it which we do by 
                // calling the internal print() function Rf_PrintValue
                // and intercept what would be printed in the console
                // using capture_WriteConsoleEx instead of the regular 
                // WriteConsoleEx
                capture_stream.str("");
                ptr_R_WriteConsoleEx = capture_WriteConsoleEx;
                R_ToplevelExec([](void* value) {
                    Rf_PrintValue((SEXP)value);
                }, (void*)value);
                
                // restore the normal printing to the console
                ptr_R_WriteConsoleEx = WriteConsoleEx;
                
                nl::json pub_data;
                pub_data["text/plain"] = capture_stream.str();
                publish_execution_result(execution_counter, std::move(pub_data), nl::json::object());
            }
            
            UNPROTECT(3); // value, result, expr
        }

        
        UNPROTECT(2); // parsed, out
        
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
        ss << CHAR(STRING_ELT(dir_xr, 0)) << "/../share/jupyter/kernels/xr/R/xeus-r.R";

        SEXP xeus_R_code_path = PROTECT(Rf_mkString(ss.str().c_str()));
        SEXP sym_source = Rf_install("source");
        SEXP call_source = PROTECT(Rf_lang2(sym_source, xeus_R_code_path));
        SEXP result = Rf_eval(call_source, R_GlobalEnv);

        UNPROTECT(4);
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
