..  Copyright (c) 2023,    

   Distributed under the terms of the GNU General Public License v3.  

   The full license is in the file LICENSE, distributed with this software.

Build and configuration
=======================

General Build Options
---------------------

Building the xeus-r library
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``xeus-r`` build supports the following options:

- ``XEUS_R_BUILD_SHARED``: Build the ``xeus-r`` shared library. **Enabled by default**.
- ``XEUS_R_BUILD_STATIC``: Build the ``xeus-r`` static library. **Enabled by default**.


- ``XEUS_R_USE_SHARED_XEUS``: Link with a `xeus` shared library (instead of the static library). **Enabled by default**.

Building the kernel
~~~~~~~~~~~~~~~~~~~

The package includes two options for producing a kernel: an executable ``xr`` and a Python extension module, which is used to launch a kernel from Python.

- ``XEUS_R_BUILD_EXECUTABLE``: Build the ``xr``  executable. **Enabled by default**.


If ``XEUS_R_USE_SHARED_XEUS_R`` is disabled, xr  will be linked statically with ``xeus-r``.

Building the Tests
~~~~~~~~~~~~~~~~~~

- ``XEUS_R_BUILD_TESTS ``: enables the tets  **Disabled by default**.

