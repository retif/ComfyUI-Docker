# ComfyUI Docker - NixOS Flake Edition

Declarative, layered Docker image for ComfyUI using Nix flakes.

## Architecture

### Layered Structure

The image is built as a stack of immutable layers for efficient caching:

```
Layer 6: Final Runtime     ← Entrypoint, config
Layer 5: ComfyUI App       ← ComfyUI + 47 custom nodes
Layer 4: Performance       ← Flash Attention, SageAttention, Nunchaku
Layer 3: Dependencies      ← Python packages from pak*.txt
Layer 2: PyTorch           ← PyTorch + torchvision + torchaudio
Layer 1: Python 3.14       ← Python 3.14 (free-threaded, no GIL)
Layer 0: Base + CUDA       ← System utils + CUDA 13.0 + cuDNN
```

### Benefits

- **Declarative**: All dependencies explicitly declared in flake.nix
- **Reproducible**: Lock file ensures exact versions
- **Efficient**: Layers cached independently, only rebuild what changes
- **Composable**: Can build/test individual layers
- **Pure**: No hidden dependencies or side effects

## Prerequisites

```bash
# Enable Nix flakes
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

## Quick Start

### Build Complete Image

```bash
cd cu130-megapak-pt210-py314-nix

# Build and load into Docker
nix run .#build

# Or build directly
nix build .#comfyui
./result | docker load
```

### Build Individual Layers

```bash
# Build just the base layer
nix build .#baseLayer
docker load < result

# Build Python layer
nix build .#pythonLayer
docker load < result

# Build up to PyTorch
nix build .#pytorchLayer
docker load < result
```

### Run

```bash
# Using nix app
nix run .#run

# Or manually
docker run --rm -it \
  --gpus all \
  -p 8188:8188 \
  -v "$(pwd)/output:/root/output" \
  comfyui-boot:cu130-megapak-py314-nix
```

### Development Shell

```bash
# Enter dev environment with Python 3.14 + CUDA
nix develop

# Now you have access to:
# - python3 (3.14, free-threaded)
# - CUDA toolkit
# - All build dependencies
```

## Layer Details

### Layer 0: Base + CUDA
- **Purpose**: Foundation system + CUDA environment
- **Contents**: coreutils, bash, CUDA 13.0, cuDNN, build tools
- **Size**: ~4GB
- **Rebuild frequency**: Rarely (only on CUDA updates)

### Layer 1: Python 3.14
- **Purpose**: Python runtime
- **Contents**: Python 3.14 (free-threaded), pip, setuptools, wheel
- **Size**: ~200MB
- **Rebuild frequency**: On Python version changes

### Layer 2: PyTorch
- **Purpose**: Deep learning framework
- **Contents**: PyTorch 2.10 + torchvision + torchaudio for CUDA 13.0
- **Size**: ~2GB
- **Rebuild frequency**: On PyTorch updates

### Layer 3: Dependencies
- **Purpose**: ComfyUI Python dependencies
- **Contents**: ~120 Python packages from pak3/5/7.txt
- **Size**: ~1GB
- **Rebuild frequency**: When dependencies change

### Layer 4: Performance
- **Purpose**: Optimized attention mechanisms
- **Contents**: Flash Attention, SageAttention, Nunchaku
- **Size**: ~500MB
- **Rebuild frequency**: When performance libs update

### Layer 5: ComfyUI Application
- **Purpose**: The actual ComfyUI application
- **Contents**: ComfyUI core, Manager, Frontend, 47 custom nodes
- **Size**: ~500MB
- **Rebuild frequency**: Daily/on demand

### Layer 6: Runtime
- **Purpose**: Final configuration
- **Contents**: Entrypoint scripts, environment config
- **Size**: ~1MB
- **Rebuild frequency**: On config changes

## Updating

### Update Python packages

```nix
# In flake.nix, modify the pythonLayer or dependenciesLayer
# Then rebuild
nix flake update
nix build .#comfyui
```

### Update CUDA version

```nix
# In flake.nix, change:
cudaPackages = pkgs.cudaPackages_13_0;
# Then rebuild
```

### Update individual layer

Each layer is independently buildable. Change the layer definition in flake.nix,
then rebuild just that layer and everything above it.

## Comparison with Traditional Dockerfile

| Aspect | Dockerfile | Nix Flake |
|--------|-----------|-----------|
| Declarative | Imperative steps | Pure declarations |
| Reproducible | Best effort | Guaranteed |
| Caching | Layer-based | Content-addressed |
| Composability | Limited | Excellent |
| Dev environment | Separate | Same definition |

## Advanced Usage

### Customize Layers

Edit `flake.nix` to add/remove packages from any layer:

```nix
# Add a package to base layer
baseLayer = pkgs.dockerTools.buildImage {
  copyToRoot = pkgs.buildEnv {
    paths = with pkgs; [
      # ... existing packages ...
      myNewPackage  # Add here
    ];
  };
};
```

### Use as Base for Custom Image

```nix
# In your own flake.nix
{
  inputs.comfyui.url = "github:retif/ComfyUI-Docker?dir=cu130-megapak-pt210-py314-nix";

  outputs = { self, comfyui }: {
    packages.x86_64-linux.default = pkgs.dockerTools.buildImage {
      fromImage = comfyui.packages.x86_64-linux.comfyuiLayer;
      # Add your customizations
    };
  };
}
```

### Pin Specific Versions

```bash
# Update to latest packages
nix flake update

# Pin specific nixpkgs revision
nix flake lock --override-input nixpkgs github:NixOS/nixpkgs/<commit-hash>
```

## Troubleshooting

### Build fails with "experimental feature"
Enable flakes in nix.conf (see Prerequisites)

### CUDA not found in container
Check LD_LIBRARY_PATH includes CUDA libraries

### Layer too large
Reduce maxLayers in streamLayeredImage config

## Next Steps

1. Add builder-scripts and runner-scripts to appropriate layers
2. Integrate preload-cache.sh for ComfyUI setup
3. Add pak*.txt files for dependency installation
4. Create GitHub Actions workflow for automated builds
5. Publish to GitHub Container Registry

## Resources

- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [dockerTools](https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-dockerTools)
- [Python 3.14 Free Threading](https://peps.python.org/pep-0703/)
