# Building with Custom Wheels from pytorch-wheels-builder

This image uses custom-built wheels for performance optimization libraries that are not yet available for Python 3.13 + CUDA 13.0.

## Custom Wheels Included

The following packages are built from the `pytorch-wheels-builder` repository:

1. **SageAttention v2.2.0** for Python 3.13 + PyTorch 2.10.0 + CUDA 13.0
   - Source: GitHub Release
   - Release: https://github.com/oleks/pytorch-wheels-builder/releases/tag/sageattention-v2.2.0-py313-torch2.10.0-cu130
   - Wheel: `sageattention-2.2.0+cu130torch2.10.0-cp313-cp313-linux_x86_64.whl`

2. **Nunchaku v1.0.2** for Python 3.13 + PyTorch 2.10.0 + CUDA 13.0
   - Source: GitHub Release
   - Release: https://github.com/oleks/pytorch-wheels-builder/releases/tag/nunchaku-v1.0.2-py313-torch2.10.0-cu130
   - Wheel: `nunchaku-1.0.2+torch2.10-cp313-cp313-linux_x86_64.whl`

3. **Flash Attention** (no py313 release yet)
   - Source: GitHub Actions Artifact (Run ID: 21769440938)
   - Build: https://github.com/oleks/pytorch-wheels-builder/actions/runs/21769440938
   - Date: 2026-02-06T23:22:13Z

## Build Requirements

To build this Docker image, you need:

1. **GitHub CLI (`gh`)** - Used to download artifacts from GitHub Actions
2. **GitHub Token** with read access to the `pytorch-wheels-builder` repository

## Build Command

The build process uses a hybrid approach:
- **SageAttention & Nunchaku**: Direct pip install from public GitHub releases (no auth needed)
- **Flash Attention**: Downloaded from GitHub Actions artifact (requires GitHub token)

```bash
# Build with GitHub token as a build secret (needed for Flash Attention)
docker build \
  --secret id=GITHUB_TOKEN,env=GITHUB_TOKEN \
  -t yanwk/comfyui-boot:cu130-megapak \
  -f cu130-megapak-pt210/Dockerfile \
  .
```

Make sure `GITHUB_TOKEN` is set in your environment:

```bash
# Use gh auth token (recommended if gh is already authenticated)
export GITHUB_TOKEN=$(gh auth token)

# OR set manually
export GITHUB_TOKEN="your_github_token_here"
```

The Dockerfile will:
1. Install SageAttention and Nunchaku directly from public release URLs
2. Install gh CLI and authenticate for Flash Attention artifact
3. Download Flash Attention artifact and install
4. Clean up temporary files

## Updating Wheel Versions

When new builds are available in `pytorch-wheels-builder`:

1. Find the successful run ID:
   ```bash
   cd /path/to/pytorch-wheels-builder
   gh run list --limit 20 --json conclusion,name,status,databaseId,createdAt \
     --jq '.[] | select(.conclusion == "success") | "\(.databaseId)\t\(.name)\t\(.createdAt)"'
   ```

2. Update `builder-scripts/download-custom-wheels.sh` with the new run IDs

3. Update this file with the new run IDs and dates
