#!/usr/bin/env bash
# Refetch all package hashes and update to correct SRI format
set -e

echo "Refetching ALL package hashes..."
echo "This will take several minutes..."
echo ""

# Process each .nix file
for file in pak3.nix pak5.nix pak7.nix custom-packages.nix; do
    if [ ! -f "$file" ]; then
        echo "⊗ $file not found, skipping"
        continue
    fi

    echo "==== Processing $file ===="

    # Find all fetchPypi blocks with hash
    grep -n 'pname = \|version = \|hash = "sha256-' "$file" | while IFS=: read -r line_num content; do
        # Accumulate pname, version, and hash
        if [[ $content =~ pname\ =\ \"([^\"]+)\" ]]; then
            pname="${BASH_REMATCH[1]}"
        elif [[ $content =~ version\ =\ \"([^\"]+)\" ]]; then
            version="${BASH_REMATCH[1]}"
        elif [[ $content =~ hash\ =\ \"(sha256-[^\"]+)\" ]]; then
            old_hash="${BASH_REMATCH[1]}"

            if [ -n "$pname" ] && [ -n "$version" ]; then
                echo "  $pname@$version"

                # Fetch the correct hash
                base32_hash=$(nix-prefetch-url "https://files.pythonhosted.org/packages/source/${pname:0:1}/${pname}/${pname}-${version}.tar.gz" 2>/dev/null || echo "")

                if [ -n "$base32_hash" ]; then
                    # Convert to SRI
                    new_hash=$(nix hash to-sri --type sha256 "$base32_hash" 2>/dev/null || echo "")

                    if [ -n "$new_hash" ] && [ "$new_hash" != "$old_hash" ]; then
                        # Update the file
                        sed -i "s|hash = \"$old_hash\"|hash = \"$new_hash\"|g" "$file"
                        echo "    ✓ Updated: $old_hash → $new_hash"
                    elif [ "$new_hash" == "$old_hash" ]; then
                        echo "    ✓ Already correct"
                    else
                        echo "    ✗ Failed to convert hash"
                    fi
                else
                    echo "    ✗ Failed to fetch"
                fi

                pname=""
                version=""
            fi
        fi
    done

    echo ""
done

echo "Refetch complete!"
