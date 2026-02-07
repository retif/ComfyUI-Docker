################################################################################
# Dockerfile that builds 'yanwk/comfyui-boot:cu130-megapak-py314-source'
# A runtime environment for https://github.com/comfyanonymous/ComfyUI
# Using CUDA 13.0, Python 3.14 (free-threaded, compiled from source), GCC 15.
# Using glibc 2.40 (from openSUSE Leap 16.0).
# Python 3.14 built from source with --disable-gil flag.
################################################################################

FROM docker.io/opensuse/leap:16.0

LABEL maintainer="YAN Wenkun <code@yanwk.fun>"

ARG USING_GITHUB_ACTIONS=false
ARG PYTHON_VERSION=3.14.0

################################################################################
# NVIDIA CUDA devel
# Ref: https://gitlab.com/nvidia/container-images/cuda/

# Helper function for retry logic on network failures
RUN printf '#!/bin/bash\n\
zypper_retry() {\n\
    local max_attempts=5\n\
    local timeout=2\n\
    local attempt=1\n\
    local exitCode=0\n\
    \n\
    while (( attempt <= max_attempts )); do\n\
        echo "Attempt $attempt of $max_attempts: zypper $@"\n\
        if zypper "$@"; then\n\
            echo "zypper command succeeded on attempt $attempt"\n\
            return 0\n\
        else\n\
            exitCode=$?\n\
            echo "zypper command failed with exit code $exitCode on attempt $attempt"\n\
            \n\
            if (( attempt < max_attempts )); then\n\
                echo "Waiting ${timeout}s before retry..."\n\
                sleep $timeout\n\
                timeout=$((timeout * 2))\n\
            fi\n\
        fi\n\
        attempt=$((attempt + 1))\n\
    done\n\
    \n\
    echo "zypper command failed after $max_attempts attempts"\n\
    return $exitCode\n\
}\n\
zypper_retry "$@"\n' > /usr/local/bin/zypper-retry \
    && chmod +x /usr/local/bin/zypper-retry

RUN --mount=type=cache,target=/var/cache/zypp \
    zypper update --no-confirm

RUN --mount=type=cache,target=/var/cache/zypp \
    printf "\
[cuda-opensuse15-x86_64]\n\
name=cuda-opensuse15-x86_64\n\
baseurl=https://developer.download.nvidia.com/compute/cuda/repos/opensuse15/x86_64\n\
enabled=1\n\
gpgcheck=1\n\
gpgkey=https://developer.download.nvidia.com/compute/cuda/repos/opensuse15/x86_64/D42D0685.pub\n" \
        > /etc/zypp/repos.d/cuda-opensuse15.repo \
    && zypper-retry --verbose --gpg-auto-import-keys \
        install --no-confirm --no-recommends --auto-agree-with-licenses \
cuda-cccl-13-0 \
cuda-command-line-tools-13-0 \
cuda-compat-13-0 \
cuda-compiler-13-0 \
cuda-cudart-13-0 \
cuda-minimal-build-13-0 \
cuda-nvcc-13-0 \
cuda-nvtx-13-0

RUN --mount=type=cache,target=/var/cache/zypp \
    zypper-retry --verbose --gpg-auto-import-keys \
        install --no-confirm --no-recommends --auto-agree-with-licenses \
libcublas-13-0

RUN --mount=type=cache,target=/var/cache/zypp \
    zypper-retry --verbose --gpg-auto-import-keys \
        install --no-confirm --no-recommends --auto-agree-with-licenses \
libcublas-devel-13-0

RUN --mount=type=cache,target=/var/cache/zypp \
    zypper-retry --verbose --gpg-auto-import-keys \
        install --no-confirm --no-recommends --auto-agree-with-licenses \
cuda-ctadvisor-13-0 \
cuda-cudart-devel-13-0 \
cuda-culibos-devel-13-0 \
cuda-nvml-devel-13-0 \
cuda-nvrtc-devel-13-0 \
cuda-sandbox-devel-13-0 \
libnpp-devel-13-0 \
libnvimgcodec-cuda-13 \
libnvptxcompiler-13-0 \
libnvvm-13-0

RUN --mount=type=cache,target=/var/cache/zypp \
    zypper-retry --verbose --gpg-auto-import-keys \
        install --no-confirm --no-recommends --auto-agree-with-licenses \
libcusolver-13-0 \
libcusolver-devel-13-0

