### Using conda dockerfile template from:
# https://fmgdata.kinja.com/using-docker-with-conda-environments-1790901398

# Start from miniconda image:
FROM continuumio/miniconda3


# Set the ENTRYPOINT to use bash
# (this is also where you’d set SHELL,
# if your version of docker supports this)
#ENTRYPOINT ["/bin/bash", "-c"]

#EXPOSE 5000


# Install some essential things:
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
 libpq-dev \
 build-essential \
 xvfb \
 vim \
&& rm -rf /var/lib/apt/lists/*


# Some things to get perl PDL library installed:
RUN apt-get update && apt-get install -y libblas-dev liblapack-dev gfortran

# Install perl modules:
RUN cpan PDL
RUN cpan install PDL::LinearAlgebra::Trans


# Use the conda environment yaml file to create the "bpb" conda environment:
ADD environment_bpb.yml /tmp/environment_bpb.yml
WORKDIR /tmp
RUN conda update -n base -c defaults conda
RUN conda install -c conda-forge mamba
ADD environment_bpb.yml /tmp/environment_bpb.yml
RUN ["mamba", "env", "create", "-f", "environment_bpb.yml"]

# Add the conda environment to the path:
ENV PATH /opt/conda/envs/bpb/bin:$PATH


# Copy over the repository:
WORKDIR /bcr-phylo-benchmark
COPY . /bcr-phylo-benchmark

