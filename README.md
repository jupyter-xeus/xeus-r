# ![xeus-r](docs/source/xeus-logo.svg)

[![Build Status](https://github.com/jupyter-xeus/xeus-r/actions/workflows/main.yml/badge.svg)](https://github.com/jupyter-xeus/xeus-r/actions/workflows/main.yml)
[![Documentation Status](http://readthedocs.org/projects/xeus-r/badge/?version=latest)](https://xeus-r.readthedocs.io/en/latest/?badge=latest)
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/jupyter-xeus/xeus-r/main?urlpath=/lab/tree/notebooks/xeus-r.ipynb)
[![lite-badge](https://jupyterlite.rtfd.io/en/latest/_static/badge.svg)](https://jupyter-xeus.github.io/xeus-r/)

`xeus-r` is a Jupyter kernel for the R programming language.

## Installation

xeus-r has been packaged for the mamba package manager on the Linux, Windows, and OS X platforms.

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

Xeus-r can be built from sources. We recommend installing the dependencies with mamba.

```bash
mamba install cmake cxx-compiler xeus-zmq nlohmann_json jupyterlab r-base r-evaluate r-rlang r-jsonlite r-glue r-cli r-repr r-irdisplay -c conda-forge
```

Then you can compile the sources (replace `$CONDA_PREFIX` with a custom installation
prefix if need be)

```bash
mkdir build && cd build && mkdir temp_r_lib
cmake .. -D CMAKE_PREFIX_PATH=$CONDA_PREFIX -D CMAKE_INSTALL_PREFIX=$CONDA_PREFIX -D CMAKE_INSTALL_LIBDIR=lib
make && make install
```

## Trying it online

To try out xeus-r interactively in your web browser, just click on the Binder link.

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/jupyter-xeus/xeus-r/main?urlpath=/lab/tree/notebooks/xeus-r.ipynb)

To use a WebAssembly build of xeus-r in JupyterLite, follow the link.

[![lite-badge](https://jupyterlite.rtfd.io/en/latest/_static/badge.svg)](https://jupyter-xeus.github.io/xeus-r/)

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

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) to know how to contribute and set up a
development environment.

## License

This software is licensed under the `GNU General Public License v3`.

See the [LICENSE](LICENSE) file for details.
