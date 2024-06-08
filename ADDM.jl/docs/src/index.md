# Introduction

[![Documentation](https://github.com/aDDM-Toolbox/ADDM.jl/actions/workflows/documentation.yml/badge.svg)](https://github.com/aDDM-Toolbox/ADDM.jl/actions/workflows/documentation.yml)  [![CI](https://github.com/aDDM-Toolbox/ADDM.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/aDDM-Toolbox/ADDM.jl/actions/workflows/CI.yml)

Welcome to [ADDM.jl](https://github.com/aDDM-Toolbox/ADDM.jl), a package for 
joint modeling of response times, eyetracking data and choice behavior using
evidence accummulations models with time-varying drift rates. 

## Installation

### Currently

#### Docker

This option is for those who don't want to deal with installing any dependencies. See below for [instructions on how to install via Github](#Github)

- Install and start [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- From the command line interface you have for your sistem
  - Run the command below to start a Julia REPL. Note that this will mount your current working directory onto a path in the container so you can save your outputs locally if needed (more on this below)

    ```
    docker run -it --rm \
    -v $(pwd):/home/jovyan/work \
    rnlcaltech/addm-toolbox:addm.jl
    ```

  - Or start a notebook in a container based on the image using the command.   

    ```
    docker run -it --rm \
    -v $(pwd):/home/jovyan/work \
    -p 8888:8888 rnlcaltech/addm-toolbox:addm.jl jupyter-lab
    ```

    - `docker run -it --rm`: this is the main command to start a container from an image. The two flags are `-it` to interact with the container interactively and `--rm` so docker cleans up after we're done with the container
    - `-v $(pwd):/home/jovyan/work`: this mounts your local directory, wherever you're running this command from as captured by `$(pwd)` on to the file system in the docker image at path `/home/jovyan/work`. You can change either side of `:` to mount another directory from your system or to another path in the container. This part is critical if you want to be able to write out and save any output from your analyses that run in the container. Otherwise they will disappear when you kill the container (because we are starting the container with the `--rm` flag).
    - `-p 8888:8888`: this connects a local port to the jupyter-lab port in the container. If you have any other jupyter-lab notebooks running locally that are listening on the `8888` port you should change this to e.g. `-p 8989:8888` so it does not ask you for a token when you go to the URL this command lists in its output.
    - `rnlcaltech/addm-toolbox:addm.jl jupyter-lab`: this specifies the container name with the tag and the entry point (the beginning command) you want to run in the container. The output will look similar to when you start a jupyter notebook locally. Go to the URL listed in the output in a browser to start a notebook and begin exploring the toolbox as described in [Getting started with ADDM.jl](https://addm-toolbox.github.io/ADDM.jl/dev/tutorials/getting_started/)

- To kill the container hit `cmd + c`

#### Github

If you have Julia and Git installed and want a local copy of the toolbox on your machine you can follow the intructions below. Note that, this will require you to install all Julia dependencies (in it's own environmet).

- Clone the Github repo

```
git clone https://github.com/aDDM-Toolbox/ADDM.jl.git
```

- Navigate to the ADDM.jl directory

```
cd ADDM.jl
```

- Set up the Julia environment (might take a few minutes)

```
julia --project -e 'import Pkg; Pkg.instantiate()'
```

- Start up a Julia REPL using the project's environment

```
julia --project={path_to}/ADDM.jl
```

### Once `ADDM.jl` is on the Julia Registry

You can install `ADDM.jl` from the Julia Registry if you want a local copy of it. Alternatively you can use the Docker images as described above.

```julia
julia> import Pkg

julia> Pkg.add("ADDM")
```

## License

`ADDM.jl` is licensed under the [GNU General Public License v3.0](https://github.com/aDDM-Toolbox/ADDM.jl/blob/main/LICENSE).

## Resources for getting started

There are a few ways to get started with ADDM.jl:

 * Become familiar with the modeling framework described in [Krajbich et al. (2010)](https://www.nature.com/articles/nn.2635)  
 * Become familiar with algorithm used for likelihood computation in [Tavares et al. (2017)](https://www.frontiersin.org/articles/10.3389/fnins.2017.00468/full)  
 * Read the [introductory tutorial](https://addm-toolbox.github.io/ADDM.jl/dev/tutorials/01_getting_started/)

## Getting help

If you need help, please [open a GitHub issue](https://github.com/aDDM-Toolbox/ADDM.jl/issues/new).

## Citing `ADDM.jl`

If you use `ADDM.jl`, we ask that you please cite the following:
