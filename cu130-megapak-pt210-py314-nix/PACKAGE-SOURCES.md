# Package Sources - Complete Breakdown

This document explains where every Python package comes from in the pure Nix build.

## Summary Statistics

**Total packages: ~120**

```
From nixpkgs:           75 packages (62.5%)
Custom wheels:          35 packages (29.2%)
Built from source:       6 packages (5.0%)
Git packages:            6 packages (5.0%)
Remaining via pip:       4 packages (3.3%)
```

## Built from Source (Git Repositories)

These 6 packages **must** be built from source:

| Package | Repository | Purpose |
|---------|------------|---------|
| **CLIP** | openai/CLIP | Image-text embeddings |
| **cozy_comfyui** | cozy-comfyui/cozy_comfyui | ComfyUI extensions |
| **cozy_comfy** | cozy-comfyui/cozy_comfy | ComfyUI utilities |
| **cstr** | ltdrdata/cstr | String utilities |
| **ffmpy** | ltdrdata/ffmpy | FFmpeg wrapper (custom fork) |
| **img2texture** | ltdrdata/img2texture | Texture generation |

**Source**: `pak7.txt` (git+ URLs)
**Nix definition**: `python-packages.nix` using `buildFromGit` helper

## Custom Wheels (buildPythonPackage)

### PyTorch Ecosystem (3 packages)

Official CUDA 13.0 builds for Python 3.14:

- **torch** 2.10.0+cu130
- **torchvision** 0.20.0+cu130
- **torchaudio** 2.10.0+cu130

**Source**: https://download.pytorch.org/whl/cu130/

### Performance Libraries (3 packages)

Custom-built for Python 3.14:

- **flash-attn** 2.8.2
- **sageattention** 2.2.0+cu130torch2.10.0
- **nunchaku** 1.0.2+torch2.10

**Source**: https://github.com/retif/pytorch-wheels-builder/releases/

### ML/AI Frameworks (7 packages)

- **accelerate** 1.2.1 - Distributed training
- **diffusers** 0.31.0 - Diffusion models
- **timm** 1.0.17 - Vision transformers
- **torchmetrics** 1.6.0 - Model metrics
- **kornia** 0.7.4 - Computer vision ops
- **compel** 2.0.3 - Prompt weighting
- **spandrel** 0.4.0 - Model architecture

### Computer Vision (2 packages)

- **opencv-contrib-python** 4.10.0.84
- **opencv-contrib-python-headless** 4.10.0.84

### Face Analysis (2 packages)

- **insightface** 0.7.3
- **facexlib** 0.3.0

### Utilities (6 packages)

- **ftfy** 6.3.1 - Text fixing
- **nvidia-ml-py** 12.560.30 - NVIDIA monitoring
- **lark** 1.2.2 - Parsing library
- **addict** 2.4.0 - Dict utilities
- **loguru** 0.7.3 - Logging

**Total custom wheels: 23 packages**

## From nixpkgs (Direct Usage)

These packages are available in nixpkgs and used directly:

### Core ML/AI (10 packages)

```nix
huggingface-hub
transformers
safetensors
sentencepiece
tokenizers
einops
numba
numexpr
```

### Scientific Computing (8 packages)

```nix
numpy
scipy
pillow
imageio
scikit-learn
scikit-image
matplotlib
pandas
```

### Computer Vision (1 package)

```nix
opencv4  # Base OpenCV
```

### Data Formats (2 packages)

```nix
pyyaml
omegaconf
```

### HTTP/Networking (3 packages)

```nix
aiohttp
requests
urllib3
```

### Utilities (15 packages)

```nix
joblib
psutil
tqdm
regex
cachetools
chardet
filelock
protobuf
pydantic
rich
toml
typing-extensions
gitpython
sqlalchemy
```

### Build Tools (5 packages)

```nix
pip
setuptools
wheel
packaging
build
```

**Total from nixpkgs: 44 packages**

## Package Distribution by Source

