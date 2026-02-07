# NixOS Flake Design - ComfyUI Docker Image

## Design Philosophy

### Declarative Over Imperative

Traditional Dockerfiles are imperative scripts:
```dockerfile
RUN apt-get update && apt-get install -y python3
RUN pip install torch
RUN git clone ...
```

Nix flakes are declarative specifications:
```nix
python = pkgs.python314;
torch = python.pkgs.torch;
```

### Layer Strategy

#### Problem with Traditional Dockerfiles
- Layers rebuild if anything above changes
- No content-addressing
- Hard to reuse layers across images
- Manual cache optimization

#### Nix Solution
- Content-addressed store
- Automatic deduplication
- Composable derivations
- Smart layer splitting with `streamLayeredImage`

### Six-Layer Architecture

```
┌─────────────────────────────────┐
│  Layer 6: Runtime Config        │  ← Changes most frequently
├─────────────────────────────────┤
│  Layer 5: ComfyUI Application   │  ← Daily updates
├─────────────────────────────────┤
│  Layer 4: Performance Wheels    │  ← Weekly updates
├─────────────────────────────────┤
│  Layer 3: Python Dependencies   │  ← When deps change
├─────────────────────────────────┤
│  Layer 2: PyTorch + ML Stack    │  ← Monthly updates
├─────────────────────────────────┤
│  Layer 1: Python 3.14           │  ← Stable
├─────────────────────────────────┤
│  Layer 0: Base + CUDA           │  ← Most stable
└─────────────────────────────────┘
```

Layers ordered by stability (bottom = most stable, top = most volatile).

## Key Design Decisions

### 1. Using `streamLayeredImage` vs `buildImage`

```nix
# Option A: buildImage - Simple, single layer
buildImage {
  name = "comfyui";
  contents = [ everything ];
}

# Option B: streamLayeredImage - Smart multi-layer ✓
streamLayeredImage {
  name = "comfyui";
  fromImage = previousLayer;
  maxLayers = 100;  # Automatic optimization
}
```

**Choice**: `streamLayeredImage`
- Automatically splits into optimal layers
- Respects Docker's 125 layer limit
- Content-addressed for deduplication

### 2. Mixing Nix Packages with pip

```nix
# Pure Nix approach (ideal but limited)
python.withPackages (ps: with ps; [
  torch  # May not have CUDA 13.0
  numpy
])

# Hybrid approach (pragmatic) ✓
runAsRoot = ''
  ${python}/bin/pip install torch \
    --index-url https://download.pytorch.org/whl/cu130
''
```

**Choice**: Hybrid
- Use Nix for system packages (gcc, CUDA)
- Use pip for ML packages (better CUDA support)
- Future: Move to pure Nix as packages mature

### 3. Layer Granularity

**Too coarse** (1-2 layers):
- Rebuild everything on small changes
- Lose caching benefits

**Too fine** (50+ layers):
- Hit Docker layer limit
- Slower builds (more overhead)
- Harder to reason about

**Optimal** (6 layers):
- Balance rebuild time vs complexity
- Group by update frequency
- Clear separation of concerns

### 4. Free-Threading Python

```nix
# Standard Python
python = pkgs.python314;

# Free-threaded (no GIL) - Future
python = pkgs.python314.override {
  enableOptimizations = true;
  freeThreading = true;  # May not be in nixpkgs yet
};
```

**Current**: Use standard Python 3.14 from nixpkgs
**Future**: Override with free-threading when available

## Implementation Strategy

### Phase 1: Core Structure ✓
- [x] Define flake.nix with 6 layers
- [x] Create build system (Makefile, apps)
- [x] Document architecture

### Phase 2: Integration
- [ ] Copy builder-scripts into appropriate layers
- [ ] Add pak*.txt dependency files
- [ ] Integrate preload-cache.sh
- [ ] Test layer builds independently

### Phase 3: Optimization
- [ ] Minimize layer sizes
- [ ] Add proper caching
- [ ] Parallel builds where possible
- [ ] Benchmark vs Dockerfile approach

### Phase 4: CI/CD
- [ ] GitHub Actions workflow
- [ ] Automated testing
- [ ] Multi-arch support (amd64, arm64)
- [ ] Push to GHCR

## Technical Details

### Content Addressing

Nix uses content-addressed storage:
```
/nix/store/hash-package-version
            ↑
            Derived from inputs + build script
```

Same inputs → same hash → reuse cached build

### Reproducibility

Every build input is pinned in flake.lock:
```json
{
  "nixpkgs": {
    "locked": {
      "narHash": "sha256-...",
      "rev": "abc123...",
      "type": "github"
    }
  }
}
```

### Composability

Each layer is a standalone derivation:
```nix
# Use comfyui as base for custom image
imports.comfyui.url = "github:retif/ComfyUI-Docker/...";

myImage = buildImage {
  fromImage = comfyui.packages.x86_64-linux.comfyuiLayer;
  # Add custom stuff
};
```

## Comparison Matrix

| Feature | Dockerfile | Nix Flake |
|---------|-----------|-----------|
| **Reproducibility** | ⚠️ Best effort | ✅ Guaranteed |
| **Caching** | Layer-based | Content-addressed |
| **Composition** | Limited | Excellent |
| **Dev parity** | Different env | Same definition |
| **Learning curve** | Low | Moderate |
| **Build speed** | Fast (cached) | Fast (cached) |
| **Debugging** | Good | Moderate |
| **Multi-arch** | Manual | Built-in |

## Future Enhancements

### 1. Pure Nix Dependencies
Replace pip installs with Nix packages as they become available:
```nix
python.withPackages (ps: with ps; [
  torch-cuda130  # When available
  flash-attn
  sageattention
])
```

### 2. Flake Modules
Extract layers into reusable modules:
```nix
# modules/cuda-layer.nix
{ pkgs, cudaVersion }:
pkgs.dockerTools.buildImage {
  # CUDA layer definition
}
```

### 3. Development Workflows
```bash
# Live reload during development
nix develop --command comfyui-dev-server

# Test specific layer
nix build .#pytorchLayer && docker load < result
```

### 4. Registry Publishing
```bash
# Publish to GitHub Container Registry
nix run .#publish-ghcr

# Publish to Docker Hub
nix run .#publish-dockerhub
```

## Resources

- [Nix Pills](https://nixos.org/guides/nix-pills/) - Learn Nix fundamentals
- [dockerTools manual](https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-dockerTools)
- [Flakes RFC](https://github.com/NixOS/rfcs/blob/master/rfcs/0049-flakes.md)
- [Python in Nix](https://nixos.org/manual/nixpkgs/stable/#python)

## Questions & Answers

**Q: Why not pure Nix for everything?**
A: PyTorch with CUDA 13.0 isn't in nixpkgs yet. Hybrid approach lets us move forward now.

**Q: Can I use this without Nix installed?**
A: Once built, it's a regular Docker image. Nix only needed for building.

**Q: How do updates work?**
A: `nix flake update` updates inputs, `nix build` rebuilds only changed layers.

**Q: What about security updates?**
A: Pin specific nixpkgs revision with known-good packages, or update regularly.

**Q: Can this run on Mac/Windows?**
A: Build requires Linux (for Docker). Nix flakes work cross-platform for dev shell.
