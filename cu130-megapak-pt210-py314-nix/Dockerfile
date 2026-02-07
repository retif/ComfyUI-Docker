################################################################################
# Dockerfile that builds 'yanwk/comfyui-boot:cu130-megapak-py314-nix'
# A runtime environment for https://github.com/comfyanonymous/ComfyUI
# Using CUDA 13.0, Python 3.14 (free-threaded, no GIL), NixOS.
# Using NixOS for access to bleeding-edge Python 3.14 packages.
################################################################################

FROM nixos/nix:latest

LABEL maintainer="YAN Wenkun <code@yanwk.fun>"

# Enable flakes and experimental features
RUN echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf

# Create a Nix expression for the build environment
RUN mkdir -p /build-env && cat > /build-env/shell.nix <<'EOF'
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Python 3.14 (free-threaded)
    python314
    python314Packages.pip
    python314Packages.setuptools
    python314Packages.wheel

    # CUDA and development tools
    cudaPackages.cuda_cudart
    cudaPackages.cuda_nvcc
    cudaPackages.cudnn

    # Build dependencies
    gcc
    cmake
    ninja
    git
    aria2
    vim
    ffmpeg
  ];

  shellHook = ''
    export CUDA_HOME=${pkgs.cudaPackages.cuda_nvcc}
    export LD_LIBRARY_PATH=${pkgs.cudaPackages.cuda_cudart}/lib:${pkgs.cudaPackages.cudnn}/lib:$LD_LIBRARY_PATH
    export PATH=${pkgs.cudaPackages.cuda_nvcc}/bin:$PATH
  '';
}
EOF

# Install the environment
RUN nix-shell /build-env/shell.nix --run "python3 --version"

# Set up Python and pip
RUN nix-shell /build-env/shell.nix --run "pip install --upgrade pip wheel setuptools packaging"

# Install PyTorch for CUDA 13.0
RUN nix-shell /build-env/shell.nix --run "\
    pip install torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/cu130 || \
    pip install --pre torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/nightly/cu130"

# Install custom-built wheels from GitHub releases
RUN nix-shell /build-env/shell.nix --run "\
    pip install -U uv \
    && pip install \
https://github.com/retif/pytorch-wheels-builder/releases/download/flash-attn-v2.8.2-py314-torch2.10.0-cu130/flash_attn-2.8.2-cp314-cp314-linux_x86_64.whl \
    && pip install \
https://github.com/retif/pytorch-wheels-builder/releases/download/sageattention-v2.2.0-py314-torch2.10.0-cu130/sageattention-2.2.0%2Bcu130torch2.10.0-cp314-cp314-linux_x86_64.whl \
    && pip install \
https://github.com/retif/pytorch-wheels-builder/releases/download/nunchaku-v1.0.2-py314-torch2.10.0-cu130/nunchaku-1.0.2%2Btorch2.10-cp314-cp314-linux_x86_64.whl"

# Copy build scripts
COPY builder-scripts/. /builder-scripts/

# Install ComfyUI dependencies
RUN nix-shell /build-env/shell.nix --run "\
    pip install -r /builder-scripts/pak3.txt \
    && pip install -r /builder-scripts/pak5.txt \
    && pip install -r /builder-scripts/pak7.txt"

# Install SAM-2
RUN nix-shell /build-env/shell.nix --run "\
    cd /builder-scripts \
    && git clone https://github.com/facebookresearch/sam2.git \
    && cd sam2 \
    && SAM2_BUILD_CUDA=1 pip install -e . --no-deps --no-build-isolation \
    && cd /"

# Install SAM-3
RUN nix-shell /build-env/shell.nix --run "\
    cd /builder-scripts \
    && git clone https://github.com/facebookresearch/sam3.git \
    && cd sam3 \
    && pip install -e . --no-deps --no-build-isolation \
    && cd /"

# Bundle ComfyUI and custom nodes
WORKDIR /default-comfyui-bundle

RUN nix-shell /build-env/shell.nix --run "bash /builder-scripts/preload-cache.sh"

RUN nix-shell /build-env/shell.nix --run "\
    pip install \
        -r '/default-comfyui-bundle/ComfyUI/requirements.txt' \
        -r '/default-comfyui-bundle/ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt' \
    && pip list"

# Copy runtime scripts
COPY runner-scripts/. /runner-scripts/

# Set up entrypoint
USER root
VOLUME /root
WORKDIR /root
EXPOSE 8188
ENV CLI_ARGS=""

# Create wrapper entrypoint that runs in nix-shell
RUN cat > /entrypoint-wrapper.sh <<'EOF'
#!/usr/bin/env bash
nix-shell /build-env/shell.nix --run "bash /runner-scripts/entrypoint.sh"
EOF

RUN chmod +x /entrypoint-wrapper.sh

CMD ["/entrypoint-wrapper.sh"]
