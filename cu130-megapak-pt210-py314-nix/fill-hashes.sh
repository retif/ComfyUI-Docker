#!/usr/bin/env bash
# Automatically fill in sha256 hashes in python-packages.nix
# This script extracts URLs, prefetches hashes, and updates the file

set -e

PACKAGES_FILE="python-packages.nix"
TEMP_FILE="${PACKAGES_FILE}.tmp"

echo "========================================"
echo "Filling hashes in python-packages.nix"
echo "========================================"
echo ""

# Function to prefetch and update hash for a URL
prefetch_and_update() {
    local url="$1"
    local line_num="$2"

    echo "Prefetching: $url"

    # Prefetch the hash
    local hash
    if hash=$(nix-prefetch-url "$url" 2>/dev/null); then
        echo "  ✅ Hash: sha256-$hash"

        # Convert to SRI format (sha256-...)
        local sri_hash="sha256-$hash"

        # Update the file - find the next line with placeholder hash
        sed -i "${line_num}s/sha256-0\{52\}/sha256-${hash}/" "$PACKAGES_FILE"

        return 0
    else
        echo "  ❌ Failed to prefetch"
        return 1
    fi
}

# Function to extract PyPI URL from pname and version
get_pypi_url() {
    local pname="$1"
    local version="$2"

    # PyPI URL format: https://files.pythonhosted.org/packages/.../package-version.tar.gz
    # We need to query PyPI API to get the actual URL
    echo "https://pypi.org/pypi/${pname}/${version}/json"
}

echo "Step 1: Prefetching wheel URLs (PyTorch, performance libs)"
echo "-----------------------------------------------------------"

# PyTorch wheels
echo ""
echo "PyTorch wheels:"
nix-prefetch-url "https://download.pytorch.org/whl/cu130/torch-2.10.0%2Bcu130-cp314-cp314-linux_x86_64.whl" > /tmp/torch.hash || echo "Failed"
nix-prefetch-url "https://download.pytorch.org/whl/cu130/torchvision-0.20.0%2Bcu130-cp314-cp314-linux_x86_64.whl" > /tmp/torchvision.hash || echo "Failed"
nix-prefetch-url "https://download.pytorch.org/whl/cu130/torchaudio-2.10.0%2Bcu130-cp314-cp314-linux_x86_64.whl" > /tmp/torchaudio.hash || echo "Failed"

# Performance wheels
echo ""
echo "Performance wheels:"
nix-prefetch-url "https://github.com/retif/pytorch-wheels-builder/releases/download/flash-attn-v2.8.2-py314-torch2.10.0-cu130/flash_attn-2.8.2-cp314-cp314-linux_x86_64.whl" > /tmp/flash-attn.hash || echo "Failed"
nix-prefetch-url "https://github.com/retif/pytorch-wheels-builder/releases/download/sageattention-v2.2.0-py314-torch2.10.0-cu130/sageattention-2.2.0%2Bcu130torch2.10.0-cp314-cp314-linux_x86_64.whl" > /tmp/sageattention.hash || echo "Failed"
nix-prefetch-url "https://github.com/retif/pytorch-wheels-builder/releases/download/nunchaku-v1.0.2-py314-torch2.10.0-cu130/nunchaku-1.0.2%2Btorch2.10-cp314-cp314-linux_x86_64.whl" > /tmp/nunchaku.hash || echo "Failed"

echo ""
echo "Step 2: Prefetching git repositories"
echo "-------------------------------------"

