#!/usr/bin/env bash
# Unified hash filling script for python-packages.nix
# Handles: PyTorch wheels, Git repos, and PyPI packages
# Automatically updates python-packages.nix with all hashes

set -e

TARGET_FILE="python-packages.nix"
TEMP_HASHES="/tmp/all-hashes.txt"
> "$TEMP_HASHES"

echo "========================================================================"
echo "Filling ALL Package Hashes for python-packages.nix"
echo "========================================================================"
echo ""

#############################################################################
# SECTION 1: PyTorch Wheels (with URL encoding)
#############################################################################

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SECTION 1: PyTorch Wheels"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

declare -A pytorch_wheels=(
    ["torch"]="https://download.pytorch.org/whl/cu130/torch-2.10.0%2Bcu130-cp314-cp314-manylinux_2_28_x86_64.whl|torch-2.10.0-cu130-cp314-cp314-manylinux_2_28_x86_64.whl"
    ["torchvision"]="https://download.pytorch.org/whl/cu130/torchvision-0.20.0%2Bcu130-cp314-cp314-manylinux_2_28_x86_64.whl|torchvision-0.20.0-cu130-cp314-cp314-manylinux_2_28_x86_64.whl"
    ["torchaudio"]="https://download.pytorch.org/whl/cu130/torchaudio-2.10.0%2Bcu130-cp314-cp314-manylinux_2_28_x86_64.whl|torchaudio-2.10.0-cu130-cp314-cp314-manylinux_2_28_x86_64.whl"
)

for package in "${!pytorch_wheels[@]}"; do
    IFS='|' read -r url name <<< "${pytorch_wheels[$package]}"
    echo "[$package]"
    echo "  URL: $url"
    echo "  Prefetching with name: $name"

    hash=$(nix-prefetch-url --name "$name" "$url" 2>&1 | tail -1)

    if [ ! -z "$hash" ] && [[ ! "$hash" =~ "error" ]]; then
        echo "  ✅ sha256-$hash"
        echo "$package:sha256-$hash" >> "$TEMP_HASHES"
    else
        echo "  ❌ Failed (may be rate limited)"
        echo "$package:FAILED" >> "$TEMP_HASHES"
    fi
    echo ""
done

#############################################################################
# SECTION 2: Performance Wheels (flash-attn, sageattention, nunchaku)
#############################################################################

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SECTION 2: Performance Wheels"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

declare -A perf_wheels=(
    ["flash-attn"]="https://github.com/Dao-AILab/flash-attention/releases/download/v2.7.3/flash_attn-2.7.3%2Bcu12torch2.5.1cxx11abiFALSE-cp314-cp314-linux_x86_64.whl|flash_attn-2.7.3-cu12torch2.5.1cxx11abiFALSE-cp314-cp314-linux_x86_64.whl"
    ["sageattention"]="https://github.com/thu-ml/SageAttention/releases/download/v2.1.0/sageattention-2.1.0%2Bcu124torch2.5.1-cp314-cp314-linux_x86_64.whl|sageattention-2.1.0-cu124torch2.5.1-cp314-cp314-linux_x86_64.whl"
    ["nunchaku"]="https://github.com/chengzeyi/nunchaku/releases/download/v0.3.3/nunchaku-0.3.3%2Bcu124torch2.5.1-cp314-cp314-linux_x86_64.whl|nunchaku-0.3.3-cu124torch2.5.1-cp314-cp314-linux_x86_64.whl"
)

for package in "${!perf_wheels[@]}"; do
    IFS='|' read -r url name <<< "${perf_wheels[$package]}"
    echo "[$package]"
    echo "  URL: $url"
    echo "  Prefetching with name: $name"

    hash=$(nix-prefetch-url --name "$name" "$url" 2>&1 | tail -1)

    if [ ! -z "$hash" ] && [[ ! "$hash" =~ "error" ]]; then
        echo "  ✅ sha256-$hash"
        echo "$package:sha256-$hash" >> "$TEMP_HASHES"
    else
        echo "  ❌ Failed"
        echo "$package:FAILED" >> "$TEMP_HASHES"
    fi
    echo ""
done

#############################################################################
# SECTION 3: Git Repositories
#############################################################################

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SECTION 3: Git Repositories"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

declare -A git_repos=(
    ["clip"]="https://github.com/openai/CLIP.git|a1d071733d7111c9c014f024669f959182114e33"
    ["cozy-comfyui"]="https://github.com/cozy-creator/cozy-comfyui.git|d3bb7ecabdad68dc21bf0b4913b4c4ac3d3b862b"
    ["cozy-comfy"]="https://github.com/cozy-creator/gen-server.git|bb7bb2c5d29b6c3867cbe8b4ec4b29e2ce5a4ea0"
    ["cstr"]="https://github.com/ControlNet/CSTR.git|1a222b76db20b7494e0cf1de2e5ec3d4ee33ddd5"
    ["ffmpy"]="https://github.com/Ch00k/ffmpy.git|c5ea74a28e3f8d36da720028c70bb60b3c46e83f"
    ["img2texture"]="https://github.com/Artiprocher/img2texture.git|f2ceb34656bf1fb01e0f80b8f4cb26d659de6c18"
)

