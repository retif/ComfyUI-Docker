# NixOS Workflow Design Improvements

## Issues Encountered

### 1. CUDA Package Collisions
**Problem**: `cudatoolkit` and `cudnn` have conflicting LICENSE files
**Current Fix**: `ignoreCollisions = true` (works but inelegant)
**Better Solutions**:

```nix
# Option A: Use symlinkJoin instead of buildEnv
copyToRoot = pkgs.symlinkJoin {
  name = "base-root";
  paths = [ cudaPackages.cudatoolkit cudaPackages.cudnn ... ];
};

# Option B: Use cuda-merged package
cudaPackages = pkgs.cudaPackages_13_0.override {
  # Compose CUDA packages properly
};

# Option C: Separate CUDA into its own layer
cudaLayer = pkgs.dockerTools.buildImage {
  # Only CUDA packages here
};
```

### 2. No Binary Caching (Cachix)
**Problem**: Disabled Cachix due to GitHub Actions secret comparison issues
**Impact**: Every build rebuilds everything from scratch (45-70 min)
**Better Solutions**:

```yaml
# Option A: Use step-level conditional
- name: Setup Cachix
  if: vars.CACHIX_ENABLED == 'true'  # Use repository variable
  uses: cachix/cachix-action@v14
  with:
    name: comfyui-docker
    authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'

# Option B: Use GitHub's native cache
- name: Cache Nix store
  uses: actions/cache@v4
  with:
    path: |
      ~/.cache/nix
      /nix/store
    key: nix-${{ hashFiles('flake.lock') }}

# Option C: Self-hosted binary cache
# Set up nginx with nix-serve on a dedicated server
```

**Recommendation**: Set up Cachix properly - saves 40-60 minutes per build after first successful build.

### 3. Hybrid Nix/Pip Approach
**Problem**: Installing PyTorch and Python packages via pip inside Nix layers
**Why**: PyTorch with CUDA 13.0 not in nixpkgs, custom wheels needed
**Better Solutions**:

```nix
# Option A: Pure Nix with custom derivations
pytorch-cuda130 = python.pkgs.buildPythonPackage {
  pname = "torch";
  version = "2.10.0";
  format = "wheel";
  src = fetchurl {
    url = "https://download.pytorch.org/whl/cu130/torch-2.10.0%2Bcu130-cp314-cp314-linux_x86_64.whl";
    hash = "sha256-...";  # Pin hash for reproducibility
  };
};

# Option B: Use dream2nix or poetry2nix
# Convert requirements.txt to Nix derivations automatically

# Option C: Build wheels in separate Nix derivation
flash-attn = python.pkgs.buildPythonPackage rec {
  pname = "flash-attn";
  version = "2.8.2";
  src = fetchFromGitHub {
    owner = "Dao-AILab";
    repo = "flash-attention";
    rev = "v${version}";
    hash = "sha256-...";
  };
  buildInputs = [ cudaPackages.cudatoolkit ];
  # Build from source with Nix's CUDA
};
```

**Benefits**:
- True reproducibility (no network calls during build)
- Better layer caching (content-addressed)
- Offline builds possible

### 4. Layer Optimization
**Problem**: Current 6-layer approach is manual and not optimized
**Better Solutions**:

```nix
# Use streamLayeredImage's automatic optimization
finalImage = pkgs.dockerTools.streamLayeredImage {
  name = "comfyui-boot";
  fromImage = null;  # Don't chain images

  # Just specify all contents
  contents = [
    baseEnv
    pythonEnv
    pytorchEnv
    # ...
  ];

  # Let Nix optimize layer splitting
  maxLayers = 100;  # Docker supports up to 125
};

# Or use dockerTools.buildLayeredImage
# Automatically splits based on package closure sizes
```

**Benefits**:
- Better layer deduplication
- Automatic optimization based on package sizes
- Fewer manual layer boundaries

### 5. Script Integration Pattern
**Problem**: Copying scripts into image feels imperative
**Better Solution**:

```nix
# Define scripts as Nix derivations
builderScripts = pkgs.stdenv.mkDerivation {
  name = "comfyui-builder-scripts";
  src = ./builder-scripts;
  installPhase = ''
    mkdir -p $out/bin
    cp -r * $out/bin/
    chmod +x $out/bin/*.sh
  '';
};

# Then reference in layer
runAsRoot = ''
  ${builderScripts}/bin/preload-cache.sh
'';
```

**Benefits**:
- Scripts are proper Nix derivations
- Version controlled and content-addressed
- Can be shared across images

### 6. Long Build Times on CI
**Problem**: 45-70 minute builds without caching
**Better Solutions**:

```yaml
# Option A: Build layers in parallel (if independent)
strategy:
  matrix:
    layer: [base, python, pytorch, deps]
parallel: true

# Option B: Use GitHub's larger runners
runs-on: ubuntu-latest-8-cores  # Or self-hosted with more resources

# Option C: Split into multiple workflows
# - base-layers.yml (runs weekly, cached)
# - application.yml (runs on every commit, uses cached base)

# Option D: Only rebuild changed layers
- name: Check layer changes
  id: changes
  run: |
    if git diff --name-only HEAD~1 | grep -q "pak.*\.txt"; then
      echo "deps_changed=true" >> $GITHUB_OUTPUT
    fi

- name: Build deps layer
  if: steps.changes.outputs.deps_changed == 'true'
  run: nix build .#dependenciesLayer
```

### 7. Development Workflow
**Problem**: Hard to iterate locally on Nix builds
**Better Solutions**:

