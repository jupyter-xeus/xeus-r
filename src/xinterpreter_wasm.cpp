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

namespace xeus_r
{

    wasm_interpreter::wasm_interpreter()
        : interpreter(0, nullptr)
    {
    }
}