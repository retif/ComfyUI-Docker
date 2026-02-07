# Hash Filling for Nix Packages

## Overview

The `fill-all-hashes.sh` script automatically fills missing SHA256 hashes for packages in the modular Nix structure.

## Supported Files

- `pak3.nix` - Core ML essentials (PyPI packages)
- `pak5.nix` - Extended libraries (PyPI packages)
- `pak7.nix` - Face analysis + Git packages (PyPI + GitHub)
- `custom-packages.nix` - PyTorch wheels + performance libraries (wheels)

## Usage

### Check and fill all missing hashes:
```bash
./fill-all-hashes.sh
```

The script will:
1. Check each module for empty hashes (`sha256 = "";`)
2. Automatically fetch the correct hash based on package type:
   - **PyPI packages** (`fetchPypi`) - Uses `nix-prefetch-url` with PyPI URLs
   - **Wheel packages** (`fetchurl` with `.whl`) - Uses `nix-prefetch-url` with direct URLs
   - **Git packages** (`fetchFromGitHub`) - Uses `nix-prefetch-git` with GitHub repos
3. Update the `.nix` file with the fetched hash
4. Show verification summary

### Expected Output

If all hashes are filled:
```
✓ pak3.nix - All hashes filled
✓ pak5.nix - All hashes filled
✓ pak7.nix - All hashes filled
✓ custom-packages.nix - All hashes filled
All hashes already filled!
```

If hashes need filling:
```
○ pak3.nix - Has empty hashes, processing...
  Fetching hash for accelerate 1.2.1...
    ✓ Updated hash: 1pwdxvyfl2sl47cr8zcw9klql6sbjq9bhinyzg6yfdzqijavn75y
```

## Package Types

### 1. PyPI Packages (pak3.nix, pak5.nix, pak7.nix)

```nix
packageName = pythonPackages.buildPythonPackage rec {
  pname = "packagename";
  version = "1.0.0";
  src = pythonPackages.fetchPypi {
    inherit pname version;
    sha256 = "";  # ← Script fills this
  };
};
```

### 2. Wheel Packages (custom-packages.nix)

```nix
packageName = buildWheel {
  pname = "packagename";
  version = "1.0.0";
  src = fetchurl {
    url = "https://example.com/package.whl";
    sha256 = "";  # ← Script fills this
  };
};
```

### 3. Git Packages (pak7.nix)

```nix
packageName = buildFromGit {
  pname = "packagename";
  version = "unstable-2024-01-01";
  src = fetchFromGitHub {
    owner = "username";
    repo = "reponame";
    rev = "commit-hash-or-tag";
    sha256 = "";  # ← Script fills this
  };
};
```

## Manual Hash Fetching

If the script fails or you need to fetch a hash manually:

### For PyPI packages:
```bash
nix-prefetch-url "https://files.pythonhosted.org/packages/source/p/packagename/packagename-1.0.0.tar.gz"
```

### For wheels:
```bash
nix-prefetch-url "https://example.com/package.whl"
```

### For Git repos:
```bash
nix-prefetch-git --url "https://github.com/owner/repo" --rev "commit-hash"
# Extract sha256 from JSON output
```

## Requirements

The script requires:
- `nix-prefetch-url` (part of Nix)
- `nix-prefetch-git` (part of Nix)
- `jq` (for parsing JSON from nix-prefetch-git)
- `perl` (for advanced text replacement)

## Adding New Packages

1. Add package definition to the appropriate `.nix` file with empty hash:
   ```nix
   sha256 = "";
   ```

2. Run the hash filling script:
   ```bash
   ./fill-all-hashes.sh
   ```

3. Verify the hash was filled:
   ```bash
   grep -A2 "pname = \"yourpackage\"" pak3.nix
   ```

## Troubleshooting

### Hash fetch fails
- **PyPI**: Package may not exist on PyPI or version is wrong
- **Wheel**: URL may be incorrect or require authentication
- **Git**: Repo may not exist or commit hash is invalid

### Script doesn't update file
- Check that the package definition format matches examples above
- Ensure `pname`, `version`, or `url` fields are correctly formatted
- Try manual hash fetching to verify the source is accessible

## See Also

- [LAYERS.md](LAYERS.md) - Layer architecture documentation
- [flake.nix](flake.nix) - Main Nix flake configuration
- [package-lists.nix](package-lists.nix) - Centralized package organization
