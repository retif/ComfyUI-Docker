# ComfyUI Docker - Pure Nix Build

This is a **completely declarative** Nix-based build for ComfyUI Docker images.

## Key Innovation: No pip, No fakeRootCommands

**What's different from the previous layered approach:**

| Feature | Previous (Layered) | **New (Pure Nix)** |
|---------|--------------------|--------------------|
| **Package installation** | pip + fakeRootCommands | `python.withPackages` |
| **PyTorch** | Downloaded wheels + pip install | `buildPythonPackage` with wheels |
| **Custom wheels** | `fakeRootCommands` + pip | `buildPythonPackage` format="wheel" |
| **Git packages** | pip install git+https://... | `buildPythonPackage` with fetchFromGitHub |
| **Reproducibility** | Partial (pip from index) | **100% (all from Nix)** |
| **Root access needed** | Yes (fakeroot) | **No** |
| **Garbage collection** | Manual | **Automatic (Nix)** |
| **Development** | Docker only | **nix-shell support** |

## Architecture

```
flake.nix (main configuration)
├─ python-packages.nix (custom package definitions)
│  ├─ PyTorch wheels (buildPythonPackage format="wheel")
│  ├─ Performance wheels (flash-attn, sageattention, nunchaku)
│  ├─ Git packages (CLIP, SAM-2, SAM-3, etc.)
│  └─ PyPI packages not in nixpkgs
│
└─ pythonWithAllPackages (combines everything)
   ├─ Packages from nixpkgs (~70 packages)
   └─ Custom packages from python-packages.nix (~50 packages)

Docker Layers:
├─ Layer 0: Base + CUDA
├─ Layer 1: Python + ALL packages (from Nix!)
├─ Layer 2: Application scripts
└─ Layer 3: ComfyUI setup
```

## Package Distribution

**Total: ~120 Python packages**

```
From nixpkgs:           ~70 packages (58%)
├─ numpy, scipy, pillow
├─ transformers, huggingface-hub
├─ opencv4, scikit-learn
└─ aiohttp, requests, pydantic

Custom (wheels):        ~40 packages (33%)
├─ torch, torchvision, torchaudio
├─ flash-attn, sageattention, nunchaku
└─ Packages not yet in nixpkgs

Built from source:      ~10 packages (8%)
├─ SAM-2, SAM-3
├─ CLIP (OpenAI)
└─ Git-based packages
```

## Build Process

### 1. Check Available Packages

```bash
cd cu130-megapak-pt210-py314-nix
./check-nixpkgs-packages.sh
```

This shows which packages are in nixpkgs vs need custom definitions.

### 2. Prefetch Hashes

For each wheel or git package, get the hash:

```bash
# For wheels
nix-prefetch-url https://download.pytorch.org/whl/cu130/torch-2.10.0%2Bcu130-cp314-cp314-linux_x86_64.whl

# For git repos
nix-prefetch-git https://github.com/openai/CLIP
```

Add the hashes to `python-packages.nix`.

### 3. Build Incrementally

```bash
nix run .#build-incremental
```

This builds:
1. **Layer 0** (~2-5 min) - Base system + CUDA
2. **Layer 1** (~20-40 min first time) - Python + ALL packages
3. **Layer 2** (~1 min) - Application scripts
4. **Layer 3** (~5-10 min) - ComfyUI setup

**Total first build**: ~30-60 minutes
**Rebuilds**: 2-10 minutes (only changed layers)

### 4. Verify

```bash
# Check Python environment
nix run .#check-packages

# Test PyTorch
docker run --rm comfyui-boot:cu130-megapak-py314-nix \
  python -c "import torch; print(f'PyTorch {torch.__version__} CUDA {torch.version.cuda}')"
```

## Adding New Packages

### From nixpkgs

If a package is in nixpkgs, just add it to `flake.nix`:

```nix
pythonWithAllPackages = python.withPackages (ps: with ps; [
  # ... existing packages ...
  newpackage  # Add here
]);
```

### From PyPI (wheel)

Add to `python-packages.nix`:

```nix
newpackage = buildWheel {
  pname = "newpackage";
  version = "1.0.0";
  src = fetchurl {
    url = "https://pypi.org/.../newpackage-1.0.0-py3-none-any.whl";
    hash = "sha256-...";  # From nix-prefetch-url
  };
  propagatedBuildInputs = [ torch pythonPackages.numpy ];  # Dependencies
};
```

Then reference in `flake.nix`:

```nix
customPythonPackages.newpackage
```

### From Git

Add to `python-packages.nix`:

