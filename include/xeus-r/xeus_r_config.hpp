/***************************************************************************
* Copyright (c) 2023, QuantStack
*
* Distributed under the terms of the GNU General Public License v3.
*
* The full license is in the file LICENSE, distributed with this software.
****************************************************************************/

#ifndef XEUS_R_CONFIG_HPP
#define XEUS_R_CONFIG_HPP

// Project version
#define XEUS_R_VERSION_MAJOR 0
#define XEUS_R_VERSION_MINOR 7
#define XEUS_R_VERSION_PATCH 0

// Composing the version string from major, minor and patch
#define XEUS_R_CONCATENATE(A, B) XEUS_R_CONCATENATE_IMPL(A, B)
#define XEUS_R_CONCATENATE_IMPL(A, B) A##B
#define XEUS_R_STRINGIFY(a) XEUS_R_STRINGIFY_IMPL(a)
#define XEUS_R_STRINGIFY_IMPL(a) #a

#define XEUS_R_VERSION XEUS_R_STRINGIFY(XEUS_R_CONCATENATE(XEUS_R_VERSION_MAJOR,   \
                 XEUS_R_CONCATENATE(.,XEUS_R_CONCATENATE(XEUS_R_VERSION_MINOR,   \
                                  XEUS_R_CONCATENATE(.,XEUS_R_VERSION_PATCH)))))

#ifdef _WIN32
    #ifdef XEUS_R_EXPORTS
        #define XEUS_R_API __declspec(dllexport)
    #else
        #define XEUS_R_API __declspec(dllimport)
    #endif
#else
    #define XEUS_R_API
#endif

#endif
