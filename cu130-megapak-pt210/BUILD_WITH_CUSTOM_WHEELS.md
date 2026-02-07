# Building with Custom Wheels from pytorch-wheels-builder

This image uses custom-built wheels for performance optimization libraries that are not yet available for Python 3.13 + CUDA 13.0.

## Custom Wheels Included

The following packages are built from the `pytorch-wheels-builder` repository:

1. **Flash Attention** (Run ID: 21769440938)
   - Build: https://github.com/oleks/pytorch-wheels-builder/actions/runs/21769440938
   - Date: 2026-02-06T23:22:13Z

2. **SageAttention** (Run ID: 21769119652)
   - Build: https://github.com/oleks/pytorch-wheels-builder/actions/runs/21769119652
   - Date: 2026-02-06T23:07:33Z

3. **Nunchaku** (Run ID: 21769116283)
   - Build: https://github.com/oleks/pytorch-wheels-builder/actions/runs/21769116283
   - Date: 2026-02-06T23:07:24Z

## Build Requirements

To build this Docker image, you need:

1. **GitHub CLI (`gh`)** - Used to download artifacts from GitHub Actions
2. **GitHub Token** with read access to the `pytorch-wheels-builder` repository

## Build Command

The build process downloads wheel artifacts directly from GitHub Actions during the Docker build using the gh CLI.

```bash
# Build with GitHub token as a build secret
docker build \
  --secret id=GITHUB_TOKEN,env=GITHUB_TOKEN \
  -t yanwk/comfyui-boot:cu130-megapak \
  -f cu130-megapak-pt210/Dockerfile \
  .
```

Make sure `GITHUB_TOKEN` is set in your environment with read access to the repository:

```bash
# Use gh auth token (recommended if gh is already authenticated)
export GITHUB_TOKEN=$(gh auth token)

# OR set manually
export GITHUB_TOKEN="your_github_token_here"
```

The Dockerfile will:
1. Install gh CLI
2. Authenticate using the provided token
3. Download each wheel artifact from the specified workflow runs
4. Install the wheels using pip
5. Clean up temporary files

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