```nix
newpackage = buildFromGit {
  pname = "newpackage";
  version = "unstable-2024-01-01";
  src = fetchFromGitHub {
    owner = "owner";
    repo = "newpackage";
    rev = "main";  # Or specific commit
    sha256 = "sha256-...";  # From nix-prefetch-git
  };
  propagatedBuildInputs = [ ... ];
};
```

## Benefits

### 1. Fully Reproducible

Every package is defined declaratively with content hashes:

```nix
torch = buildWheel {
  src = fetchurl {
    url = "https://...";
    hash = "sha256-abc123...";  # Exact content hash
  };
};
```

**Result**: Builds are byte-for-byte identical across machines and time.

### 2. No Root Access Needed

All packages installed as regular user in `/nix/store`:

```
/nix/store/abc123-python3.14-torch-2.10.0/
/nix/store/def456-python3.14-numpy-2.0.0/
```

**No fakeroot, no VM, no permission issues.**

### 3. Automatic Garbage Collection

Old package versions are automatically cleaned:

```bash
nix-collect-garbage --delete-older-than 30d
```

Frees up space from old builds without manual cleanup.

### 4. Development Shell

Use the same environment locally:

```bash
nix develop

# Now you have the exact same Python environment
python -c "import torch; print(torch.__version__)"
```

**No Docker needed for development!**

### 5. Dependency Tracking

Nix knows the full dependency graph:

```bash
nix why-depends .#comfyui nixpkgs#python314Packages.numpy
```

Shows exactly why numpy is included.

### 6. Better Caching

Nix cache is smarter than Docker layers:

```
Change torch version → Only torch rebuilds
Change Python → torch, torchvision rebuild (dependency)
Change CUDA → Everything with CUDA dependency rebuilds
```

**Docker layers**: Change one line → everything downstream rebuilds
**Nix**: Change one package → only that package + dependents rebuild

## Comparison with Previous Approaches

### vs Dockerfile (py314-source)

| Feature | Dockerfile | Pure Nix |
|---------|------------|----------|
| **Build time (first)** | 35-40 min | 30-60 min |
| **Build time (rebuild)** | 5-10 min | 2-10 min |
| **Reproducibility** | Good (pip cache) | **Perfect (content-addressed)** |
| **Development** | Docker only | **nix-shell + Docker** |
| **Package management** | pip | **Nix** |

### vs Layered Nix (previous)

| Feature | Layered (fakeRoot) | Pure Nix |
|---------|-------------------|----------|
| **pip usage** | Yes (in layers) | **No** |
| **fakeRootCommands** | Yes (7 layers) | **No** |
| **Root simulation** | fakeroot | **None needed** |
| **Reproducibility** | Partial | **100%** |
| **From nixpkgs** | ~50 packages | **~70 packages** |
| **Complexity** | Medium | Medium |

## Current Status

- ✅ Architecture defined
- ✅ flake.nix refactored
- ✅ python-packages.nix created
- ⏳ Hashes need to be filled in (use nix-prefetch-url)
- ⏳ Remaining packages need custom definitions
- ⏳ Testing needed

## Next Steps

1. **Fill in hashes** (`python-packages.nix`)
   ```bash
   nix-prefetch-url https://download.pytorch.org/whl/cu130/torch-2.10.0%2Bcu130-cp314-cp314-linux_x86_64.whl
   ```

2. **Expand python-packages.nix**
   - Add remaining packages from pak files
   - Use `check-nixpkgs-packages.sh` to see what's available

3. **Test build**
   ```bash
   nix flake check
   nix run .#build-incremental
   ```

4. **Update workflow**
   - Remove fakeRootCommands from GitHub Actions workflow
   - Simplify layer building (no pip installs)

## Troubleshooting

### "package X not found"

Check if it's in nixpkgs:
```bash
nix search nixpkgs python314Packages.X
```

If not, add to `python-packages.nix`.

### "hash mismatch"

Update hash in python-packages.nix:
```bash
nix-prefetch-url <url>
```

### "circular dependency"

Check `propagatedBuildInputs` - one package might depend on another that depends on it.

### "builder for X failed"

Check build logs:
```bash
nix build .#customPythonPackages.X --show-trace
```

## Resources

- [Nix Pills](https://nixos.org/guides/nix-pills/) - Learn Nix
- [nixpkgs Python docs](https://nixos.org/manual/nixpkgs/stable/#python) - Python packaging
- [dockerTools docs](https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-dockerTools) - Building Docker images

## Philosophy

**"Everything from Nix"** - This approach maximizes Nix's strengths:

- Reproducibility (content-addressed)
- Caching (derivation-level)
- Garbage collection (automatic)
- Development (nix-shell)
- Declarative (no imperative pip installs)

The trade-off is upfront complexity (defining packages), but the long-term benefits (reproducibility, maintainability) are worth it.
