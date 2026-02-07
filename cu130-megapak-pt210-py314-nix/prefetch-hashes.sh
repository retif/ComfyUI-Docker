#!/usr/bin/env bash
# Prefetch all wheel hashes for flake-layered.nix

set -e

echo "Prefetching PyTorch wheels..."
echo ""

echo "torch:"
nix-prefetch-url "https://download.pytorch.org/whl/cu130/torch-2.10.0%2Bcu130-cp314-cp314-linux_x86_64.whl"
echo ""

echo "torchvision:"
nix-prefetch-url "https://download.pytorch.org/whl/cu130/torchvision-0.20.0%2Bcu130-cp314-cp314-linux_x86_64.whl"
echo ""

echo "torchaudio:"
nix-prefetch-url "https://download.pytorch.org/whl/cu130/torchaudio-2.10.0%2Bcu130-cp314-cp314-linux_x86_64.whl"
echo ""

echo "Prefetching performance wheels..."
echo ""

echo "flash-attn:"
nix-prefetch-url "https://github.com/retif/pytorch-wheels-builder/releases/download/flash-attn-v2.8.2-py314-torch2.10.0-cu130/flash_attn-2.8.2-cp314-cp314-linux_x86_64.whl"
echo ""

echo "sageattention:"
nix-prefetch-url "https://github.com/retif/pytorch-wheels-builder/releases/download/sageattention-v2.2.0-py314-torch2.10.0-cu130/sageattention-2.2.0%2Bcu130torch2.10.0-cp314-cp314-linux_x86_64.whl"
echo ""

echo "nunchaku:"
nix-prefetch-url "https://github.com/retif/pytorch-wheels-builder/releases/download/nunchaku-v1.0.2-py314-torch2.10.0-cu130/nunchaku-1.0.2%2Btorch2.10-cp314-cp314-linux_x86_64.whl"
echo ""

echo "Done! Copy these hashes into flake-layered.nix"
