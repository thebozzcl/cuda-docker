# Credits
This is a fork of latonaio's lic-docker-cuda-ce repository over at BitBucket. Original source here: https://bitbucket.org/latonaio/lic-docker-cuda-ce/src/master/

I modified this script so it installs CUDA 10.2, and all other related libraries matching my Jetson Nano's cache, so the README is not fully accurate at the moment. The only updated section is the list of `.deb` files you will need to gather.

You can find my latest build here: https://hub.docker.com/repository/docker/thebozzcl/cuda

# Docker images base-tegra-cuda

# 1. Description

This repository aims to provide a
[`CUDA`](https://en.wikipedia.org/wiki/CUDA) "enabled" container for NVIDIA
[Jetson](https://www.nvidia.com/en-us/autonomous-machines/embedded-systems/)
devices [AGX Xavier](https://www.nvidia.com/en-us/autonomous-machines/embedded-systems/jetson-agx-xavier/),
[TX2](https://www.nvidia.com/en-us/autonomous-machines/embedded-systems/jetson-tx2/),
and [Nano](https://www.nvidia.com/en-us/autonomous-machines/embedded-systems/jetson-nano/).


## 1.1. Included libs from the Jetpack

This container contains some of NVIDIA Tegra libs and the CUDA libs.
In the version 0.1.0:

- CUDA 10.0.166
- NVInfer 5.0.6-1
- Cudnn 7.3.1.28-1
- TensorRT 5.0.6.3-1
- Tegra drivers libs 32-1.0
- NVIDIA Gstreamer plugins from Tegra 32-1.0

> Note: those proprietary libs need to be downloaded separately. Please refer
> to section 3 below.


# 2. Usage

The Dockerfile is designed to produce two flavours of the image :
a "**`build`**" mode and a "**`run`**" mode.

- The **`build`** image contains the necessary files (such as headers and `-dev`
  packages) to build CUDA-enabled projects.
- The **`run`** is a much lighter image which includes only files needed at
  runtime such as shared libs.

This allows using a builder/runner pattern with multistage dockerfiles.


# 3. Build the image

## 3.1. CUDA dependencies availability

To build the image, various archives need to be provided.
As the CUDA libs are not accessible directly from a public URL, they need to be
manually down once.

To retrieve the .deb files you can use [JetPack SDK Manager](https://developer.nvidia.com/embedded/jetpack). The files are extracted in a folder specified during the installation process at step 2 (see the download and install options).


> Note: it is required to put those files like the following.
> Minor versions might be different depending on the Jetpack version.

**NOTE FROM @rjbozzol**: I updated this section of the original README to show what my own DEB path ended up being. Instead of using the JetPack SDK Manager, I found all these files just sitting in `/var/cache/apt/archives/`! This could be automated to get all the libraries when building in a Tegra machine... but I'll leave that as a potential upgrade in the future.

```bash
./nvidia-deb/
├── cuda
│   └── cuda-repo-ubuntu1804-10-2-local-10.2.107-435.17.01_1.0-1_arm64.deb
├── cudnn
│   ├── libcudnn8_8.0.0.180-1+cuda10.2_arm64.deb
│   ├── libcudnn8-dev_8.0.0.180-1+cuda10.2_arm64.deb
│   └── libcudnn8-doc_8.0.0.180-1+cuda10.2_arm64.deb
├── libnvonnxparsers-dev_7.1.3-1+cuda10.2_arm64.deb
├── libnvparsers-dev_7.1.3-1+cuda10.2_arm64.deb
├── nvinfer
│   ├── libnvinfer7_7.1.3-1+cuda10.2_arm64.deb
│   ├── libnvinfer-bin_7.1.3-1+cuda10.2_arm64.deb
│   ├── libnvinfer-dev_7.1.3-1+cuda10.2_arm64.deb
│   ├── libnvinfer-doc_7.1.3-1+cuda10.2_all.deb
│   ├── libnvinfer-plugin7_7.1.3-1+cuda10.2_arm64.deb
│   ├── libnvinfer-plugin-dev_7.1.3-1+cuda10.2_arm64.deb
│   ├── libnvinfer-samples_7.1.3-1+cuda10.2_all.deb
│   ├── libnvonnxparsers7_7.1.3-1+cuda10.2_arm64.deb
│   ├── libnvonnxparsers-dev_7.1.3-1+cuda10.2_arm64.deb
│   ├── libnvparsers7_7.1.3-1+cuda10.2_arm64.deb
│   ├── libnvparsers-dev_7.1.3-1+cuda10.2_arm64.deb
│   ├── python3-libnvinfer_7.1.3-1+cuda10.2_arm64.deb
│   └── python3-libnvinfer-dev_7.1.3-1+cuda10.2_arm64.deb
└── tensorrt
    └── tensorrt_7.1.3.0-1+cuda10.2_arm64.deb
```

## 3.2. Tegra libraries and drivers

Tegra's archives are downloaded directly from NVIDIA website within the
container at build.

For Tegra 32.1:  [JAX-TX2-Jetson_Linux_R32.1.0_aarch64.tbz2](https://developer.nvidia.com/embedded/dlc/l4t-jetson-driver-package-32-1-JAX-TX2)

## 3.3. Docker build

To build the image you should run:

- For the **`build`** version:

    ```bash
    $ docker build --build-arg RUN=0 -t tegra-cuda-base:build .
    ```

- For the **`run`** version:

    ```bash
    $ docker build --build-arg RUN=1 -t tegra-cuda-base:run .
    ```

The build can be configured using the following args. Here are the default
values:

### 3.3.1. CUDA

- `CUDA_VERSION_DASHED`: Version of CUDA to be installed. This must match the
  version of a CUDA deb file (i.e. cuda-repo-l4t-***XX-Y***-local_*) in your local `nvidia-deb/cuda` folder. *(default= "10-0")*

### 3.3.2. Tegra

- `TEGRA_VERSION`: The version of Tegra libs used. *(default= 32.1.0)*
- `TEGRA_ARCHIVE`: The URL of the archive of the Tegra's drivers to download.
  *(default= https://developer.nvidia.com/embedded/dlc/l4t-jetson-driver-package-32-1-JAX-TX2)*
  > Note: So far, the archive's name was not constant between version 28.2 and
  32.1 of Tegra. Therefore the URL is not created from `TEGRA_VERSION`. Please
  be sure that `TEGRA_VERSION` matches the version of `TEGRA_ARCHIVE`.
- `NV_DRIVERS`: name of the archive containing the L4T drivers inside the Tegra
  archive. *(default= Linux_for_Tegra/nv_tegra/nvidia_drivers.tbz2)*
- `NV_GSTAPPS`: name of the archive containing the
  [Gstreamer](https://gstreamer.freedesktop.org/documentation/index.html?gi-language=c)
  plugins inside the Tegra archive.
  *(default= Linux_for_Tegra/nv_tegra/nv_sample_apps/nvgstapps.tbz2)*

### 3.3.3. Image mode

- `RUN`: Set to `1` if you want to produce a "run" image (i.e. without build
  dependencies). To keep the build dependencies and create a "build" image, set
  it to `0`. Please refer to section 2 for details about these two modes.
  *(default: `0`)*


# 4. Example

In this example, we will see how to use the CUDA-enable image produced with this
repository. We will build a sample provided along with CUDA dev packages. The
following dockerfile is available in `Dockerfile.test`:

```docker
# GLOBAL ARGS
ARG CUDA_BASE_IMAGE=tegra-cuda-base
ARG TAG_BUILD=build
ARG TAG_RUN=run

ARG CUDA_SAMPLE_DIR=/usr/local/cuda/samples/

# BUILD STAGE -----------------------------------------------------------------
FROM ${CUDA_BASE_IMAGE}:${TAG_BUILD} AS builder

ARG CUDA_SAMPLE_DIR
ARG TARGETS="."

RUN export CUDA_VERSION=`cat /usr/local/cuda/version.txt \
    | cut -d " " -f3 \
    | cut -d "." -f1,2` \
  && echo "Build for CUDA $CUDA_VERSION" \
  && cd ${CUDA_SAMPLE_DIR} \
  && echo Build following projects: `\
    find ${TARGETS} -name Makefile \
    | sed "s/Makefile//g" \
    | sed "s/\.\///g"`\
  && PROJECTS=` find ${TARGETS} -name Makefile \
    | sed "s/Makefile//g" \
    | sed "s/\.\///g" ` \
    make -j `nproc`

# RUN STAGE -------------------------------------------------------------------
FROM ${CUDA_BASE_IMAGE}:${TAG_RUN} as tester

ARG CUDA_SAMPLE_DIR
ARG SAMPLE_DEST=/compiled-samples

WORKDIR ${SAMPLE_DEST}
COPY --from=builder ${CUDA_SAMPLE_DIR}/bin/aarch64/linux/release/ ${SAMPLE_DEST}

CMD [ "/bin/bash" ]
```

The build argument `TARGETS` allows selecting which samples in the directory
`/usr/local/cuda/samples` you want to build:

- Set it to `""` (<*empty string*>) or `"."` to build all the samples.
- To build a specific sample, set it to the relative path of the directory of
  the desired sample. E.g.: `"1_Utilities/deviceQuery"`.
- You can also specify a folder to build all the subprojects inside. E.g.:
  `"1_Utilities"`
- To build multiple directories or samples, specify them in a single string.
  Folders names must be separated by a space `" "`. E.g.:
  `"1_Utilities 5_Simulations"`.

> Note: You can retrieve the list of available samples by running the build
> container as follows:
>
> ```bash
> $ docker run --rm tegra-cuda-base:build find /usr/local/cuda/samples -name Makefile
> ```

## 4.1. Build the test


```bash
$ docker build \
  --build-arg CUDA_BASE_IMAGE=tegra-cuda-base \
  --build-arg TAG_BUILD=build \
  --build-arg TAG_RUN=run \
  --build-arg TARGETS="1_Utilities/deviceQuery" \
  --build-arg SAMPLE_DEST="/compiled-samples" \
  -t cuda-test \
  -f Dockerfile.test .
```

## 4.2. Run the test

```bash
$ docker run --rm -it --privileged cuda-test

# Once in the container, run the sample:
root@86534cd14e9b:/compiled-sample# ./deviceQuery
```

Or the lazy way:

```bash
$ docker run --rm -it --privileged cuda-test /compiled-samples/deviceQuery
```

You should obtain a similar output on a Jetson AGX Xavier

```bash
./deviceQuery Starting...

 CUDA Device Query (Runtime API) version (CUDART static linking)

Detected 1 CUDA Capable device(s)

Device 0: "Xavier"
  CUDA Driver Version / Runtime Version          10.0 / 10.0
  CUDA Capability Major/Minor version number:    7.2
  Total amount of global memory:                 15692 MBytes (16454631424 bytes)
  ( 8) Multiprocessors, ( 64) CUDA Cores/MP:     512 CUDA Cores
  GPU Max Clock rate:                            1500 MHz (1.50 GHz)
  Memory Clock rate:                             1377 Mhz
  Memory Bus Width:                              256-bit
  L2 Cache Size:                                 524288 bytes
  Maximum Texture Dimension Size (x,y,z)         1D=(131072), 2D=(131072, 65536), 3D=(16384, 16384, 16384)
  Maximum Layered 1D Texture Size, (num) layers  1D=(32768), 2048 layers
  Maximum Layered 2D Texture Size, (num) layers  2D=(32768, 32768), 2048 layers
  Total amount of constant memory:               65536 bytes
  Total amount of shared memory per block:       49152 bytes
  Total number of registers available per block: 65536
  Warp size:                                     32
  Maximum number of threads per multiprocessor:  2048
  Maximum number of threads per block:           1024
  Max dimension size of a thread block (x,y,z): (1024, 1024, 64)
  Max dimension size of a grid size    (x,y,z): (2147483647, 65535, 65535)
  Maximum memory pitch:                          2147483647 bytes
  Texture alignment:                             512 bytes
  Concurrent copy and kernel execution:          Yes with 1 copy engine(s)
  Run time limit on kernels:                     No
  Integrated GPU sharing Host Memory:            Yes
  Support host page-locked memory mapping:       Yes
  Alignment requirement for Surfaces:            Yes
  Device has ECC support:                        Disabled
  Device supports Unified Addressing (UVA):      Yes
  Device supports Compute Preemption:            Yes
  Supports Cooperative Kernel Launch:            Yes
  Supports MultiDevice Co-op Kernel Launch:      Yes
  Device PCI Domain ID / Bus ID / location ID:   0 / 0 / 0
  Compute Mode:
     < Default (multiple host threads can use ::cudaSetDevice() with device simultaneously) >

deviceQuery, CUDA Driver = CUDART, CUDA Driver Version = 10.0, CUDA Runtime Version = 10.0, NumDevs = 1
Result = PASS
```

> Note: `--privileged` is used to grant access to GPU devices on the host.
> It is fine to use it for testing but may not be suitable for a released app.
> Check [Docker privileged and capabilities docs](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities)
> for more details.