```bash
# Add to Makefile or flake apps
develop-layer:
  # Build just one layer and enter shell
  nix develop .#dependenciesLayer

test-layer:
  # Build layer and run tests
  nix build .#dependenciesLayer
  docker load < result
  docker run --rm comfyui-deps python3 -c "import torch; print(torch.version.cuda)"

debug-build:
  # Keep failed build for inspection
  nix build .#comfyui --keep-failed
  # Then inspect /tmp/nix-build-*
```

**Add to flake.nix**:
```nix
devShells = {
  # Shell for each layer
  dependenciesLayer = pkgs.mkShell {
    buildInputs = pythonEnv.buildInputs;
    shellHook = ''
      echo "Deps layer dev environment"
      pip list
    '';
  };

  # Test environment
  test = pkgs.mkShell {
    buildInputs = [ pkgs.docker ];
    shellHook = ''
      echo "Load and test images with: make test-layer"
    '';
  };
};
```

### 8. Flake Structure
**Problem**: Single monolithic flake.nix (340 lines)
**Better Solution**:

```
cu130-megapak-pt210-py314-nix/
├── flake.nix              # Main entry point
├── flake.lock             # Locked dependencies
├── modules/
│   ├── base-layer.nix     # Base + CUDA
│   ├── python-layer.nix   # Python 3.14
│   ├── pytorch-layer.nix  # PyTorch + ML
│   ├── deps-layer.nix     # Dependencies
│   ├── perf-layer.nix     # Performance wheels
│   └── app-layer.nix      # ComfyUI
├── packages/
│   ├── flash-attn.nix     # Custom derivation
│   ├── sageattention.nix
│   └── nunchaku.nix
└── scripts/               # Converted to derivations
    ├── builder.nix
    └── runner.nix
```

**Benefits**:
- Easier to understand and maintain
- Reusable modules
- Better organization

### 9. Version Pinning
**Problem**: Some versions are hardcoded, others pulled from latest
**Better Solution**:

```nix
# versions.nix
{
  python = "3.14.0";
  pytorch = "2.10.0";
  cuda = "13.0";
  comfyui = "0.12.3";
  manager = "4.1b1";
  frontend = "1.39.8";

  wheels = {
    flashAttn = {
      version = "2.8.2";
      hash = "sha256-xxx";  # Pin exact wheel hash
      url = "https://github.com/retif/pytorch-wheels-builder/releases/download/flash-attn-v2.8.2-py314-torch2.10.0-cu130/flash_attn-2.8.2-cp314-cp314-linux_x86_64.whl";
    };
    # ...
  };
}

# Then import in flake.nix
versions = import ./versions.nix;
```

**Benefits**:
- Single source of truth for versions
- Easy to update all versions at once
- Clear version matrix

### 10. Testing Strategy
**Problem**: Only runs quick-test in CI
**Better Solution**:

```nix
# Add to flake.nix
checks = {
  # Unit tests for layers
  base-layer-test = pkgs.runCommand "test-base" {} ''
    ${baseLayer}/bin/nvcc --version | grep "13.0"
    touch $out
  '';

  pytorch-test = pkgs.runCommand "test-pytorch" {} ''
    ${pythonEnv}/bin/python -c "import torch; assert torch.cuda.is_available()"
    touch $out
  '';

  # Integration test
  comfyui-test = pkgs.runCommand "test-comfyui" {} ''
    # Load image and run full test suite
    ${pkgs.docker}/bin/docker load < ${finalImage}
    ${pkgs.docker}/bin/docker run --rm comfyui-boot:test python -m pytest /tests/
    touch $out
  '';
};

# Run with: nix flake check
```

## Recommended Improvements Priority

### High Priority (Do First)
1. **Set up Cachix** - Saves 40-60 min per build
2. **Split base layers into separate workflow** - Base/Python/PyTorch rarely change
3. **Add layer-level caching** - Only rebuild changed layers

### Medium Priority (Nice to Have)
4. **Convert critical packages to pure Nix** - Better reproducibility
5. **Modularize flake.nix** - Easier maintenance
6. **Add comprehensive testing** - Catch issues earlier

### Low Priority (Future)
7. **Multi-arch builds** - Add ARM64 support
8. **Local development workflow** - Better DX for contributors
9. **Automated version updates** - Dependabot for Nix

## Specific Action Items

### 1. Enable Cachix (15 min)
```bash
# On cachix.org: Create "comfyui-docker" cache
# On GitHub: Add CACHIX_AUTH_TOKEN secret
# Update workflow: Uncomment Cachix step
```

### 2. Create Base Layer Workflow (30 min)
```yaml
# .github/workflows/build-base-layers.yml
name: Build Base Layers
on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly
  workflow_dispatch:

jobs:
  build-base:
    # Build base, python, pytorch layers
    # Push to Cachix
```

### 3. Pure Nix PyTorch (2-3 hours)
```nix
# Create pytorch-cuda130.nix
# Test with: nix build .#pytorch-cuda130
# Replace pip install in layer
```

## Conclusion

The current design works but has room for optimization:

**Strengths**:
- ✅ Declarative layer structure
- ✅ Reproducible builds (mostly)
- ✅ Good documentation
- ✅ CI/CD integration

**Weaknesses**:
- ❌ No binary caching (biggest issue)
- ❌ Hybrid Nix/pip approach
- ❌ Long build times
- ❌ Manual layer management

**Biggest Impact Improvements**:
1. Cachix → 80% faster rebuilds
2. Base layer separation → 50% fewer rebuilds
3. Pure Nix packages → 100% reproducible

The workflow is production-ready as-is, but these improvements would make it production-excellent.
