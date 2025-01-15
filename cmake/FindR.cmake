# From https://github.com/Kitware/VTK/blob/master/CMake/FindR.cmake
#
# - This module locates an installed R distribution.
#
# Input:
#  R_LIB_ARCH - For windows (i386 or x64)
#
# Defines the following:
#  R_COMMAND           - Path to R command
#  R_SCRIPT_COMMAND    - Path to RScript command
#  R_HOME              - Path to 'R home', as reported by R
#  R_INCLUDE_DIR       - Path to R include directory
#  R_LIBRARY_BASE      - Path to R library
#  R_LIBRARY_BLAS      - Path to Rblas / blas library
#  R_LIBRARY_LAPACK    - Path to Rlapack / lapack library
#  R_LIBRARY_READLINE  - Path to readline library
#  R_LIBRARIES         - Array of: R_LIBRARY_BASE, R_LIBRARY_BLAS, R_LIBRARY_LAPACK, R_LIBRARY_BASE [, R_LIBRARY_READLINE]
#  R_LDFLAGS           - R CMD config --ldflags
#
# Variable search order:
#   1. Attempt to locate and set R_COMMAND
#     - If unsuccessful, generate error and prompt user to manually set R_COMMAND
#   2. Use R_COMMAND to set R_HOME
#   3. Locate other libraries in the priority:
#     1. Within a user-built instance of R at R_HOME
#     2. Within an installed instance of R
#     3. Within external system libraries
#

if(NOT R_LIB_ARCH)
  if("${CMAKE_SIZEOF_VOID_P}" EQUAL "8")
    set(R_LIB_ARCH x64)
  else()
    set(R_LIB_ARCH i386)
  endif()
endif()

set(TEMP_CMAKE_FIND_APPBUNDLE ${CMAKE_FIND_APPBUNDLE})
set(CMAKE_FIND_APPBUNDLE "NEVER")
find_program(R_COMMAND R DOC "R executable.")
find_program(R_SCRIPT_COMMAND Rscript DOC "Rscript executable.")
set(CMAKE_FIND_APPBUNDLE ${TEMP_CMAKE_FIND_APPBUNDLE})

if(R_COMMAND)
  # temporarily append ".dll" to the cmake find_library suffixes
  set(OLD_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES})
  set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES} ".dll")

  if(CMAKE_SYSTEM_NAME STREQUAL "Emscripten")
    message(STATUS "Configuring for Emscripten...")

    # Find the pkg-config executable
