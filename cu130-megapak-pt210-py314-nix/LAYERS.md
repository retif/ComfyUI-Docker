# Layered Build Architecture

This Nix flake uses a modular, layered architecture that mirrors the classic Dockerfile's 12-step installation process. Each layer is a separate flake that builds on the previous one.

## Layer Structure

### Layer 01: Base + CUDA
**Path:** `layers/01-base-cuda/`
- System utilities (bash, coreutils, findutils, etc.)
- CUDA Toolkit 13.0 + cuDNN
- Build tools (gcc, cmake, ninja, git)
- Media libraries (ffmpeg, x264, x265)

### Layer 02: Python + Tools
**Path:** `layers/02-python-tools/`
- Python 3.14 (free-threaded)
- Basic build tools (pip, setuptools, wheel, packaging)
- Utilities (aria2, vim, fish)

### Layer 03: GCC 15
**Path:** `layers/03-gcc15/`
- GCC 15 compiler
- C++ compiler (g++)
- Configured as default compiler via environment variables

### Layer 04: PyTorch
**Path:** `layers/04-pytorch/`
- PyTorch 2.10.0 + CUDA 13.0
- torchvision
- torchaudio

### Layer 05: pak3 - Core ML Essentials
**Path:** `layers/05-pak3/`
- Core ML frameworks (accelerate, diffusers, transformers)
- Scientific computing (numpy, scipy, pandas, scikit-learn)
- Computer vision (opencv, kornia, timm)
- ML utilities (torchmetrics, compel, lark)
- Data formats (pyyaml, omegaconf, onnx)
- System utilities (joblib, psutil, tqdm, nvidia-ml-py)

**Total:** ~42 packages from pak3.txt

### Layer 06: CuPy
**Path:** `layers/06-cupy/`
- cupy-cuda13x 14.0.0rc1 (Python 3.14 support)

### Layer 07: pak5 - Extended Libraries
**Path:** `layers/07-pak5/`
- HTTP/networking (aiohttp, requests)
- Data processing (albumentations, av, einops, numba)
- ML/AI tools (peft, safetensors, sentencepiece, tokenizers)
- Utilities (loguru, protobuf, pydantic, rich, SQLAlchemy)
- Geometry (shapely, trimesh)
- Additional (webcolors, qrcode, yarl, tomli, pycocotools)

**Total:** ~72 packages from pak5.txt

### Layer 08: pak7 - Face Analysis + Git Packages
**Path:** `layers/08-pak7/`
- Face analysis (dlib, facexlib, insightface)
- Git packages (CLIP, cozy-comfyui, cozy-comfy, cstr, ffmpy, img2texture)

**Total:** ~9 packages from pak7.txt

### Layer 09: SAM-2 & SAM-3
**Not implemented yet** - Requires special git builds with custom flags

### Layer 10: Performance Libraries
**Path:** `layers/10-performance/`
- flash-attn 2.8.2 (Python 3.14 + PyTorch 2.10.0 + CUDA 13.0)
- sageattention 2.2.0
- nunchaku 1.0.2

### Layer 11: Application Scripts
**Path:** `layers/11-app/`
- Builder scripts (for setup)
- Runner scripts (entrypoint, etc.)
- ComfyUI bundle directory structure

### Layer 12: ComfyUI Bundle (Final)
**Path:** `layers/12-comfyui/`
- Final image configuration
- Entrypoint setup
- Volume and port configuration

## Building

### Build all layers incrementally:
```bash
nix run .#build-all-layers
```

### Build final image directly:
```bash
nix run .#build-final
```

### Build a specific layer:
```bash
nix build .#layer01-base-cuda
nix build .#layer04-pytorch
nix build .#layer08-pak7
nix build .#layer12-comfyui
```

### Load into Docker:
```bash
# For regular images
nix build .#layer01-base-cuda
docker load < result

# For streamed images (final layer)
nix build .#layer12-comfyui
./result | docker load
```

## Layer Dependencies

Each layer depends on the previous one:
```
layer01 (Base+CUDA)
  └─> layer02 (Python+Tools)
        └─> layer03 (GCC 15)
              └─> layer04 (PyTorch)
              └─> layer05 (pak3)
                    └─> layer06 (CuPy)
                          └─> layer07 (pak5)
                                └─> layer08 (pak7)
                                      └─> layer10 (Performance)
                                            └─> layer11 (App Scripts)
                                                  └─> layer12 (ComfyUI Final)
```

## Caching Strategy

- **Nix Store:** Nix automatically caches built derivations
- **Docker Registry:** Each layer can be pushed to GHCR separately
- **Incremental Builds:** Only changed layers need to be rebuilt

## Package Organization

Packages are organized in separate modules:
- `pak3.nix` - Core ML essentials (11 custom packages)
- `pak5.nix` - Extended libraries (3 custom packages)
- `pak7.nix` - Face analysis + git packages (8 packages)
- `custom-packages.nix` - PyTorch wheels + performance libs (7 packages)
- `package-lists.nix` - Centralized package lists for all layers

## Total Package Count

- **Build tools:** 5 packages
- **PyTorch:** 3 packages
- **pak3:** ~42 packages
- **CuPy:** 1 package
- **pak5:** ~72 packages
- **pak7:** ~9 packages
- **Performance:** 3 packages

**Total:** ~135 Python packages from Nix (no pip installs!)

## Comparison with Classic Dockerfile

| Layer | Dockerfile | Nix Flake | Caching |
|-------|-----------|-----------|---------|
| 01 | Base + CUDA | ✅ | GHCR |
| 02 | Python 3.14 | ✅ | GHCR |
| 03 | GCC 15 | ✅ | GHCR |
| 04 | PyTorch | ✅ | GHCR |
| 05 | pak3.txt | ✅ | GHCR |
| 06 | cupy-cuda13x | ✅ | GHCR |
| 07 | pak5.txt | ✅ | GHCR |
| 08 | pak7.txt | ✅ | GHCR |
| 09 | SAM-2/3 | 🚧 TODO | - |
| 10 | Performance | ✅ | GHCR |
| 11 | App scripts | ✅ | GHCR |
| 12 | ComfyUI | ✅ | GHCR |

## Benefits

1. **Modularity:** Each layer is self-contained and reusable
2. **Caching:** GHCR can cache each layer independently
3. **Debugging:** Easy to test specific layers
4. **Reproducibility:** Fully declarative, no hidden dependencies
5. **Efficiency:** Only rebuild changed layers
