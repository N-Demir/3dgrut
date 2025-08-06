# TODO: Add an example
###### How to edit this file ######
# Docker and Dockerfiles are quite simple:
# - a dockerfile is the set of instructions for getting a fresh machine ready to run your code
# - start by defining a base image (FROM ...) based on the cuda and torch version you want. This gets the hard gpu driver stuff out of the way
# - set env vars with ENV ..., change directories with WORKDIR ..., and run commands with RUN ...
# - avoid using conda installs (just replace them with pip installs) because getting conda initialized in docker is a pain
# 
# Beam will handle building the docker image from this file, but you can also build it yourself and run it wherever you want

FROM pytorch/pytorch:2.1.2-cuda11.8-cudnn8-devel

# Set Torch CUDA Compatbility to be for RTX 4090, T4, and A100
# If using a different GPU, make sure its torch cuda architecture version is added to the list
ENV TORCH_CUDA_ARCH_LIST="7.5;8.0;8.9;9.0"

# Install git and various other helper dependencies
# Set environment variable to avoid interactive prompts from installing packages
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/New_York
RUN apt-get update && apt-get install -y \
    git \
    wget \
    unzip \
    cmake \
    build-essential \
    ninja-build \
    libglew-dev \
    libassimp-dev \
    libboost-all-dev \
    libgtk-3-dev \
    libopencv-dev \
    libglfw3-dev \
    libavdevice-dev \
    libavcodec-dev \
    libeigen3-dev \
    libxxf86vm-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root/workspace

###### Method Installation ######
# Pulling from a repo is probably the easiest
# eg: RUN git clone https://github.com/graphdeco-inria/gaussian-splatting.git . --recursive
RUN git clone https://github.com/N-Demir/3dgrut.git --recursive -b nvs-leaderboard .

# Install (avoid conda installs because they don't work well in dockerfile situations)
# Separating these on separate lines helps if there are errors (previous lines will be cached) especially on the large package installs
# eg:
# RUN pip install submodules/diff-gaussian-rasterization
# RUN pip install submodules/simple-knn
# RUN pip install submodules/fused-ssim
# RUN pip install -e .

# Note: If your install needs access to a gpu it's actually possible to do that through Beam's python sdk. Check their docs or reach out!

RUN pip install kaolin==0.17.0 -f https://nvidia-kaolin.s3.us-east-2.amazonaws.com/torch-2.1.2_cu118.html
RUN pip install -r requirements.txt
RUN pip install -e .