find_program(PKG_CONFIG_EXECUTABLE NAMES pkg-config)

    if (PKG_CONFIG_EXECUTABLE)
        # Get the R version using pkg-config
        execute_process(
            COMMAND env PKG_CONFIG_PATH=${CMAKE_PREFIX_PATH}/lib/pkgconfig ${PKG_CONFIG_EXECUTABLE} --modversion libR
            OUTPUT_VARIABLE R_VERSION
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )

        # Extract the major, minor, and patch version numbers
        string(REGEX MATCH "([0-9]+)\\.([0-9]+)\\.([0-9]+)" _ ${R_VERSION})
        set(R_VERSION_MAJOR ${CMAKE_MATCH_1})
        set(R_VERSION_MINOR ${CMAKE_MATCH_2}.${CMAKE_MATCH_3})

        message(STATUS "Found R version ${R_VERSION_MAJOR}.${R_VERSION_MINOR}")
    else()
        message(FATAL_ERROR "pkg-config executable not found")
    endif()

    set(R_HOME "${CMAKE_PREFIX_PATH}/lib/R" CACHE PATH "R home directory for Emscripten")

    set(R_INCLUDE_DIR "${R_HOME}/include" CACHE PATH "Path to R include directory")

    set(R_LDFLAGS "-L${CMAKE_PREFIX_PATH}/lib -L${CMAKE_PREFIX_PATH}/lib/R/lib -lRblas -lFortranRuntime -lpcre2-8 -llzma -lbz2 -lz -lrt -ldl -lm -liconv" CACHE STRING "Linker flags for R libraries in Emscripten")

    set(R_LIBRARY_BASE "${R_HOME}/lib/libR.a" CACHE FILEPATH "R library (libR.a) in Emscripten")

    set(R_LIBRARY_BLAS "${R_HOME}/lib/libRblas.so" CACHE FILEPATH "Rblas library (libRblas.so) in Emscripten")

    set(R_LIBRARY_LAPACK "${R_HOME}/lib/libRlapack.so" CACHE FILEPATH "Rlapack library (libRlapack.so) in Emscripten")

  else()
    message(STATUS "Configuring for non-Emscripten environment...")

    execute_process(COMMAND ${R_SCRIPT_COMMAND} -e "cat(R.Version()$major)"
                    OUTPUT_VARIABLE R_VERSION_MAJOR
                    OUTPUT_STRIP_TRAILING_WHITESPACE)

    execute_process(COMMAND ${R_SCRIPT_COMMAND} -e "cat(R.Version()$minor)"
                    OUTPUT_VARIABLE R_VERSION_MINOR
                    OUTPUT_STRIP_TRAILING_WHITESPACE)

    set(R_VERSION_MAJOR ${R_VERSION_MAJOR} CACHE STRING "Major version of R")
    set(R_VERSION_MINOR ${R_VERSION_MINOR} CACHE STRING "Minor version of R")

    execute_process(WORKING_DIRECTORY .
                    COMMAND ${R_COMMAND} RHOME
                    OUTPUT_VARIABLE R_ROOT_DIR
                    OUTPUT_STRIP_TRAILING_WHITESPACE)

    set(R_HOME ${R_ROOT_DIR} CACHE PATH "R home directory obtained from R RHOME")

    execute_process(WORKING_DIRECTORY .
                    COMMAND ${R_COMMAND} CMD config --ldflags
                    OUTPUT_VARIABLE R_LDFLAGS
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    set(R_LDFLAGS ${R_LDFLAGS} CACHE PATH "R CMD config --ldflags")

    find_path(R_INCLUDE_DIR R.h
              HINTS ${R_ROOT_DIR} ${R_ROOT_DIR}/bin/${R_LIB_ARCH}
              PATHS /usr/local/lib /usr/local/lib64 /usr/share
              PATH_SUFFIXES include R/include
              DOC "Path to file R.h")

    find_library(R_LIBRARY_BASE R
                 HINTS ${R_ROOT_DIR}/lib ${R_ROOT_DIR}/bin/${R_LIB_ARCH}
                 DOC "R library (example libR.a, libR.dylib, etc.).")

    find_library(R_LIBRARY_BLAS NAMES Rblas blas
                 HINTS ${R_ROOT_DIR}/lib ${R_ROOT_DIR}/bin/${R_LIB_ARCH}
                 DOC "Rblas library (example libRblas.a, libRblas.dylib, etc.).")

    find_library(R_LIBRARY_LAPACK NAMES Rlapack lapack
                 HINTS ${R_ROOT_DIR}/lib ${R_ROOT_DIR}/bin/${R_LIB_ARCH}
                 DOC "Rlapack library (example libRlapack.a, libRlapack.dylib, etc.).")

    find_library(R_LIBRARY_READLINE readline
                 DOC "(Optional) system readline library. Only required if the R libraries were built with readline support.")
  endif()

  # reset cmake find_library to initial value
  set(CMAKE_FIND_LIBRARY_SUFFIXES ${OLD_SUFFIXES})

else()
  message(SEND_ERROR "FindR.cmake requires the following variables to be set: R_COMMAND")
endif()

# Note: R_LIBRARY_BASE is added to R_LIBRARIES twice; this may be due to circular linking dependencies; needs further investigation
set(R_LIBRARIES ${R_LIBRARY_BASE} ${R_LIBRARY_BLAS} ${R_LIBRARY_LAPACK} ${R_LIBRARY_BASE})
if(R_LIBRARY_READLINE)
  set(R_LIBRARIES ${R_LIBRARIES} ${R_LIBRARY_READLINE})
endif()