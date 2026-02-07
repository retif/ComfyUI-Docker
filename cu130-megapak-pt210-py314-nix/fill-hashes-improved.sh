#!/usr/bin/env bash
# Improved hash filling script that handles URL encoding correctly

set -e

echo "========================================"
echo "Filling Hashes - Improved Version"
echo "========================================"
echo ""

# Prefetch with proper name parameter to handle URL encoding
prefetch_wheel() {
    local url="$1"
    local name="$2"

    echo "Prefetching: $name"
    echo "  URL: $url"

    local hash
    if hash=$(nix-prefetch-url --name "$name" "$url" 2>&1 | tail -1); then
        echo "  ✅ Hash: $hash"
        echo "$hash"
        return 0
    else
        echo "  ❌ Failed: $hash"
        return 1
    fi
}

# Create a temp file to store hashes
HASH_FILE="/tmp/nix-hashes.txt"
> "$HASH_FILE"

echo "Step 1: PyTorch Wheels (large downloads, ~2-3GB each)"
echo "-----------------------------------------------------"
echo ""

# Torch
if hash=$(prefetch_wheel \
    "https://download.pytorch.org/whl/cu130/torch-2.10.0%2Bcu130-cp314-cp314-manylinux_2_28_x86_64.whl" \
    "torch-2.10.0-cu130-cp314-cp314-manylinux_2_28_x86_64.whl"); then
    echo "torch:$hash" >> "$HASH_FILE"
fi

# Torchvision
if hash=$(prefetch_wheel \
    "https://download.pytorch.org/whl/cu130/torchvision-0.20.0%2Bcu130-cp314-cp314-manylinux_2_28_x86_64.whl" \
    "torchvision-0.20.0-cu130-cp314-cp314-manylinux_2_28_x86_64.whl"); then
    echo "torchvision:$hash" >> "$HASH_FILE"
fi

# Torchaudio
if hash=$(prefetch_wheel \
    "https://download.pytorch.org/whl/cu130/torchaudio-2.10.0%2Bcu130-cp314-cp314-manylinux_2_28_x86_64.whl" \
    "torchaudio-2.10.0-cu130-cp314-cp314-manylinux_2_28_x86_64.whl"); then
    echo "torchaudio:$hash" >> "$HASH_FILE"
fi

echo ""
echo "Step 2: Performance Wheels"
echo "--------------------------"
echo ""

# Flash Attention
if hash=$(prefetch_wheel \
    "https://github.com/retif/pytorch-wheels-builder/releases/download/flash-attn-v2.8.2-py314-torch2.10.0-cu130/flash_attn-2.8.2-cp314-cp314-linux_x86_64.whl" \
    "flash_attn-2.8.2-cp314-cp314-linux_x86_64.whl"); then
    echo "flash-attn:$hash" >> "$HASH_FILE"
fi

# SageAttention
if hash=$(prefetch_wheel \
    "https://github.com/retif/pytorch-wheels-builder/releases/download/sageattention-v2.2.0-py314-torch2.10.0-cu130/sageattention-2.2.0%2Bcu130torch2.10.0-cp314-cp314-linux_x86_64.whl" \
    "sageattention-2.2.0-cu130torch2.10.0-cp314-cp314-linux_x86_64.whl"); then
    echo "sageattention:$hash" >> "$HASH_FILE"
fi

# Nunchaku
if hash=$(prefetch_wheel \
    "https://github.com/retif/pytorch-wheels-builder/releases/download/nunchaku-v1.0.2-py314-torch2.10.0-cu130/nunchaku-1.0.2%2Btorch2.10-cp314-cp314-linux_x86_64.whl" \
    "nunchaku-1.0.2-torch2.10-cp314-cp314-linux_x86_64.whl"); then
    echo "nunchaku:$hash" >> "$HASH_FILE"
fi

echo ""
echo "Step 3: Git Repositories"
echo "------------------------"
echo ""

prefetch_git() {
    local url="$1"
    local name="$2"

    echo "Prefetching git: $name"
    echo "  URL: $url"

    local hash
    if hash=$(nix-prefetch-git "$url" 2>/dev/null | jq -r '.sha256'); then
        echo "  ✅ Hash: $hash"
        echo "$name:$hash" >> "$HASH_FILE"
        return 0
    else
        echo "  ❌ Failed"
        return 1
    fi
}

prefetch_git "https://github.com/openai/CLIP" "clip"
prefetch_git "https://github.com/cozy-comfyui/cozy_comfyui" "cozy-comfyui"
prefetch_git "https://github.com/cozy-comfyui/cozy_comfy" "cozy-comfy"
prefetch_git "https://github.com/ltdrdata/cstr" "cstr"
prefetch_git "https://github.com/ltdrdata/ffmpy" "ffmpy"
prefetch_git "https://github.com/ltdrdata/img2texture" "img2texture"

echo ""
echo "========================================"
echo "Collected Hashes"
echo "========================================"
echo ""
cat "$HASH_FILE"
echo ""

echo "To update python-packages.nix manually:"
echo "  1. Open python-packages.nix"
echo "  2. Replace placeholder hashes with values above"
echo "  3. Format: hash = \"sha256-<hash>\";"
echo ""
echo "Or use the automated script (coming soon)"
echo ""
