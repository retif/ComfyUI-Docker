# Building with Custom Wheels from pytorch-wheels-builder

This image uses custom-built wheels for performance optimization libraries that are not yet available for Python 3.14 + CUDA 13.0.

## Custom Wheels Included

The following packages are installed from GitHub releases in the `pytorch-wheels-builder` repository:

1. **Flash Attention v2.8.2** for Python 3.14 + PyTorch 2.10.0 + CUDA 13.0
   - Release: https://github.com/oleks/pytorch-wheels-builder/releases/tag/flash-attn-v2.8.2-py314-torch2.10.0-cu130
   - Wheel: `flash_attn-2.8.2-cp314-cp314-linux_x86_64.whl`

2. **SageAttention v2.2.0** for Python 3.14 + PyTorch 2.10.0 + CUDA 13.0
   - Release: https://github.com/oleks/pytorch-wheels-builder/releases/tag/sageattention-v2.2.0-py314-torch2.10.0-cu130
   - Wheel: `sageattention-2.2.0+cu130torch2.10.0-cp314-cp314-linux_x86_64.whl`

3. **Nunchaku v1.0.2** for Python 3.14 + PyTorch 2.10.0 + CUDA 13.0
   - Release: https://github.com/oleks/pytorch-wheels-builder/releases/tag/nunchaku-v1.0.2-py314-torch2.10.0-cu130
   - Wheel: `nunchaku-1.0.2+torch2.10-cp314-cp314-linux_x86_64.whl`

## Build Command

The build process installs wheels directly from public GitHub releases:

```bash
docker build \
  -t yanwk/comfyui-boot:cu130-megapak-py314 \
  -f cu130-megapak-pt210-py314/Dockerfile \
  .
```

**No GitHub token required** - all wheels are installed from public release URLs.

## Key Differences from Python 3.13 Version

- **Python 3.14** (free-threaded, no GIL) instead of Python 3.13
- Wheels are installed directly from **public GitHub releases** instead of workflow artifacts
- No authentication or secrets required during build
- Simplified build process with direct `pip install` URLs

## Updating Wheel Versions

When new releases are available in `pytorch-wheels-builder`:

1. Check for new releases:
   ```bash
   cd /path/to/pytorch-wheels-builder
   gh release list --limit 20
   ```

2. Update the Dockerfile URLs to point to the new release tags and wheel filenames

3. Update this file with the new version numbers and release links
