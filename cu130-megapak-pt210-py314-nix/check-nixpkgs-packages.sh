#!/usr/bin/env bash
# Check which packages from pak files are available in nixpkgs

set -e

echo "Checking package availability in nixpkgs python314Packages..."
echo "================================================================"
echo ""

check_package() {
    local pkg=$1
    # Convert Python package names to nixpkgs format (dashes to underscores, etc.)
    local nix_pkg=$(echo "$pkg" | sed 's/-/_/g' | cut -d'[' -f1)

    if nix eval --raw "nixpkgs#python314Packages.${nix_pkg}.pname" 2>/dev/null >/dev/null; then
        echo "✅ $pkg → python314Packages.${nix_pkg}"
        return 0
    else
        echo "❌ $pkg (not in nixpkgs, need custom package)"
        return 1
    fi
}

echo "PAK3.TXT packages:"
echo "------------------"
available=0
missing=0

while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue

    pkg=$(echo "$line" | xargs)  # trim whitespace
    if check_package "$pkg"; then
        ((available++))
    else
        ((missing++))
    fi
done < builder-scripts/pak3.txt

echo ""
echo "PAK5.TXT packages:"
echo "------------------"
while IFS= read -r line; do
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue

    pkg=$(echo "$line" | xargs)
    if check_package "$pkg"; then
        ((available++))
    else
        ((missing++))
    fi
done < builder-scripts/pak5.txt

echo ""
echo "PAK7.TXT packages:"
echo "------------------"
while IFS= read -r line; do
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^git\+ ]] && continue  # Skip git packages

    pkg=$(echo "$line" | xargs)
    if check_package "$pkg"; then
        ((available++))
    else
        ((missing++))
    fi
done < builder-scripts/pak7.txt

echo ""
echo "================================================================"
echo "Summary:"
echo "  ✅ Available in nixpkgs: $available packages"
echo "  ❌ Need custom definitions: $missing packages"
echo ""
echo "Next steps:"
echo "  1. Add available packages to flake.nix pythonWithAllPackages"
echo "  2. Create custom definitions in python-packages.nix for missing packages"
echo "  3. Run: nix flake check"
