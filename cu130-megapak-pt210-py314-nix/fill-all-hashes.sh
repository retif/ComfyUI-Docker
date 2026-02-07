#!/usr/bin/env bash
# Unified hash filling script for modular Nix packages
# Works with: pak3.nix, pak5.nix, pak7.nix, custom-packages.nix
set -e

echo "========================================"
echo "Fill Package Hashes (Modular Structure)"
echo "========================================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if a file has any empty hashes
check_empty_hashes() {
    local file=$1
    if grep -q 'sha256 = "";' "$file" 2>/dev/null; then
        return 0  # Has empty hashes
    else
        return 1  # No empty hashes
    fi
}

# Fill hashes for PyPI packages (fetchPypi)
fill_pypi_hashes() {
    local file=$1
    echo -e "${YELLOW}Processing PyPI packages in $file...${NC}"

    # Find packages with fetchPypi and empty sha256
    grep -B10 'sha256 = "";' "$file" | grep -E 'pname = |version = ' | while read -r line; do
        if [[ $line =~ pname\ =\ \"([^\"]+)\" ]]; then
            pname="${BASH_REMATCH[1]}"
        elif [[ $line =~ version\ =\ \"([^\"]+)\" ]]; then
            version="${BASH_REMATCH[1]}"

            if [ -n "$pname" ] && [ -n "$version" ]; then
                echo -e "  Fetching hash for ${GREEN}${pname}${NC} ${version}..."

                # Use nix-prefetch-url to get the hash
                hash=$(nix-prefetch-url "https://files.pythonhosted.org/packages/source/${pname:0:1}/${pname}/${pname}-${version}.tar.gz" 2>/dev/null || echo "")

                if [ -n "$hash" ]; then
                    # Update the file (find the package block and replace empty sha256)
                    sed -i "/pname = \"${pname}\"/,/sha256 = \"\";/{s|sha256 = \"\";|sha256 = \"${hash}\";|}" "$file"
                    echo -e "    ${GREEN}✓${NC} Updated hash: ${hash}"
                else
                    echo -e "    ${RED}✗${NC} Failed to fetch hash"
                fi

                pname=""
                version=""
            fi
        fi
    done
}

# Fill hashes for wheel packages (fetchurl with .whl)
fill_wheel_hashes() {
    local file=$1
    echo -e "${YELLOW}Processing wheel packages in $file...${NC}"

    # Find packages with fetchurl (wheels) and empty sha256
    grep -B5 'sha256 = "";' "$file" | grep 'url = ' | while read -r line; do
        if [[ $line =~ url\ =\ \"([^\"]+)\" ]]; then
            url="${BASH_REMATCH[1]}"

            # Extract package name from URL
            if [[ $url =~ ([^/]+)\.whl ]]; then
                wheel_name="${BASH_REMATCH[1]}"
                echo -e "  Fetching hash for ${GREEN}${wheel_name}.whl${NC}..."

                # Use nix-prefetch-url to get the hash
                hash=$(nix-prefetch-url "$url" 2>/dev/null || echo "")

                if [ -n "$hash" ]; then
                    # Update the file - replace the empty sha256 after this URL
                    # Use perl for more precise replacement
                    perl -i -pe "BEGIN{undef $/;} s|(url = \"${url//./\\.}\".*?)sha256 = \"\";|\1sha256 = \"${hash}\";|sm" "$file"
                    echo -e "    ${GREEN}✓${NC} Updated hash: ${hash}"
                else
                    echo -e "    ${RED}✗${NC} Failed to fetch hash"
                fi
            fi
        fi
    done
}

# Fill hashes for git packages (fetchFromGitHub)
fill_git_hashes() {
    local file=$1
    echo -e "${YELLOW}Processing git packages in $file...${NC}"

    # Find packages with fetchFromGitHub and empty sha256
    local in_fetch=false
    local owner=""
    local repo=""
    local rev=""

    while IFS= read -r line; do
        if [[ $line =~ fetchFromGitHub ]]; then
            in_fetch=true
            owner=""
            repo=""
            rev=""
        elif [[ $in_fetch == true ]]; then
            if [[ $line =~ owner\ =\ \"([^\"]+)\" ]]; then
                owner="${BASH_REMATCH[1]}"
            elif [[ $line =~ repo\ =\ \"([^\"]+)\" ]]; then
                repo="${BASH_REMATCH[1]}"
            elif [[ $line =~ rev\ =\ \"([^\"]+)\" ]]; then
                rev="${BASH_REMATCH[1]}"
            elif [[ $line =~ sha256\ =\ \"\" ]]; then
                if [ -n "$owner" ] && [ -n "$repo" ] && [ -n "$rev" ]; then
                    echo -e "  Fetching hash for ${GREEN}${owner}/${repo}${NC} @ ${rev}..."

                    # Use nix-prefetch-git
                    hash=$(nix-prefetch-git --url "https://github.com/${owner}/${repo}" --rev "$rev" --quiet 2>/dev/null | jq -r '.sha256' || echo "")

                    if [ -n "$hash" ] && [ "$hash" != "null" ]; then
                        # Update the file
                        perl -i -pe "BEGIN{undef $/;} s|(owner = \"${owner}\".*?repo = \"${repo}\".*?rev = \"${rev}\".*?)sha256 = \"\";|\1sha256 = \"${hash}\";|sm" "$file"
                        echo -e "    ${GREEN}✓${NC} Updated hash: ${hash}"
                    else
                        echo -e "    ${RED}✗${NC} Failed to fetch hash"
                    fi
                fi
                in_fetch=false
            fi
        fi
    done < "$file"
}

# Main processing
echo "Checking for empty hashes in modular files..."
echo ""

files=("pak3.nix" "pak5.nix" "pak7.nix" "custom-packages.nix")
updated_any=false

for file in "${files[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}✗ $file not found${NC}"
        continue
    fi

    if ! check_empty_hashes "$file"; then
        echo -e "${GREEN}✓ $file - All hashes filled${NC}"
        continue
    fi

    echo -e "${YELLOW}○ $file - Has empty hashes, processing...${NC}"
    echo ""

    # Try to fill different types of packages
    fill_pypi_hashes "$file"
    fill_wheel_hashes "$file"
    fill_git_hashes "$file"

    echo ""
    updated_any=true
done

echo "========================================"
if [ "$updated_any" = true ]; then
    echo -e "${GREEN}Hash filling complete!${NC}"
    echo ""
    echo "Verification:"
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            empty_count=$(grep -c 'sha256 = "";' "$file" 2>/dev/null || echo "0")
            filled_count=$(grep -c 'sha256 = "' "$file" 2>/dev/null || echo "0")
            if [ "$empty_count" -eq 0 ]; then
                echo -e "  ${GREEN}✓${NC} $file: $filled_count hashes filled, 0 empty"
            else
                echo -e "  ${YELLOW}○${NC} $file: $filled_count hashes filled, $empty_count empty"
            fi
        fi
    done
else
    echo -e "${GREEN}All hashes already filled!${NC}"
fi
echo "========================================"
