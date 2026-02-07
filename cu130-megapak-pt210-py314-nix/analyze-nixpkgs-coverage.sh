#!/usr/bin/env bash
# Analyze which Python packages from pak files are available in nixpkgs

set -e

echo "Analyzing nixpkgs coverage for Python packages..."
echo ""

# Common packages that ARE in nixpkgs (python314Packages)
cat > nixpkgs-available.txt <<EOF
# Core scientific computing
numpy
scipy
pillow
imageio

# ML/AI
scikit-learn
scikit-image
opencv4
transformers

# Data processing
pandas
h5py
pyarrow

# Data formats
pyyaml
toml
msgpack

# HTTP/networking
requests
urllib3
aiohttp
httpx
websocket-client

# Async
asyncio

# CLI/utilities
tqdm
click
psutil
jinja2

# Testing
pytest

# Compression
zstandard

# Image processing
imageio-ffmpeg

# Database
sqlalchemy

# Crypto
cryptography
pyjwt

# Other utilities
python-dateutil
colorama
einops
omegaconf
safetensors
sentencepiece
tokenizers
EOF

echo "Packages available in nixpkgs (python314Packages):"
cat nixpkgs-available.txt
echo ""
echo "============================================"
echo ""

# These need pip (not in nixpkgs or version mismatch)
cat > pip-needed.txt <<EOF
# PyTorch ecosystem (need specific CUDA version)
torch
torchvision
torchaudio

# Performance (custom builds)
flash-attn
sageattention
nunchaku
xformers

# ComfyUI specific
comfyui-*

# Cutting-edge AI (not yet in nixpkgs)
diffusers
accelerate
bitsandbytes

# Specific versions needed
onnxruntime-gpu

# SAM (build from source)
segment-anything
EOF

echo "Packages that need pip or custom build:"
cat pip-needed.txt
echo ""

rm nixpkgs-available.txt pip-needed.txt

echo "Recommendation:"
echo "1. Use nixpkgs for ~40-50 common packages (numpy, scipy, requests, etc.)"
echo "2. Use pre-fetched wheels for PyTorch + performance libs"
echo "3. Use pip only for cutting-edge AI packages not in nixpkgs yet"
echo "4. Build SAM-2/3 from source as Nix derivations"