RUN --mount=type=cache,target=/var/cache/zypp \
    zypper-retry --verbose --gpg-auto-import-keys \
        install --no-confirm --no-recommends --auto-agree-with-licenses \
libcusparse-13-0 \
libcusparse-devel-13-0

RUN --mount=type=cache,target=/var/cache/zypp \
    zypper-retry --verbose --gpg-auto-import-keys \
        install --no-confirm --no-recommends --auto-agree-with-licenses \
cuda-libraries-13-0

RUN --mount=type=cache,target=/var/cache/zypp \
    zypper-retry --verbose --gpg-auto-import-keys \
        install --no-confirm --no-recommends --auto-agree-with-licenses \
cuda-libraries-devel-13-0

RUN --mount=type=cache,target=/var/cache/zypp \
    zypper-retry --verbose --gpg-auto-import-keys \
        install --no-confirm --no-recommends --auto-agree-with-licenses \
cusparselt-cuda-13

RUN --mount=type=cache,target=/var/cache/zypp \
    zypper-retry --verbose --gpg-auto-import-keys \
        install --no-confirm --no-recommends --auto-agree-with-licenses \
libcudnn9-cuda-13-9.16.0.29-1

RUN --mount=type=cache,target=/var/cache/zypp \
    zypper-retry --verbose --gpg-auto-import-keys \
        install --no-confirm --no-recommends --auto-agree-with-licenses \
cudnn9-cuda-13-0

ENV PATH="${PATH}:/usr/local/cuda-13.0/bin" \
    LD_LIBRARY_PATH="/usr/lib64:/usr/local/cuda-13.0/lib64" \
    LIBRARY_PATH="/usr/local/cuda-13.0/lib64/stubs" \
    CUDA_HOME="/usr/local/cuda-13.0"

################################################################################
# Python 3.14 from source (free-threaded, no GIL)
# Install build dependencies first

RUN --mount=type=cache,target=/var/cache/zypp \
    zypper-retry --gpg-auto-import-keys \
        install --no-confirm --auto-agree-with-licenses \
make \
gcc \
gcc-c++ \
findutils \
libopenssl-devel \
libffi-devel \
libbz2-devel \
libsqlite3-0 \
sqlite3-devel \
zlib-devel \
libreadline8 \
readline-devel \
gdbm-devel \
libuuid-devel \
tk-devel \
libX11-devel \
xz-devel \
ncurses-devel \
wget \
ca-certificates

# Download and compile Python 3.14 with free-threading (--disable-gil)
RUN cd /tmp \
    && wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz \
    && tar -xf Python-${PYTHON_VERSION}.tar.xz \
    && cd Python-${PYTHON_VERSION} \
    && ./configure \
        --enable-optimizations \
        --disable-gil \
        --with-lto \
        --enable-shared \
        --prefix=/usr/local \
        LDFLAGS="-Wl,-rpath /usr/local/lib" \
    && make -j$(nproc) \
    && make install \
    && cd / \
    && rm -rf /tmp/Python-${PYTHON_VERSION}*

# Create python3 symlink and verify installation
RUN ln -sf /usr/local/bin/python3.14 /usr/local/bin/python3 \
    && ln -sf /usr/local/bin/python3.14 /usr/local/bin/python \
    && ln -sf /usr/local/bin/pip3.14 /usr/local/bin/pip3 \
    && ln -sf /usr/local/bin/pip3.14 /usr/local/bin/pip \
    && python3 --version \
    && python3 -c "import sys; print(f'GIL: {sys._is_gil_enabled()}')"

################################################################################
# System tools and libraries

RUN --mount=type=cache,target=/var/cache/zypp \
    zypper-retry --gpg-auto-import-keys \
        install --no-confirm --auto-agree-with-licenses \
Mesa-libGL-devel \
Mesa-libEGL-devel \
libgthread-2_0-0

RUN --mount=type=cache,target=/var/cache/zypp \
    zypper-retry --gpg-auto-import-keys \
        install --no-confirm --auto-agree-with-licenses \
make \
cmake \
ninja \
git \
aria2 \
findutils \
fish \
fd \
vim \
which

# Temp fix for OpenCV on openSUSE
ENV LD_PRELOAD=/usr/lib64/libjpeg.so.8

# Temp fix for SentencePiece on CMAKE 4+
ENV CMAKE_POLICY_VERSION_MINIMUM=3.5