# Git repos
echo ""
echo "Git repositories:"
nix-prefetch-git https://github.com/openai/CLIP 2>/dev/null | jq -r '.sha256' > /tmp/clip.hash || echo "Failed"
nix-prefetch-git https://github.com/cozy-comfyui/cozy_comfyui 2>/dev/null | jq -r '.sha256' > /tmp/cozy-comfyui.hash || echo "Failed"
nix-prefetch-git https://github.com/cozy-comfyui/cozy_comfy 2>/dev/null | jq -r '.sha256' > /tmp/cozy-comfy.hash || echo "Failed"
nix-prefetch-git https://github.com/ltdrdata/cstr 2>/dev/null | jq -r '.sha256' > /tmp/cstr.hash || echo "Failed"
nix-prefetch-git https://github.com/ltdrdata/ffmpy 2>/dev/null | jq -r '.sha256' > /tmp/ffmpy.hash || echo "Failed"
nix-prefetch-git https://github.com/ltdrdata/img2texture 2>/dev/null | jq -r '.sha256' > /tmp/img2texture.hash || echo "Failed"

echo ""
echo "Step 3: Updating python-packages.nix with hashes"
echo "-------------------------------------------------"

# Update the file with actual hashes
update_hash() {
    local package="$1"
    local hash_file="$2"

    if [ -f "$hash_file" ]; then
        local hash=$(cat "$hash_file")
        if [ ! -z "$hash" ] && [ "$hash" != "Failed" ]; then
            echo "Updating $package: sha256-$hash"
            # Find the package definition and update its hash
            # This is a simple approach - may need refinement
            sed -i "/pname = \"$package\"/,/sha256-0\{52\}/s/sha256-0\{52\}/sha256-$hash/" "$PACKAGES_FILE"
        fi
    fi
}

# Update PyTorch
update_hash "torch" /tmp/torch.hash
update_hash "torchvision" /tmp/torchvision.hash
update_hash "torchaudio" /tmp/torchaudio.hash

# Update performance
update_hash "flash-attn" /tmp/flash-attn.hash
update_hash "sageattention" /tmp/sageattention.hash
update_hash "nunchaku" /tmp/nunchaku.hash

# Update git repos
update_hash "clip" /tmp/clip.hash
update_hash "cozy-comfyui" /tmp/cozy-comfyui.hash
update_hash "cozy-comfy" /tmp/cozy-comfy.hash
update_hash "cstr" /tmp/cstr.hash
update_hash "ffmpy" /tmp/ffmpy.hash
update_hash "img2texture" /tmp/img2texture.hash

echo ""
echo "Step 4: PyPI packages (slower - querying PyPI API)"
echo "---------------------------------------------------"
echo "NOTE: PyPI packages need to query the API to get actual download URLs"
echo "This step is optional - you can manually prefetch these later"
echo ""

# List of PyPI packages to prefetch
declare -A pypi_packages=(
    ["ftfy"]="6.3.1"
    ["nvidia-ml-py"]="12.560.30"
    ["opencv-contrib-python"]="4.10.0.84"
    ["opencv-contrib-python-headless"]="4.10.0.84"
    ["timm"]="1.0.17"
    ["accelerate"]="1.2.1"
    ["diffusers"]="0.31.0"
    ["torchmetrics"]="1.6.0"
    ["kornia"]="0.7.4"
    ["compel"]="2.0.3"
    ["lark"]="1.2.2"
    ["spandrel"]="0.4.0"
    ["insightface"]="0.7.3"
    ["facexlib"]="0.3.0"
    ["addict"]="2.4.0"
    ["loguru"]="0.7.3"
)

echo "To prefetch PyPI packages, run:"
echo ""
for pkg in "${!pypi_packages[@]}"; do
    version="${pypi_packages[$pkg]}"
    echo "  # $pkg"
    echo "  curl -sL https://pypi.org/pypi/${pkg}/${version}/json | jq -r '.urls[] | select(.packagetype==\"bdist_wheel\" or .packagetype==\"sdist\") | .url' | head -1 | xargs nix-prefetch-url"
    echo ""
done

echo ""
echo "========================================"
echo "Hash filling complete!"
echo "========================================"
echo ""
echo "Verification:"
echo "  1. Check python-packages.nix for updated hashes"
echo "  2. Count remaining placeholders:"
echo "     grep -c 'sha256-0\\{52\\}' python-packages.nix"
echo ""
echo "Next steps:"
echo "  1. nix flake check"
echo "  2. nix build .#pythonWithAllPackages"
echo ""
