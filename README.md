# ![xeus-r](docs/source/xeus-logo.svg)

[![Build Status](https://github.com/jupyter-xeus/xeus-r/actions/workflows/main.yml/badge.svg)](https://github.com/jupyter-xeus/xeus-r/actions/workflows/main.yml) [![Documentation Status](http://readthedocs.org/projects/xeus-r/badge/?version=latest)](https://xeus-r.readthedocs.io/en/latest/?badge=latest) [![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/jupyter-xeus/xeus-r/main?urlpath=/lab/tree/notebooks/xeus-r.ipynb)

`xeus-r` is a Jupyter kernel for R based on the native implementation of the
Jupyter protocol [xeus](https://github.com/jupyter-xeus/xeus).

## Installation

xeus-r has been packaged for the mamba (or conda) package manager on the Linux, Windows, and OS X platforms.

To ensure that the installation works, it is preferable to install `xeus-r` in a
fresh environment. It is also needed to use a
[miniforge](https://github.com/conda-forge/miniforge#mambaforge) or
[miniconda](https://conda.io/miniconda.html) installation because with the full
[anaconda](https://www.anaconda.com/) you may have a conflict with the `zeromq` library
which is already installed in the anaconda distribution.

### Installation with mamba or conda

The safest usage is to create an environment named `xeus-r`

```bash
mamba create -n xeus-r
mamba activate xeus-r
```

Then you can install in this environment `xeus-r` and its dependencies

```
mamba install xeus-r -c conda-forge
```

### Installing from source

Or you can install it from the sources, you will first need to install dependencies

```bash
mamba install cmake cxx-compiler xeus-zmq nlohmann_json jupyterlab r-base r-evaluate r-rlang r-jsonlite r-glue r-cli r-repr r-irdisplay -c conda-forge
```

Then you can compile the sources (replace `$CONDA_PREFIX` with a custom installation
prefix if need be)

```bash
mkdir build && cd build
cmake .. -D CMAKE_PREFIX_PATH=$CONDA_PREFIX -D CMAKE_INSTALL_PREFIX=$CONDA_PREFIX -D CMAKE_INSTALL_LIBDIR=lib
make && make install
```

## Installation within a mamba environment (wasm build instructions)

First clone the repository, and move into that directory
```bash
git clone --depth=1 git@github.com:jupyter-xeus/xeus-r.git
cd ./xeus-r
```

Now you'll want to create a clean mamba environment containing the tools you'll need to do a wasm build. This can be done by executing
the following
```bash
micromamba create -f environment-wasm-build.yml -y
micromamba activate xeus-r-wasm-build
```

You'll now want to make sure you're using emsdk version "3.1.45" and activate it. You can get this by executing the following
```bash
cd $HOME
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install 3.1.45
./emsdk activate 3.1.45
source $HOME/emsdk/emsdk_env.sh
```

You are now in a position to build the xeus-r kernel. You build it by executing the following
```bash
micromamba create -f environment-wasm-host.yml --platform=emscripten-wasm32
mkdir build
pushd build
export PREFIX=$MAMBA_ROOT_PREFIX/envs/xeus-r-wasm-host
export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX

emcmake cmake \
        -DCMAKE_BUILD_TYPE=Release                        \
        -DCMAKE_PREFIX_PATH=$PREFIX                       \
        -DCMAKE_INSTALL_PREFIX=$PREFIX                    \
        -DXEUS_R_EMSCRIPTEN_WASM_BUILD=ON                 \
        -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON            \
        ..
emmake make install
```

To build Jupyter Lite with this kernel without creating a website you can execute the following
```bash
micromamba create -n xeus-lite-host jupyterlite-core
micromamba activate xeus-lite-host
python -m pip install jupyterlite-xeus
jupyter lite build --XeusAddon.prefix=$PREFIX
```
Once the Jupyter Lite site has built you can test the website locally by executing
```bash
jupyter lite serve --XeusAddon.prefix=$PREFIX
```

<!-- ## Trying it online

To try out xeus-r interactively in your web browser, just click on the binder link:
(Once Conda Package is Ready)

[![Binder](binder-logo.svg)](https://mybinder.org/v2/gh/jupyter-xeus/xeus-r/main?urlpath=/lab/tree/notebooks/xeus-r.ipynb) -->



## Documentation

To get started with using `xeus-r`, check out the full documentation

http://xeus-r.readthedocs.io


## Dependencies

`xeus-r` depends on

- [xeus-zmq](https://github.com/jupyter-xeus/xeus-zmq)
- [nlohmann_json](https://github.com/nlohmann/json)

| `xeus-r`|   `xeus-zmq`     |`nlohmann_json` |
|---------|------------------|----------------|
|  main   |  >=3.0,<4.0      |  >=3.11.3      |
|  0.2.x  |  >=3.0,<4.0      |  >=3.11.3      |

Prior vo version 0.2, `xeus-r` was also depending on [xtl](https://github.com/xtensor-stack/xtl) & [cppzmq](https://github.com/zeromq/cppzmq):

| `xeus-r`|   `xeus-zmq`     |      `xtl`      | `cppzmq` | `nlohmann_json` |
|---------|------------------|-----------------|----------|-----------------|
|  0.1.x  |  >=1.0.0,<2.0    |  >=0.7.0,<0.8   | ~4.4.1   |  >=3.11.2       |

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) to know how to contribute and set up a
development environment.

## License

This software is licensed under the `GNU General Public License v3`. See the [LICENSE](LICENSE)
file for details.
