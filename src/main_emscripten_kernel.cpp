/***************************************************************************
* Copyright (c) 2023, QuantStack
*                                                                          
* Distributed under the terms of the GNU General Public License v3.                 
*                                                                          
* The full license is in the file LICENSE, distributed with this software. 
****************************************************************************/

#include <iostream>
#include <memory>

#include <emscripten/bind.h>

#include <xeus/xembind.hpp>

#include "xeus-r/xinterpreter_wasm.hpp"

EMSCRIPTEN_BINDINGS(my_module)
{
    xeus::export_core();
    using interpreter_type = xeus_r::wasm_interpreter;
    xeus::export_kernel<interpreter_type>("xkernel");
}