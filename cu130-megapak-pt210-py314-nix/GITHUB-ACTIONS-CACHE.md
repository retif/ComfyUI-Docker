# GitHub Actions Cache Setup

## Overview

The workflow now uses **GitHub Actions cache** for Nix store caching instead of Cachix.

## How It Works

### 1. Cache Nix Store (lines 34-44)
```yaml
- name: Cache Nix store
  uses: actions/cache@v4
  id: nix-cache
  with:
    path: |
      /nix/store        # Nix derivations
      /nix/var/nix/db   # Nix database
      ~/.cache/nix      # Nix metadata
    key: nix-store-${{ runner.os }}-${{ hashFiles('cu130-megapak-pt210-py314-nix/flake.lock') }}
    restore-keys: |
      nix-store-${{ runner.os }}-
```

**Cache Key:**
- `nix-store-Linux-<flake.lock hash>`
- Changes when `flake.lock` changes (package versions updated)
- Fallback: `nix-store-Linux-` (any previous cache)

**What's Cached:**
- All Nix derivations (packages, layers)
- Nix database (package metadata)
- Nix metadata (build info)

### 2. Cache Status Check (lines 46-52)
```yaml
- name: Cache status
  run: |
    if [ "${{ steps.nix-cache.outputs.cache-hit }}" == "true" ]; then
      echo "✅ Nix store cache hit - derivations will be reused"
    else
      echo "❌ Nix store cache miss - full rebuild required"
    fi
```

**Outputs:**
- `cache-hit: true` → Nix will reuse cached derivations
- `cache-hit: false` → Full rebuild required

### 3. Build with Cache (line 58)
```yaml
- name: Build ComfyUI image
  run: nix build .#comfyui --print-build-logs
```

**Behavior:**
- **Cache hit:** Nix reuses cached derivations (~2-5 min build)
- **Cache miss:** Nix builds everything from scratch (~40 min build)

### 4. Push with Layer Deduplication (lines 77-79)
```yaml
nix run .#comfyui.copyToRegistry -- \
  --dest-creds "$GITHUB_ACTOR:$GITHUB_TOKEN" \
  ghcr.io/$GITHUB_REPOSITORY_OWNER/comfyui-nix2container:cu130-megapak-py314
```

**Registry behavior:**
- Compares OCI layer digests
- Unchanged layers: "Already exists, skip upload"
- Changed layers: Upload only new data

## Cache Characteristics

### Size Limit
- **10 GB per repository** (all caches combined)
- Monitor usage: Repo Settings → Actions → Caches

### Eviction Policy
- **7-day retention** for unused caches
- Keeps most recently used caches
- Oldest caches evicted when limit reached

### Cache Key Strategy
```
nix-store-Linux-abc123  ← Exact match (flake.lock hash: abc123)
nix-store-Linux-def456  ← Different flake.lock (hash: def456)
nix-store-Linux-        ← Fallback (any Linux cache)
```

**Example scenario:**
1. First build: No cache → Full rebuild → Cache saved as `nix-store-Linux-abc123`
2. Second build: `flake.lock` unchanged → Cache hit → Fast rebuild (~2 min)
3. Update packages: `flake.lock` changes → New hash `def456` → Cache miss → Full rebuild
4. Fourth build: Hash `def456` → Cache hit → Fast rebuild

### What Gets Cached
```
/nix/store/
  ├── abc123-python-3.14/
  ├── def456-pytorch-2.10.0/
  ├── ghi789-pak3-packages/
  ├── jkl012-pak5-packages/
  └── ... (all derivations)

/nix/var/nix/db/
  └── db.sqlite (package metadata)

~/.cache/nix/
  └── fetchers/ (download cache)
```

## Performance Impact

### First Build (cold cache)
```
1. Cache restore: MISS (~10 sec to check)
2. Nix build: ~40 min (full build)
3. Push to GHCR: ~8 min
4. Cache save: ~5 min (upload to GitHub)
Total: ~53 min
```

### Second Build (warm cache, no changes)
```
1. Cache restore: HIT (~2 min to download/extract)
2. Nix build: ~30 sec (all cached)
3. Push to GHCR: ~30 sec (all layers exist)
4. Cache save: SKIP (no changes)
Total: ~3 min
```