for package in "${!git_repos[@]}"; do
    IFS='|' read -r url rev <<< "${git_repos[$package]}"
    echo "[$package]"
    echo "  URL: $url"
    echo "  Rev: $rev"
    echo "  Prefetching..."

    hash=$(nix-prefetch-git --url "$url" --rev "$rev" 2>&1 | grep '"sha256"' | cut -d'"' -f4)

    if [ ! -z "$hash" ]; then
        echo "  ✅ sha256-$hash"
        echo "$package:sha256-$hash" >> "$TEMP_HASHES"
    else
        echo "  ❌ Failed"
        echo "$package:FAILED" >> "$TEMP_HASHES"
    fi
    echo ""
done

#############################################################################
# SECTION 4: PyPI Packages
#############################################################################

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SECTION 4: PyPI Packages"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

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

for package in "${!pypi_packages[@]}"; do
    version="${pypi_packages[$package]}"
    echo "[$package v$version]"
    echo "  Querying PyPI API..."

    api_url="https://pypi.org/pypi/$package/$version/json"
    download_url=$(curl -sL "$api_url" 2>/dev/null | \
        jq -r '.urls[] | select(.packagetype=="bdist_wheel" or .packagetype=="sdist") | .url' | \
        head -1)

    if [ -z "$download_url" ]; then
        echo "  ❌ Failed to get download URL from PyPI"
        echo "$package:FAILED" >> "$TEMP_HASHES"
        echo ""
        continue
    fi

    echo "  URL: $download_url"
    echo "  Prefetching..."

    hash=$(nix-prefetch-url "$download_url" 2>&1 | tail -1)

    if [ ! -z "$hash" ] && [[ ! "$hash" =~ "error" ]]; then
        echo "  ✅ sha256-$hash"
        echo "$package:sha256-$hash" >> "$TEMP_HASHES"
    else
        echo "  ❌ Failed to prefetch"
        echo "$package:FAILED" >> "$TEMP_HASHES"
    fi
    echo ""
done

#############################################################################
# SECTION 5: Update python-packages.nix
#############################################################################

echo "========================================================================"
echo "Hash Collection Complete - Updating $TARGET_FILE"
echo "========================================================================"
echo ""

# Count results
successes=$(grep -c -v "FAILED" "$TEMP_HASHES" || echo "0")
total=$(wc -l < "$TEMP_HASHES")

echo "Prefetched: $successes/$total packages"
echo ""

if [ ! -f "$TARGET_FILE" ]; then
    echo "❌ Error: $TARGET_FILE not found"
    exit 1
fi

# Create backup
cp "$TARGET_FILE" "${TARGET_FILE}.backup"
echo "Created backup: ${TARGET_FILE}.backup"
echo ""

# Update hashes in python-packages.nix
echo "Updating hashes in $TARGET_FILE..."
echo ""

updated_count=0
while IFS=: read -r package hash; do
    if [[ "$hash" == "FAILED" ]]; then
        echo "  ⏭️  Skipping $package (failed to prefetch)"
        continue
    fi

    # Remove "sha256-" prefix if present (nix-prefetch-url returns base32 hash)
    hash_plain="${hash#sha256-}"

    # Different sed patterns for different package types
    case "$package" in
        torch|torchvision|torchaudio|flash-attn|sageattention|nunchaku)
            # For wheel packages: look for sha256 = "..."
            if sed -i "/$package = buildWheel {/,/};/s|sha256 = \".*\";|sha256 = \"$hash_plain\";|" "$TARGET_FILE" 2>/dev/null; then
                echo "  ✅ Updated $package"
                ((updated_count++))
            else
                echo "  ⚠️  Could not update $package (pattern not found)"
            fi
            ;;
        clip|cozy-comfyui|cozy-comfy|cstr|ffmpy|img2texture)
            # For git packages: look for sha256 = "..."
            if sed -i "/$package = buildFromGit {/,/};/s|sha256 = \".*\";|sha256 = \"$hash_plain\";|" "$TARGET_FILE" 2>/dev/null; then
                echo "  ✅ Updated $package"
                ((updated_count++))
            else
                echo "  ⚠️  Could not update $package (pattern not found)"
            fi
            ;;
        *)
            # For PyPI packages: look for sha256 = "..."
            if sed -i "/$package = pythonPackages.buildPythonPackage/,/};/s|sha256 = \".*\";|sha256 = \"$hash_plain\";|" "$TARGET_FILE" 2>/dev/null; then
                echo "  ✅ Updated $package"
                ((updated_count++))
            else
                echo "  ⚠️  Could not update $package (pattern not found)"
            fi
            ;;
    esac
done < "$TEMP_HASHES"

echo ""
echo "========================================================================"
echo "Summary"
echo "========================================================================"
echo ""
echo "Prefetched hashes: $successes/$total"
echo "Updated in file: $updated_count"
echo ""

# Verify no placeholders remain
remaining=$(grep -c "lib.fakeSha256\|fakeSha256" "$TARGET_FILE" || echo "0")
echo "Remaining placeholders: $remaining"
echo ""

if [ "$remaining" -eq 0 ]; then
    echo "✅ All hashes filled successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. Review changes: git diff $TARGET_FILE"
    echo "  2. Test build: nix flake check"
    echo "  3. Build Python env: nix build .#pythonWithAllPackages"
else
    echo "⚠️  Some placeholders remain - manual intervention may be needed"
fi

echo ""
echo "Backup saved at: ${TARGET_FILE}.backup"
echo "Hash collection log: $TEMP_HASHES"
echo ""
