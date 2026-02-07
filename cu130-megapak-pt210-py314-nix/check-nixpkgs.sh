#!/usr/bin/env bash
# Check package availability in nixpkgs and analyze coverage
# Dynamically queries nixpkgs and reports available vs custom packages

set -e

echo "========================================================================"
echo "Checking Package Availability in nixpkgs python314Packages"
echo "========================================================================"
echo ""

check_package() {
    local pkg=$1
    # Convert Python package names to nixpkgs format (dashes may become underscores)
    local nix_pkg=$(echo "$pkg" | sed 's/-/_/g' | cut -d'[' -f1)

    if nix eval --raw "nixpkgs#python314Packages.${nix_pkg}.pname" 2>/dev/null >/dev/null; then
        echo "  ✅ $pkg → python314Packages.${nix_pkg}"
        return 0
    else
        echo "  ❌ $pkg (needs custom definition)"
        return 1
    fi
}

available_total=0
missing_total=0

# Check PAK3.TXT (core ML packages)
if [ -f "../cu130-megapak-pt210-py314/builder-scripts/pak3.txt" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "PAK3.TXT - Core ML Packages"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    available=0
    missing=0

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
    done < "../cu130-megapak-pt210-py314/builder-scripts/pak3.txt"

    echo "  Summary: $available available, $missing need custom"
    echo ""
    ((available_total += available))
    ((missing_total += missing))
fi

# Check PAK5.TXT (utilities)
if [ -f "../cu130-megapak-pt210-py314/builder-scripts/pak5.txt" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "PAK5.TXT - Utilities & Extensions"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    available=0
    missing=0

    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^git\+ ]] && continue

        pkg=$(echo "$line" | xargs)
        if check_package "$pkg"; then
            ((available++))
        else
            ((missing++))
        fi
    done < "../cu130-megapak-pt210-py314/builder-scripts/pak5.txt"

    echo "  Summary: $available available, $missing need custom"
    echo ""
    ((available_total += available))
    ((missing_total += missing))
fi

# Check PAK7.TXT (face analysis)
if [ -f "../cu130-megapak-pt210-py314/builder-scripts/pak7.txt" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "PAK7.TXT - Face Analysis"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    available=0
    missing=0

    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^git\+ ]] && continue

        pkg=$(echo "$line" | xargs)
        if check_package "$pkg"; then
            ((available++))
        else
            ((missing++))
        fi
    done < "../cu130-megapak-pt210-py314/builder-scripts/pak7.txt"

    echo "  Summary: $available available, $missing need custom"
    echo ""
    ((available_total += available))
    ((missing_total += missing))
fi

echo "========================================================================"
echo "Overall Summary"
echo "========================================================================"
echo ""
total=$((available_total + missing_total))
percentage=$((available_total * 100 / total))

echo "  ✅ Available in nixpkgs: $available_total packages ($percentage%)"
echo "  ❌ Need custom definitions: $missing_total packages"
echo "  📦 Total checked: $total packages"
echo ""
echo "Coverage: Using nixpkgs for majority of common packages reduces build complexity"
echo ""
echo "Next steps:"
echo "  1. Available packages → Add to flake.nix pythonWithAllPackages"
echo "  2. Missing packages → Define in python-packages.nix"
echo "  3. Verify: nix flake check"
echo ""
