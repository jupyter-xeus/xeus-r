/***************************************************************************
* Copyright (c) 2023, QuantStack
*                                                                          
* Distributed under the terms of the GNU General Public License v3.                 
*                                                                          
* The full license is in the file LICENSE, distributed with this software. 
****************************************************************************/

#include "xeus/xinterpreter.hpp"
#include "xeus/xsystem.hpp"

#include "xeus-r/xinterpreter.hpp"
#include "xeus-r/xinterpreter_wasm.hpp"

#include <emscripten/val.h>

namespace xeus_r
{

    emval make_function(const std::string & params, const std::string & body) {
    return emval::global("Function").new_(params, body);
    }

    wasm_interpreter::wasm_interpreter()
        :   interpreter(0, nullptr),
            m_download_file_function(make_function("url, quiet, cacheOK, headers",
                R""""(
                    {
                        function errorToString(error) {
                            try {
                                if (!error) return "Unknown error";

                                // If it's already a string
                                if (typeof error === "string") return error;

                                // If it's a standard Error object
                                if (error instanceof Error) {
                                return [
                                    error.name || "Error",
                                    error.message || "",
                                    error.stack || ""
                                ].filter(Boolean).join(": ");
                                }

                                // If it has message / stack properties but isn’t an Error instance
                                if (typeof error === "object") {
                                const name = error.name || "Error";
                                const message = error.message || JSON.stringify(error);
                                const stack = error.stack || "";
                                return [name, message, stack].filter(Boolean).join(": ");
                                }

                                // Fallback for unexpected types
                                return String(error);
                            } catch (e) {
                                // Absolute last resort
                                return "Error serializing exception: " + String(e);
                            }
                        }


                        try{
                            var xhr = new XMLHttpRequest();
                            xhr.open("GET", url, false);
                            xhr.responseType = "arraybuffer";
         
                            for (var key in headers) {
                                console.log("Setting request header:", key, headers[key]);
                                xhr.setRequestHeader(key, headers[key]);
                            }

                            if(!cacheOK)
                            {
                                // atm we do nothing in that case
                            }

                            xhr.send();

                            // check status
                            if (xhr.status !== 200) {
                                return {
                                    has_error: true,
                                    error_msg: `Download failed with status: ${xhr.status}`
                                };
                            }

                            // Convert response to Uint8Array
                            var arrayBuffer = xhr.response;
                            if (!arrayBuffer) {
                                return {
                                    has_error: true,
                                    error_msg: "No response received"
                                };
                            }

                            return {
                                has_error: false,
                                data: arrayBuffer
                            };

                        } catch (e) {
                            return {
                                has_error: true,
                                error_msg: errorToString(e)
                            };
                        }
                    }
                )""""

            ))
    {
    }
}