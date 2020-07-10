# GLOBAL ARGS
ARG TEGRA_DST=/tmp/src/tegra
ARG TEGRA_VERSION=32.4.3

# USE ALPINE to pull tegra source has a workaround (due to some issue with bzip2 version otherwise)
FROM alpine:latest as downloader

# Tegra
ARG TEGRA_DST
ARG TEGRA_ARCHIVE=./tegra.tbz2
ARG NV_DRIVERS=Linux_for_Tegra/nv_tegra/nvidia_drivers.tbz2
ARG NV_GSTAPPS=Linux_for_Tegra/nv_tegra/nv_sample_apps/nvgstapps.tbz2
RUN apk update && apk add wget tar bzip2 ca-certificates

COPY ./tegra.tbz2 ./tegra.tbz2

RUN mkdir -p ${TEGRA_DST} \
  && tar -C . -jxv --file=tegra.tbz2 ${NV_GSTAPPS} ${NV_DRIVERS} \
  && tar -C ${TEGRA_DST} -jxvf ${NV_DRIVERS} \
  && tar -C ${TEGRA_DST} -jxvf ${NV_GSTAPPS}

FROM arm64v8/ubuntu:18.04

# ARG -------------------------------------------------------------------------

# CUDA libs
ARG NVIDIA_SRC_PATH=./nvidia-deb
ARG NVIDIA_DST_PATH=/tmp/nvidia-deb
ARG CUDA_VERSION_DASHED="10-2"
ARG CUDA_DIR=${NVIDIA_DST_PATH}/cuda
ARG CUDNN_DIR=${NVIDIA_DST_PATH}/cudnn
ARG NVINF_DIR=${NVIDIA_DST_PATH}/nvinfer
ARG TRT_DIR=${NVIDIA_DST_PATH}/tensorrt

# Tegra
ARG TEGRA_VERSION
ARG TEGRA_DST

# DOCKER Build
ARG RUN=1

# TEGRA -------------------------------------------------------------------------
COPY --from=downloader ${TEGRA_DST}/ /

# CUDA -------------------------------------------------------------------------
COPY ${NVIDIA_SRC_PATH}/ ${NVIDIA_DST_PATH}/
  # --- Install build tools dependencies ---
RUN apt-get update && apt-get dist-upgrade -y \
  && apt-get install -y --no-install-recommends \
    dpkg \
    gnupg \
    python3 \
    python3-distutils \
    ca-certificates \
  && apt-get clean -y \
  && apt-get autoclean -y \
  #
  # --- Install and configure CUDA ---
  && cd ${CUDA_DIR} \
  && dpkg -R --install ${CUDA_DIR} \
  && echo Add key from `find /var/cuda-repo-${CUDA_VERSION_DASHED}-local-* -name "*.pub"` \
  && apt-key add `find /var/cuda-repo-${CUDA_VERSION_DASHED}-local-* -name "*.pub"` \
  && cp /etc/apt/sources.list /etc/apt/sources.list.old \
  && sed -i.bak 's/\(^deb.*main restricted\)\s*$/\1 universe multiverse/g' \
    /etc/apt/sources.list \
  && sed -i.bak 's/\(^deb.*main restricted universe\)\s*$/\1 multiverse/g' \
    /etc/apt/sources.list \
  && apt-get -y update \
  && apt-get -y --allow-downgrades --no-install-recommends install \
    cuda-toolkit-${CUDA_VERSION_DASHED} libgomp1 libfreeimage-dev \
    libopenmpi-dev openmpi-bin \
  && apt-get clean -y \
  && apt-get autoclean -y \
  && rm -rf /var/cuda-repo-${CUDA_VERSION_DASHED}-local-* \
  && find /etc/apt/sources.list.d -name "cuda-${CUDA_VERSION_DASHED}*.list" -print -delete \
  && mv /etc/apt/sources.list.old /etc/apt/sources.list \
  && apt-key del cudatools \
  && export CUDA_VERSION=`echo "${CUDA_VERSION_DASHED}"|sed -e "s\-\.\g"` \
  && echo "CUDA Version: $CUDA_VERSION"\
  #
  # --- Install CUDNN ---
  && cd ${CUDNN_DIR} \
  # && dpkg -R --install ${CUDNN_DIR} \
  && apt-get install ./* \
  #
  # --- Install NVInfer ---
  && cd ${NVINF_DIR} \
  # && dpkg -R --install ${NVINF_DIR} \
  && apt-get install ./* \
  #
  # --- Install TensorRT ---
  && cd ${TRT_DIR} \
  # && dpkg -R --install ${TRT_DIR} \
  && apt-get install ./* \
  #
  # --- Fix all symlinks to .so files ---
  && cd /usr/lib/aarch64-linux-gnu/tegra \
  && ln -sf libcuda.so.1.1               libcuda.so \
  && ln -sf libcuda.so.1.1               libcuda.so.1 \
  && ln -sf libnvidia-ptxjitcompiler.so.${TEGRA_VERSION} libnvidia-ptxjitcompiler.so \
  && ln -sf libnvidia-ptxjitcompiler.so.${TEGRA_VERSION} libnvidia-ptxjitcompiler.so.1 \
  && cd /usr/lib/aarch64-linux-gnu \
  && ln -sf libglut.so.3.9.0                   libglut.so \
  && ln -sf libcudnn.so.7                      libcudnn.so \
  && ln -sf libGLU.so.1.3.1                    libGLU.so \
  && ln -sf libGLdispatch.so.0                 libGLdispatch.so.0 \
  && ln -sf tegra/libcuda.so                   libcuda.so \
  && cd /usr/local/cuda-10.2/targets/aarch64-linux/lib/ \
  && ln -sf libcudart.so.10.2                  libcudart.so \
  # --- Add extra ld conf path ---
  && echo "/usr/lib/aarch64-linux-gnu/tegra" >> /etc/ld.so.conf.d/aarch64-tegra.conf \
  && echo "/usr/lib/aarch64-linux-gnu/tegra-egl" >> /etc/ld.so.conf.d/aarch64-tegra.conf \
  && rm -f /etc/ld.so.cache \
  && ldconfig \
  #
  # --- Clean ---
  && rm -r ${NVIDIA_DST_PATH} \
  #
  # --- Remove build dependencies for run mode
  && if [ ${RUN} -eq 1 ] ; \
    then \
      echo "RUN MODE" \
      && dpkg -l | grep "\-dev" | awk '{print $2}' \
        | xargs -n200 apt-get purge -y \
      && cd /usr/local \
      && ln -s cuda-$CUDA_VERSION cuda ;\
    else \
      echo "BUILD MODE" ;\
    fi
#-------------------------------------------------------------------------------

# Setup path
ENV PATH=/usr/local/cuda/bin:$PATH
#-------------------------------------------------------------------------------