### Incremental Build (change pak5)
```
1. Cache restore: HIT (~2 min)
2. Nix build: ~5 min (rebuild pak5 layer only)
3. Push to GHCR: ~1 min (only pak5 layer uploads)
4. Cache save: ~1 min (only new derivations)
Total: ~9 min
```

## Monitoring Cache Usage

### View Cache Status
```bash
# In GitHub UI
Repo → Settings → Actions → Caches

# Shows:
- Cache key
- Size
- Last accessed
- Created date
```

### Check Cache in Workflow
The workflow outputs cache status in job summary:
```
✅ Nix store cache hit - derivations will be reused
Cache key: nix-store-Linux-abc123def456
```

### Clear Cache (if needed)
```bash
# In GitHub UI
Settings → Actions → Caches → [Delete cache]

# Or via GitHub CLI
gh cache delete <cache-id>
```

## Troubleshooting

### Cache Not Working
**Symptom:** Every build takes ~40 min

**Debug:**
1. Check workflow logs for cache status
2. Verify cache key in Settings → Actions → Caches
3. Check if cache size approaching 10 GB limit

**Solutions:**
- Ensure `flake.lock` is committed
- Check `hashFiles()` path is correct
- Verify cache isn't being evicted (check last accessed time)

### Cache Size Limit Exceeded
**Symptom:** Warning in workflow logs about cache eviction

**Solutions:**
1. **Clean up old caches:**
   ```bash
   # Delete unused caches
   gh cache list | grep nix-store | awk '{print $1}' | xargs -I {} gh cache delete {}
   ```

2. **Reduce cache paths** (exclude less important data):
   ```yaml
   path: |
     /nix/store          # Keep
     /nix/var/nix/db     # Keep
     # ~/.cache/nix      # Exclude if needed
   ```

3. **Use cache scope:**
   ```yaml
   # Separate caches per branch
   key: nix-store-${{ runner.os }}-${{ github.ref }}-${{ hashFiles('flake.lock') }}
   ```

### Slow Cache Restore
**Symptom:** Cache restore takes 5+ minutes

**Cause:** Large cache size (~8-10 GB)

**Solutions:**
- This is normal for large Nix stores
- Consider using Cachix for faster binary cache
- Optimize cache paths to exclude unnecessary data

### Cache Miss After flake.lock Update
**Symptom:** Cache miss after updating packages

**Cause:** Cache key includes `hashFiles('flake.lock')`

**Behavior:** This is **expected and correct**
- New packages → New derivations → New cache key
- Old cache still exists as fallback (restore-keys)
- Nix will reuse what it can from old cache

## Comparison: GitHub Actions vs Cachix

| Feature | GitHub Actions Cache | Cachix |
|---------|---------------------|--------|
| **Setup** | Built-in | External account |
| **Cost** | Free | Free (OSS) / Paid |
| **Size limit** | 10 GB per repo | Unlimited (paid) |
| **Retention** | 7 days unused | Configurable |
| **Speed** | 2-5 min restore | 30 sec - 2 min |
| **Multi-repo** | Per-repo | Shared across repos |
| **Local dev** | No | Yes (binary cache) |

**Recommendation:**
- **GitHub Actions cache** for simple, self-contained projects
- **Cachix** for complex, multi-repo, or team projects

## Next Steps

1. **Test the workflow:**
   ```bash
   # Push a change to trigger workflow
   git add .github/workflows/build-nix2container.yml
   git commit -m "Add GitHub Actions cache for Nix store"
   git push
   ```

2. **Monitor first build:**
   - Check workflow logs for cache status
   - First run will be slow (cache miss)
   - Verify cache is saved after build

3. **Test cache effectiveness:**
   - Trigger another build (no changes)
   - Should complete in ~3 min (cache hit)
   - Check workflow summary for cache stats

4. **Monitor cache usage:**
   - Settings → Actions → Caches
   - Watch cache size growth
   - Delete old caches if needed

## References

- [GitHub Actions Cache Documentation](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows)
- [actions/cache Repository](https://github.com/actions/cache)
- [Nix Binary Cache Guide](https://nixos.org/manual/nix/stable/package-management/binary-cache.html)
