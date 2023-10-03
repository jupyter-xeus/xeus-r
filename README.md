# ![xeus-r](docs/source/xeus-logo.svg)

[![Build Status](https://github.com/jupyter-xeus/xeus-r/actions/workflows/main.yml/badge.svg)](https://github.com/jupyter-xeus/xeus-r/actions/workflows/main.yml)

[![Documentation Status](http://readthedocs.org/projects/xeus-r/badge/?version=latest)](https://xeus-rreadthedocs.io/en/latest/?badge=latest)
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/jupyter-xeus/xeus-r/main?urlpath=/lab/tree/notebooks/xeus-r.ipynb)

`xeus-r` is a Jupyter kernel for R based on the native implementation of the
Jupyter protocol [xeus](https://github.com/jupyter-xeus/xeus).

## Installation

xeus-r has not been packaged for the mamba (or conda) package manager.

To ensure that the installation works, it is preferable to install `xeus-r` in a
fresh environment. It is also needed to use a
[miniforge](https://github.com/conda-forge/miniforge#mambaforge) or
[miniconda](https://conda.io/miniconda.html) installation because with the full
[anaconda](https://www.anaconda.com/) you may have a conflict with the `zeromq` library
which is already installed in the anaconda distribution.

The safest usage is to create an environment named `xeus-r`

```bash
mamba create -n  `xeus-r`
source activate  `xeus-r`
```

<!-- ### Installing from conda-forge

Then you can install in this environment `xeus-r` and its dependencies

```bash
mamba install`xeus-r` notebook -c conda-forge
``` -->

### Installing from source

Or you can install it from the sources, you will first need to install dependencies

```bash
mamba install cmake cxx-compiler xeus-zmq nlohmann_json cppzmq xtl jupyterlab -c conda-forge
```

Then you can compile the sources (replace `$CONDA_PREFIX` with a custom installation
prefix if need be)

```bash
mkdir build && cd build
cmake .. -D CMAKE_PREFIX_PATH=$CONDA_PREFIX -D CMAKE_INSTALL_PREFIX=$CONDA_PREFIX -D CMAKE_INSTALL_LIBDIR=lib
make && make install
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
- [xtl](https://github.com/xtensor-stack/xtl)
- [nlohmann_json](https://github.com/nlohmann/json)
- [cppzmq](https://github.com/zeromq/cppzmq)

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) to know how to contribute and set up a
development environment.

## License

This software is licensed under the `GNU General Public License v3`. See the [LICENSE](LICENSE)
file for details.
