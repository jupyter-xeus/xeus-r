/***************************************************************************
* Copyright (c) 2023, QuantStack
*                                                                          
* Distributed under the terms of the GNU General Public License v3.                 
*                                                                          
* The full license is in the file LICENSE, distributed with this software. 
****************************************************************************/


#ifndef XEUS_R_INTERPRETER_HPP
#define XEUS_R_INTERPRETER_HPP

#ifdef __GNUC__
    #pragma GCC diagnostic push
    #pragma GCC diagnostic ignored "-Wattributes"
#endif

#include <string>
#include <memory>

#include "nlohmann/json.hpp"

#include "xeus_r_config.hpp"
#include "xeus/xinterpreter.hpp"

namespace nl = nlohmann;

namespace xeus_r
{
    class XEUS_R_API interpreter : public xeus::xinterpreter
    {
    public:
        interpreter() = delete;
        interpreter(int argc, char* argv[]);
        virtual ~interpreter() = default;

        std::stringstream capture_stream;

    protected:

        void configure_impl() override;

        void execute_request_impl(
            send_reply_callback cb,
            int execution_counter,
            const std::string& code,
            xeus::execute_request_config config,
            nl::json user_expressions
        ) override;
                                      
        nl::json complete_request_impl(const std::string& code, int cursor_pos) override;

        nl::json inspect_request_impl(const std::string& code,
                                      int cursor_pos,
                                      int detail_level) override;

        nl::json is_complete_request_impl(const std::string& code) override;

        nl::json kernel_info_request_impl() override;

        void shutdown_request_impl() override;

    };

    interpreter* get_interpreter();
    void register_r_routines();
}

#ifdef __GNUC__
    #pragma GCC diagnostic pop
#endif

#endif