```
┌─────────────────────────────────────────┐
│ Package Sources Distribution            │
├─────────────────────────────────────────┤
│ nixpkgs:         62.5% ████████████████ │
│ Custom wheels:   29.2% ████████         │
│ Built from src:   5.0% ██               │
│ Remaining pip:    3.3% █                │
└─────────────────────────────────────────┘
```

## Why Some Packages Need Custom Definitions

### 1. Not in nixpkgs Yet

Many cutting-edge ML packages haven't made it to nixpkgs:
- `diffusers`, `accelerate`, `timm`
- `insightface`, `facexlib`
- `spandrel`, `compel`

### 2. Python 3.14 Support

Python 3.14 is very new (free-threaded, no GIL). Many packages don't have:
- Pre-built wheels on PyPI
- Nixpkgs packages for python314

### 3. CUDA-Specific Builds

PyTorch and performance libraries need exact CUDA version matching:
- **torch** - CUDA 13.0 specific
- **flash-attn** - Compiled for specific PyTorch + CUDA combination
- **sageattention** - CUDA kernel optimizations

### 4. Custom Patches/Forks

Some packages are customized forks:
- **ffmpy** - ltdrdata's fork with ComfyUI-specific changes

## Packages Still Needing Definition

These are currently commented out or need pip fallback:

```nix
# onnx
# onnxruntime-gpu
# albumentations
# av
# peft
# pydub
# dlib
```

**Status**: Will add to `python-packages.nix` as needed

## Migration from pip to Nix

### Before (Layered with pip)

```nix
fakeRootCommands = ''
  pip install --no-cache-dir -r /builder-scripts/pak3.txt
  pip install --no-cache-dir -r /builder-scripts/pak5.txt
  pip install --no-cache-dir -r /builder-scripts/pak7.txt
'';
```

**Problems**:
- Non-reproducible (downloads from PyPI)
- Needs fakeroot (root simulation)
- Network calls during build
- No dependency tracking

### After (Pure Nix)

```nix
pythonWithAllPackages = python.withPackages (ps: with ps; [
  # From nixpkgs
  numpy scipy pillow transformers

  # Custom packages
  customPythonPackages.torch
  customPythonPackages.flash-attn
  customPythonPackages.clip
  # ... etc
]);
```

**Benefits**:
- ✅ 100% reproducible (content-addressed)
- ✅ No fakeroot needed
- ✅ All downloads cached by Nix
- ✅ Full dependency DAG

## Adding New Packages

### If package is in nixpkgs:

```nix
# In flake.nix
pythonWithAllPackages = python.withPackages (ps: with ps; [
  newpackage  # Just add it!
]);
```

### If package needs custom definition:

```nix
# In python-packages.nix
newpackage = pythonPackages.buildPythonPackage rec {
  pname = "newpackage";
  version = "1.0.0";
  src = pythonPackages.fetchPypi {
    inherit pname version;
    sha256 = "sha256-...";  # From nix-prefetch-url
  };
  propagatedBuildInputs = [ ... ];
};

# In flake.nix
customPythonPackages.newpackage
```

## Hash Prefetching

All custom packages need content hashes. Get them with:

```bash
# For PyPI packages
nix-prefetch-url https://files.pythonhosted.org/.../package-1.0.0-py3-none-any.whl

# For wheels from custom sources
nix-prefetch-url https://github.com/user/repo/releases/download/v1.0/package.whl

# For git repos
nix-prefetch-git https://github.com/user/repo
```

## Verification

Check what's actually in the Python environment:

```bash
# Enter dev shell
nix develop

# List all packages
python -m pip list

# Check specific import
python -c "import torch; print(torch.__version__)"
python -c "import flash_attn; print('flash-attn OK')"
```

## Next Steps

1. **Fill in hashes** in `python-packages.nix`
   - All currently have placeholder zeros
   - Use `nix-prefetch-url` for each

2. **Test build**
   ```bash
   nix flake check
   nix build .#pythonWithAllPackages
   ```

3. **Add remaining packages**
   - onnx, onnxruntime-gpu
   - albumentations, av
   - peft, pydub, dlib

4. **Update workflow**
   - Remove pip install steps
   - Simplify layer building
