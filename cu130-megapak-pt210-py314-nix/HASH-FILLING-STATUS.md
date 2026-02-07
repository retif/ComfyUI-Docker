# Hash Filling Status

## Current Status: ⏳ IN PROGRESS

**Script running**: `fill-hashes-improved.sh`
**Background task**: `b1833b8`
**Output**: `/tmp/claude-1000/-home-oleks-projects-ComfyUI-Docker/tasks/b1833b8.output`
**Hash file**: `/tmp/nix-hashes.txt`

## What's Happening

The script is prefetching content hashes for all custom Python packages:

### Phase 1: PyTorch Wheels (~10-15 minutes)

Large downloads (~2.5GB each):
- [ ] torch-2.10.0+cu130
- [ ] torchvision-0.20.0+cu130
- [ ] torchaudio-2.10.0+cu130

### Phase 2: Performance Wheels (~2-3 minutes)

Custom builds for Python 3.14:
- [x] flash-attn-2.8.2 ✅ (already got: `sha256-1vj0imc1jhgm5s3ai4ri1dzwhrlp5qgp4rm19sxlxs77blvd3gn4`)
- [ ] sageattention-2.2.0+cu130torch2.10.0
- [ ] nunchaku-1.0.2+torch2.10

### Phase 3: Git Repositories (~2-3 minutes)

Source builds:
- [ ] CLIP (openai)
- [ ] cozy_comfyui
- [ ] cozy_comfy
- [ ] cstr
- [ ] ffmpy
- [ ] img2texture

## Expected Timeline

```
Current time: Starting
+ 10-15 min: PyTorch downloads
+ 2-3 min:   Performance wheels
+ 2-3 min:   Git repos
─────────────────────────────
Total: ~15-20 minutes
```

## Checking Progress

```bash
# Live progress
tail -f /tmp/claude-1000/-home-oleks-projects-ComfyUI-Docker/tasks/b1833b8.output

# Or check periodically
tail -20 /tmp/claude-1000/-home-oleks-projects-ComfyUI-Docker/tasks/b1833b8.output

# Check hash file (updates as script progresses)
cat /tmp/nix-hashes.txt
```

## What Happens When Done

Script will create `/tmp/nix-hashes.txt` with all hashes:
```
torch:sha256-...
torchvision:sha256-...
torchaudio:sha256-...
flash-attn:sha256-...
sageattention:sha256-...
nunchaku:sha256-...
clip:sha256-...
cozy-comfyui:sha256-...
cozy-comfy:sha256-...
cstr:sha256-...
ffmpy:sha256-...
img2texture:sha256-...
```

## Next Steps After Completion

### 1. Update python-packages.nix

For each package in `/tmp/nix-hashes.txt`, update the hash:

```nix
# Before:
hash = "sha256-0000000000000000000000000000000000000000000000000000";

# After (using hash from file):
hash = "sha256-abc123xyz...";
```

### 2. Verify Remaining Placeholders

```bash
cd cu130-megapak-pt210-py314-nix

# Should be 0 after updating all hashes
grep -c 'sha256-0{52}' python-packages.nix
```

### 3. Test Build

```bash
# Check for errors
nix flake check

# Build Python environment
nix build .#pythonWithAllPackages

# If successful, build full image
nix run .#build-incremental
```

## Issues We Fixed

1. **PyTorch platform**: `linux_x86_64` → `manylinux_2_28_x86_64`
2. **URL encoding**: Added `name` parameter to decode `%2B` → `-`
3. **Hash prefetching**: Use `nix-prefetch-url --name` for wheels

## Manual Hash Update (If Script Fails)

If any package fails to prefetch, you can do it manually:

```bash
# For wheels
nix-prefetch-url --name "torch-2.10.0-cu130-cp314-cp314-manylinux_2_28_x86_64.whl" \
  "https://download.pytorch.org/whl/cu130/torch-2.10.0%2Bcu130-cp314-cp314-manylinux_2_28_x86_64.whl"

# For git repos
nix-prefetch-git https://github.com/openai/CLIP | jq -r '.sha256'
```

## Background Task Commands

```bash
# Check if task is still running
# (Returns "running" or "completed")
ps aux | grep b1833b8

# Stop task if needed
pkill -f fill-hashes-improved.sh

# Restart if needed
cd cu130-megapak-pt210-py314-nix
./fill-hashes-improved.sh
```

## Estimated Completion

Based on typical download speeds:

- Fast connection (100 Mbps): ~12-15 minutes
- Medium connection (50 Mbps): ~18-25 minutes
- Slow connection (10 Mbps): ~40-60 minutes

Most time is spent downloading PyTorch wheels (~7.5 GB total).
