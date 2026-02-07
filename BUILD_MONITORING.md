# Build Monitoring Guide

## Quick Start

Monitor the latest build:
```bash
./monitor-build.sh --interval 10
```

## Features

- ✅ Real-time build status tracking
- ✅ Automatic retry on failure (configurable)
- ✅ Visual progress with step-by-step updates
- ✅ Elapsed time tracking
- ✅ Failed step identification
- ✅ Direct links to GitHub Actions

## Usage Examples

### Basic Monitoring
Monitor latest build, check every 30 seconds:
```bash
./monitor-build.sh --interval 30
```

### Auto-Retry on Failure
Automatically retry up to 3 times on failure:
```bash
./monitor-build.sh --retry --interval 30
```

### Monitor Specific Run
Monitor a specific run ID:
```bash
./monitor-build.sh --run-id 21762548498
```

### Watch Mode
Continuously monitor latest run:
```bash
./monitor-build.sh --watch --retry
```

## Configuration

### Environment Variables
- `MAX_RETRIES`: Maximum retry attempts (default: 3)
- `CHECK_INTERVAL`: Check interval in seconds (default: 30)

### Command Line Options
- `--run-id ID`: Monitor specific run ID
- `--watch`: Watch latest run continuously
- `--retry`: Enable automatic retry on failure
- `--interval SECS`: Check interval in seconds
- `-h, --help`: Show help

## Output

The monitor displays:
- Run ID and title
- Elapsed time
- Current status (queued/in progress/completed)
- Step-by-step progress with ✓/X/*/- indicators
- GitHub Actions URL
- On completion: docker pull command or failed steps

## Integration with CI/CD

### Trigger and Monitor
```bash
# Trigger new build
gh workflow run build-cu130-megapak-pt210.yml --repo retif/ComfyUI-Docker

# Wait a moment for workflow to register
sleep 5

# Start monitoring with retry
./monitor-build.sh --watch --retry --interval 20
```

### Automated Deployment
```bash
#!/bin/bash
# deploy-comfyui.sh

# Trigger build
gh workflow run build-cu130-megapak-pt210.yml --repo retif/ComfyUI-Docker

# Monitor with retry
if ./monitor-build.sh --retry --interval 30; then
    echo "✅ Build successful, updating deployment..."
    kubectl set image deployment/comfyui \
        comfyui=ghcr.io/retif/comfyui-boot:cu130-megapak-pt210
else
    echo "❌ Build failed after retries"
    exit 1
fi
```

## Troubleshooting

### "No runs found"
- Verify workflow name: `build-cu130-megapak-pt210.yml`
- Check repository: `retif/ComfyUI-Docker`
- Ensure you have permissions: `gh auth status`

### Authentication Issues
```bash
# Re-authenticate with GitHub CLI
gh auth login

# Verify access to repository
gh repo view retif/ComfyUI-Docker
```

### Script Permissions
```bash
# Make script executable
chmod +x monitor-build.sh
```

## Exit Codes

- `0`: Build completed successfully
- `1`: Build failed (or cancelled/unknown status)

## Dependencies

- `gh` (GitHub CLI) - https://cli.github.com/
- `jq` - JSON processor
- `bash` 4.0+

Install dependencies:
```bash
# Ubuntu/Debian
sudo apt-get install gh jq

# macOS
brew install gh jq
```
