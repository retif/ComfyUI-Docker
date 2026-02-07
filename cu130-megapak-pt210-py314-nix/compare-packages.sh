#!/usr/bin/env bash
# Compare packages in pak files vs what's defined in flake.nix

set -e

echo "========================================"
echo "Package Coverage Analysis"
echo "========================================"
echo ""

# Extract unique packages from pak files (excluding git URLs and comments)
extract_pak_packages() {
    cat builder-scripts/pak*.txt | \
        grep -v '^#' | \
        grep -v '^git+' | \
        grep -v '^$' | \
        sed 's/\[.*\]//' | \
        sed 's/[<>=].*//' | \
        sort -u
}

# Count packages in flake.nix
count_flake_packages() {
    # Count pythonPackages references in pythonWithAllPackages
    grep -A 200 'pythonWithAllPackages = python.withPackages' flake.nix | \
        grep -E '^\s+[a-z]' | \
        grep -v '#' | \
        wc -l
}

# Get packages actually defined
get_defined_packages() {
    grep -A 200 'pythonWithAllPackages = python.withPackages' flake.nix | \
        grep -E '^\s+[a-z]' | \
        grep -v '#' | \
        sed 's/customPythonPackages\.//' | \
        sed 's/^ *//' | \
        sort -u
}

# Count packages
PAK_PACKAGES=$(extract_pak_packages | wc -l)
FLAKE_PACKAGES=$(count_flake_packages)

echo "Package counts:"
echo "  Packages in pak files:    $PAK_PACKAGES"
echo "  Packages in flake.nix:    $FLAKE_PACKAGES"
echo ""

# Find packages in pak files but not in flake
echo "Packages in pak files but NOT yet in flake.nix:"
echo "------------------------------------------------"

comm -23 <(extract_pak_packages) <(get_defined_packages) | while read pkg; do
    # Check if it's commented in flake.nix
    if grep -q "# $pkg" flake.nix 2>/dev/null; then
        echo "  ⚠️  $pkg (commented out - needs definition)"
    else
        echo "  ❌ $pkg (missing)"
    fi
done

echo ""
echo "Summary of commented/missing packages in flake.nix:"
echo "---------------------------------------------------"
grep -E '^\s+#.*TODO' flake.nix | sed 's/^ *//' | sort -u

echo ""
echo "========================================"
echo "Missing Package Categories"
echo "========================================"
echo ""

# Check specific important packages
check_package() {
    local pkg=$1
    if grep -q "customPythonPackages\.$pkg\|^\s\+$pkg\s" flake.nix; then
        echo "  ✅ $pkg (defined)"
    elif grep -q "# $pkg" flake.nix; then
        echo "  ⚠️  $pkg (commented - needs work)"
    else
        echo "  ❌ $pkg (not in flake)"
    fi
}

echo "Critical ML packages:"
check_package "onnx"
check_package "onnxruntime"
check_package "peft"

echo ""
echo "Media processing:"
check_package "av"
check_package "albumentations"
check_package "pydub"
check_package "decord"

echo ""
echo "Computer Vision:"
check_package "dlib"
check_package "cupy-cuda12x"

echo ""
echo "========================================"
echo "Conclusion"
echo "========================================"
echo ""
echo "The pure Nix version has most packages defined, but some are:"
echo "  1. Commented out (need custom buildPythonPackage definition)"
echo "  2. Need to be checked if they're in nixpkgs"
echo "  3. Can be added to python-packages.nix"
echo ""
echo "None are 'lost' - just not yet converted to pure Nix form."
echo ""
