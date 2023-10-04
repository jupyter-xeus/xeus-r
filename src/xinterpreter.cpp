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
#include "R.h"
#include "Rinternals.h"
#include "Rembedded.h"
#include "R_ext/Parse.h"

namespace nl = nlohmann;

namespace xeus_r
{
 
    interpreter::interpreter(int argc, char* argv[])
    {
        Rf_initEmbeddedR(argc, argv);
        xeus::register_interpreter(this);
    }

    nl::json interpreter::execute_request_impl(int execution_counter,    // Typically the cell number
                                               const std::string & /*code*/, // Code to execute
                                               bool /*silent*/,
                                               bool /*store_history*/,
                                               nl::json /*user_expressions*/,
                                               bool /*allow_stdin*/)
    {
        // Use this method for publishing the execution result to the client,
        // this method takes the ``execution_counter`` as first argument,
        // the data to publish (mime type data) as second argument and metadata
        // as third argument.
        // Replace "Hello World !!" by what you want to be displayed under the execution cell
        nl::json pub_data;

        SEXP msg = PROTECT(Rf_mkString("bonjour"));
        pub_data["text/plain"] = CHAR(STRING_ELT(msg, 0));
        UNPROTECT(1);

        // If silent is set to true, do not publish anything!
        // Otherwise:
        // Publish the execution result
        publish_execution_result(execution_counter, std::move(pub_data), nl::json::object());

        // You can also use this method for publishing errors to the client, if the code
        // failed to execute
        // publish_execution_error(error_name, error_value, error_traceback);
        publish_execution_error("TypeError", "123", {"!@#$", "*(*"});

        // Use publish_stream to publish a stream message or error:
        publish_stream("stdout", "I am publishing a message");
        publish_stream("stderr", "Error!");

        // Use Helpers that create replies to the server to be returned
        return xeus::create_successful_reply(/*payload, user_expressions*/);
        // Or in case of error:
        //return xeus::create_error_reply(evalue, ename, trace_back);
    }

    void interpreter::configure_impl()
    {
        // `configure_impl` allows you to perform some operations
        // after the custom_interpreter creation and before executing any request.
        // This is optional, but can be useful;
        // you can for example initialize an engine here or redirect output.
    }

    nl::json interpreter::is_complete_request_impl(const std::string& code)
    {
        SEXP s_code = PROTECT(Rf_mkString(code.c_str()));
        ParseStatus status;

        // Currently ignore the result of R_ParseVector, and only care about status
        R_ParseVector(s_code, -1, &status, R_NilValue);
        UNPROTECT(1); // s_code

        switch(status) {
            case PARSE_EOF:
            case PARSE_NULL:
            case PARSE_OK:
                return xeus::create_is_complete_reply("complete", "");

            case PARSE_INCOMPLETE:
                /*
                    // if instead of R_NilValue in the R_ParseVector() call, 
                    // we use an environment, we might be able to 
                    // retrieve information about the parse tree 
                    // from which we can derive some heuristic about indentation for the 
                    // next line 

                    > srcfile <- new.env()
                    > parse(text = "for(i in 1:3){", srcfile = srcfile)
                    Erreur dans parse(text = "for(i in 1:3){", srcfile = srcfile) :
                    2:0: fin d'entrée inattendue
                    1: for(i in 1:3){
                    ^
                    > srcfile$parseData
                        [,1] [,2] [,3] [,4] [,5] [,6] [,7] [,8] [,9] [,10] [,11] [,12] [,13]
                    [1,]    1    1    1    1    1    1    1    1    1     1     1     1     1
                    [2,]    1    4    5    7   10   10   11   12   12    13    10     4    14
                    [3,]    1    1    1    1    1    1    1    1    1     1     1     1     1
                    [4,]    3    4    5    8   10   10   11   12   12    13    12    13    14
                    [5,]    1    1    1    1    1    0    1    1    0     1     0     0     1
                    [6,]  270   40  263  271  261   79   58  261   79    41    79    82   123
                    [7,]    1    2    3    4    5    6    7    8    9    10    11    13    14
                    [8,]    0   13   13   13    6   11   11    9   11    13    13     0     0
                    attr(,"tokens")
                    [1] "FOR"       "'('"       "SYMBOL"    "IN"        "NUM_CONST" "expr"
                    [7] "':'"       "NUM_CONST" "expr"      "')'"       "expr"      "forcond"
                    [13] "'{'"
                    attr(,"text")
                    [1] "for" "("   "i"   "in"  "1"   ""    ":"   "3"   ""    ")"   ""    ""
                    [13] "{"
                    attr(,"class")
                    [1] "parseData"
                */
        
                return xeus::create_is_complete_reply("incomplete", "  ");

            case PARSE_ERROR:
                return xeus::create_is_complete_reply("invalid", "  ");
        }
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
