/***************************************************************************
* Copyright (c) 2023, QuantStack
*                                                                          
* Distributed under the terms of the GNU General Public License v3.                 
*                                                                          
* The full license is in the file LICENSE, distributed with this software. 
****************************************************************************/

#ifndef XEUS_R_INTERPRETER_WASM_HPP
#define XEUS_R_INTERPRETER_WASM_HPP

#include "xinterpreter.hpp"
#include "xeus_r_config.hpp"

namespace xeus_r
{
    class XEUS_R_API wasm_interpreter : public interpreter
    {
    public:

        wasm_interpreter();
        virtual ~wasm_interpreter() = default;

    };
}

#endif