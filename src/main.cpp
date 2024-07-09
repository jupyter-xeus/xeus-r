/***************************************************************************
* Copyright (c) 2023, QuantStack
*                                                                          
* Distributed under the terms of the GNU General Public License v3.                 
*                                                                          
* The full license is in the file LICENSE, distributed with this software. 
****************************************************************************/



#include <cstdlib>
#include <iostream>
#include <string>
#include <utility>

#ifdef __GNUC__
#include <stdio.h>
#include <execinfo.h>
#include <signal.h>
#include <stdlib.h>
#include <unistd.h>
#endif

#include "xeus/xkernel.hpp"
#include "xeus/xkernel_configuration.hpp"
#include "xeus/xhelper.hpp"

#include "xeus-zmq/xzmq_context.hpp"
#include "xeus-zmq/xserver_zmq.hpp"

#include "xeus-r/xinterpreter.hpp"
#include "xeus-r/xeus_r_config.hpp"

#ifdef __GNUC__
void handler(int sig)
{
    void* array[10];

    // get void*'s for all entries on the stack
    size_t size = backtrace(array, 10);

    // print out all the frames to stderr
    fprintf(stderr, "Error: signal %d:\n", sig);
    backtrace_symbols_fd(array, size, STDERR_FILENO);
    exit(1);
}
#endif

std::unique_ptr<xeus::xlogger> make_file_logger(xeus::xlogger::level log_level) {
    auto logfile = std::getenv("JUPYTER_LOGFILE");
    if (logfile == nullptr) {
        return nullptr;
    }

    return xeus::make_file_logger(log_level, logfile);
}

int main(int argc, char* argv[])
{
    if (xeus::should_print_version(argc, argv))
    {
        std::clog << "xr " << XEUS_R_VERSION  << std::endl;
        return 0;
    }

    // If we are called from the Jupyter launcher, silence all logging. This
    // is important for a JupyterHub configured with cleanup_servers = False:
    // Upon restart, spawned single-user servers keep running but without the
    // std* streams. When a user then tries to start a new kernel, xr
    // will get a SIGPIPE and exit.
    if (std::getenv("JPY_PARENT_PID") != NULL)
    {
        std::clog.setstate(std::ios_base::failbit);
    }

    // Registering SIGSEGV handler
#ifdef __GNUC__
    std::clog << "registering handler for SIGSEGV" << std::endl;
    signal(SIGSEGV, handler);
#endif

    std::unique_ptr<xeus::xcontext> context = xeus::make_zmq_context();

    auto interpreter = std::unique_ptr<xeus_r::interpreter>(new xeus_r::interpreter(argc, argv));

    auto hist = xeus::make_in_memory_history_manager();

    auto logger = xeus::make_console_logger(xeus::xlogger::full, make_file_logger(xeus::xlogger::full));

    std::string connection_filename = xeus::extract_filename(argc, argv);

    if (!connection_filename.empty())
    {
        xeus::xconfiguration config = xeus::load_configuration(connection_filename);

        std::clog << "Instantiating kernel" << std::endl;
        xeus::xkernel kernel(config,
                             xeus::get_user_name(),
                             std::move(context),
                             std::move(interpreter),
                             xeus::make_xserver_default,
                             std::move(hist), 
                             std::move(logger));

        std::cout <<
            "Starting xr kernel...\n\n"
            "If you want to connect to this kernel from an other client, you can use"
            " the " + connection_filename + " file."
            << std::endl;

        kernel.start();
    }
    else
    {
        xeus::xkernel kernel(xeus::get_user_name(),
                             std::move(context),
                             std::move(interpreter),
                             xeus::make_xserver_default);

        std::cout << "Getting config" << std::endl;
        const auto& config = kernel.get_config();
        std::cout << xeus::get_start_message(config) << std::endl;

        kernel.start();
    }

    return 0;
}
