#!/usr/bin/env bash
# Automated PyPI package hash filling
# Queries PyPI API to get actual download URLs and prefetches hashes

set -e

echo "========================================"
echo "Filling PyPI Package Hashes"
echo "========================================"
echo ""

# Define packages from python-packages.nix
declare -A packages=(
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

OUTPUT_FILE="/tmp/pypi-hashes.txt"
> "$OUTPUT_FILE"

echo "Querying PyPI API and prefetching hashes..."
echo ""

for package in "${!packages[@]}"; do
    version="${packages[$package]}"
    echo "[$package v$version]"

    # Query PyPI API
    echo "  Querying PyPI API..."
    api_url="https://pypi.org/pypi/$package/$version/json"

    # Get the first wheel or sdist URL
    download_url=$(curl -sL "$api_url" 2>/dev/null | \
        jq -r '.urls[] | select(.packagetype=="bdist_wheel" or .packagetype=="sdist") | .url' | \
        head -1)

    if [ -z "$download_url" ]; then
        echo "  ❌ Failed to get download URL from PyPI"
        echo "$package:FAILED"
        continue
    fi

    echo "  URL: $download_url"

    # Extract filename from URL
    filename=$(basename "$download_url")

    # Prefetch hash
    echo "  Prefetching..."
    hash=$(nix-prefetch-url "$download_url" 2>&1 | tail -1)

    if [ ! -z "$hash" ] && [[ ! "$hash" =~ "error" ]]; then
        echo "  ✅ Hash: sha256-$hash"
        echo "$package:sha256-$hash" >> "$OUTPUT_FILE"
    else
        echo "  ❌ Failed to prefetch"
        echo "$package:FAILED" >> "$OUTPUT_FILE"
    fi

    echo ""
done

echo "========================================"
echo "Results"
echo "========================================"
echo ""
cat "$OUTPUT_FILE"
echo ""

# Count successes
successes=$(grep -c -v "FAILED" "$OUTPUT_FILE" || echo "0")
total=${#packages[@]}

echo "Summary: $successes/$total packages successfully prefetched"
echo ""
echo "Hashes saved to: $OUTPUT_FILE"
echo ""
echo "To update python-packages.nix:"
echo "  1. For each package in $OUTPUT_FILE"
echo "  2. Replace the placeholder hash with the real hash"
echo "  3. Format: hash = \"sha256-<hash>\";"
echo ""
