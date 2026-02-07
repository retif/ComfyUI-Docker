#!/usr/bin/env bash
# Convert all old base32 sha256 hashes to SRI format
set -e

echo "Converting base32 hashes to SRI format..."

for file in pak3.nix pak5.nix pak7.nix custom-packages.nix; do
    if [ ! -f "$file" ]; then
        echo "⊗ $file not found, skipping"
        continue
    fi

    echo "Processing $file..."

    # Find all sha256 = "..." lines (base32 format)
    grep -n 'sha256 = "[0-9a-z]\{52\}";' "$file" | while IFS=: read -r line_num line_content; do
        # Extract the base32 hash
        if [[ $line_content =~ sha256\ =\ \"([0-9a-z]{52})\" ]]; then
            base32_hash="${BASH_REMATCH[1]}"

            # Convert to SRI
            sri_hash=$(nix hash to-sri --type sha256 "$base32_hash" 2>/dev/null || echo "")

            if [ -n "$sri_hash" ]; then
                # Replace in file
                sed -i "${line_num}s|sha256 = \"${base32_hash}\";|hash = \"${sri_hash}\";|" "$file"
                echo "  Line $line_num: $base32_hash → $sri_hash"
            else
                echo "  Line $line_num: Failed to convert $base32_hash"
            fi
        fi
    done

    echo "✓ $file done"
    echo ""
done

echo "Conversion complete!"
