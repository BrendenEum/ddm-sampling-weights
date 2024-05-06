FROM quay.io/jupyter/julia-notebook:julia-1.9.3

RUN git clone https://github.com/aDDM-Toolbox/ADDM.jl.git

# Change directory into julia project
WORKDIR /home/jovyan/ADDM.jl

# Instantiate environment
RUN julia --project -e 'import Pkg; Pkg.instantiate()'

# Change entry point
CMD ["julia", "--project"]