################################################################################
# GCC 15

RUN --mount=type=cache,target=/var/cache/zypp \
    zypper-retry --gpg-auto-import-keys \
        install --no-confirm --auto-agree-with-licenses \
gcc15 \
gcc15-c++ \
cpp15 \
    && update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-15 90 \
    && update-alternatives --install /usr/bin/cc cc /usr/bin/gcc-15 90 \
    && update-alternatives --install /usr/bin/cpp cpp /usr/bin/cpp-15 90 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-15 90 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-15 90 \
    && update-alternatives --install /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-15 90 \
    && update-alternatives --install /usr/bin/gcc-nm gcc-nm /usr/bin/gcc-nm-15 90 \
    && update-alternatives --install /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-15 90 \
    && update-alternatives --install /usr/bin/gcov gcov /usr/bin/gcov-15 90 \
    && update-alternatives --install /usr/bin/gcov-dump gcov-dump /usr/bin/gcov-dump-15 90 \
    && update-alternatives --install /usr/bin/gcov-tool gcov-tool /usr/bin/gcov-tool-15 90

################################################################################
# PyTorch for CUDA 13.0

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip wheel setuptools packaging

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/cu130 || \
    pip install --pre torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/nightly/cu130

ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}\
:/usr/local/lib64/python3.14/site-packages/torch/lib\
:/usr/local/lib/python3.14/site-packages/nvidia/nccl/lib\
:/usr/local/lib/python3.14/site-packages/nvidia/nvshmem/lib"

################################################################################
# More Python Packages

COPY builder-scripts/.  /builder-scripts/

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip setuptools wheel && \
    pip install --only-binary opencv-python,opencv-python-headless,opencv-contrib-python,opencv-contrib-python-headless \
        -r /builder-scripts/pak3.txt

# Install CuPy RC version with Python 3.14 support
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install cupy-cuda13x --pre -U -f https://pip.cupy.dev/pre

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install \
        -r /builder-scripts/pak5.txt

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install \
        -r /builder-scripts/pak7.txt

RUN --mount=type=cache,target=/root/.cache/pip \
    cd /builder-scripts \
    && git clone https://github.com/facebookresearch/sam2.git \
    && cd sam2 \
    && SAM2_BUILD_CUDA=1 pip install \
        -e . --no-deps --no-build-isolation \
    && cd /

RUN --mount=type=cache,target=/root/.cache/pip \
    cd /builder-scripts \
    && git clone https://github.com/facebookresearch/sam3.git \
    && cd sam3 \
    && pip install \
        -e . --no-deps --no-build-isolation \
    && cd /

# Performance optimization libraries from GitHub releases
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -U uv \
    && pip install \
https://github.com/retif/pytorch-wheels-builder/releases/download/flash-attn-v2.8.2-py314-torch2.10.0-cu130/flash_attn-2.8.2-cp314-cp314-linux_x86_64.whl \
    && pip install \
https://github.com/retif/pytorch-wheels-builder/releases/download/sageattention-v2.2.0-py314-torch2.10.0-cu130/sageattention-2.2.0%2Bcu130torch2.10.0-cp314-cp314-linux_x86_64.whl \
    && pip install \
https://github.com/retif/pytorch-wheels-builder/releases/download/nunchaku-v1.0.2-py314-torch2.10.0-cu130/nunchaku-1.0.2%2Btorch2.10-cp314-cp314-linux_x86_64.whl

################################################################################
# Bundle ComfyUI and ~47 custom nodes

WORKDIR /default-comfyui-bundle

RUN bash /builder-scripts/preload-cache.sh

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install \
        -r '/default-comfyui-bundle/ComfyUI/requirements.txt' \
        -r '/default-comfyui-bundle/ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt' \
    && pip list

################################################################################
# Finalize image

RUN --mount=type=cache,target=/root/.cache/pip \
    if [ "${USING_GITHUB_ACTIONS}" = "true" ]; then \
        rm -rf /root/.cache/pip/* ; \
    fi

RUN du -ah /root \
    && rm -rfv /root/* \
    && rm -rfv /root/.[^.]* /root/.??*

COPY runner-scripts/.  /runner-scripts/

USER root
VOLUME /root
WORKDIR /root
EXPOSE 8188
ENV CLI_ARGS=""
CMD ["bash","/runner-scripts/entrypoint.sh"]
