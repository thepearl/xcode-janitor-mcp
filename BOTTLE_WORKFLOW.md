# Homebrew Bottle Automation Workflow

This document explains how the automated bottle building and publishing workflow works for the Xcode Janitor MCP Homebrew tap.

## Overview

Bottles are pre-compiled binaries that allow users to install via Homebrew without needing Xcode or Command Line Tools. Our GitHub Actions workflows automatically build bottles for macOS 13, 14, and 15.

## Workflow Architecture

```
┌─────────────────────────────────────────────────┐
│  1. Update formula version in PR                │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────┐
│  2. test.yml workflow runs automatically        │
│     - Builds on macOS-13, macOS-14, macOS-15    │
│     - Creates bottles in parallel               │
│     - Uploads as GitHub Actions artifacts       │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────┐
│  3. Add 'pr-pull' label to PR                   │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────┐
│  4. publish.yml workflow triggers               │
│     - Downloads bottles from artifacts          │
│     - Uploads to GitHub Releases                │
│     - Updates formula with bottle block         │
│     - Auto-merges PR                            │
└─────────────────────────────────────────────────┘
```

## Files

### `.github/workflows/test.yml`
- Triggers on: Push to `master` and all pull requests
- Runs on: macOS 13, 14, 15 (parallel matrix)
- Actions:
  - Sets up Homebrew
  - Runs syntax validation
  - Builds formula and creates bottles (PR only)
  - Uploads bottles as artifacts (PR only)

### `.github/workflows/publish.yml`
- Triggers on: Pull request labeled with `pr-pull`
- Runs on: Ubuntu 22.04
- Actions:
  - Downloads bottles from test workflow artifacts
  - Uploads bottles to GitHub Releases
  - Updates formula with bottle SHA256 hashes
  - Commits changes back to PR
  - Merges PR automatically
  - Deletes feature branch

## Release Process

### For New Versions (e.g., v0.13.0)

1. **Create release branch:**
   ```bash
   git checkout -b release/0.13.0
   ```

2. **Update formula:**
   ```bash
   # Edit Formula/xcode-janitor-mcp.rb
   # - Update version number in URL
   # - Update sha256 (download tarball and run: shasum -a 256 v0.13.0.tar.gz)
   ```

3. **Create PR:**
   ```bash
   git add Formula/xcode-janitor-mcp.rb
   git commit -m "chore: bump version to 0.13.0"
   git push origin release/0.13.0
   gh pr create --title "Release v0.13.0" --body "Bump version to 0.13.0"
   ```

4. **Wait for bottles:**
   - GitHub Actions `test.yml` will run automatically
   - Wait for all 3 OS builds to complete (macOS 13, 14, 15)
   - Check Actions tab for status

5. **Trigger bottle upload:**
   ```bash
   gh pr edit --add-label pr-pull
   ```
   OR via GitHub UI: Add label `pr-pull` to the PR

6. **Workflow completes:**
   - `publish.yml` workflow downloads bottles
   - Uploads to GitHub Releases (under tag v0.13.0)
   - Updates formula with bottle block
   - Auto-merges PR
   - Deletes release branch

7. **Create GitHub Release:**
   ```bash
   git checkout master
   git pull
   git tag v0.13.0
   git push origin v0.13.0
   gh release create v0.13.0 --title "v0.13.0" --notes "Release notes here"
   ```

## Bottle Structure

After the workflow completes, your formula will have a bottle block like this:

```ruby
bottle do
  root_url "https://github.com/thepearl/xcode-janitor-mcp/releases/download/v0.13.0"
  sha256 cellar: :any_skip_relocation, arm64_sequoia: "abc123..."
  sha256 cellar: :any_skip_relocation, arm64_sonoma: "def456..."
  sha256 cellar: :any_skip_relocation, arm64_ventura: "789ghi..."
end
```

## User Experience

**Without bottles (before):**
```bash
$ brew install thepearl/tap/xcode-janitor-mcp
==> Downloading source...
==> Building with swift build...  # Requires Xcode/CLT, takes 2-3 minutes
Error: Command Line Tools required!
```

**With bottles (after):**
```bash
$ brew install thepearl/tap/xcode-janitor-mcp
==> Downloading bottle...
==> Pouring xcode-janitor-mcp--0.13.0.arm64_sequoia.bottle.tar.gz
🍺  /opt/homebrew/Cellar/xcode-janitor-mcp/0.13.0: 2 files, 3.1MB
# Completes in 5-10 seconds, no compilation needed!
```

## Troubleshooting

### Bottles not building

Check the Actions tab for errors. Common issues:
- Formula syntax errors (test-bot will catch these)
- Build failures (check Swift compilation errors)
- Missing dependencies

### pr-pull workflow not triggering

Ensure:
- PR is from a branch in the same repo (not a fork)
- Label is exactly `pr-pull` (case-sensitive)
- PR is still open when labeled

### Bottles uploaded but formula not updated

The `brew pr-pull` command should automatically:
1. Download bottles from artifacts
2. Upload to GitHub Releases
3. Calculate SHA256 hashes
4. Update formula with bottle block
5. Commit to PR

If this fails, check the publish.yml workflow logs.

### Manual bottle creation (fallback)

If automation fails, you can manually create bottles:

```bash
# Install and build bottle
brew install --build-bottle thepearl/tap/xcode-janitor-mcp
brew bottle xcode-janitor-mcp

# This creates: xcode-janitor-mcp--0.13.0.arm64_sequoia.bottle.tar.gz

# Upload to GitHub Releases
gh release upload v0.13.0 *.bottle.tar.gz

# Update formula manually with bottle block
```

## Benefits

✅ **No Command Line Tools needed** - Users don't need Xcode/CLT
✅ **Fast installation** - 5-10 seconds vs 2-3 minutes
✅ **Multi-version support** - Works on macOS 13, 14, 15
✅ **Zero maintenance** - Fully automated on every release
✅ **Professional** - Same workflow used by major Homebrew taps

## References

- [Homebrew Tap with Bottles](https://brew.sh/2020/11/18/homebrew-tap-with-bottles-uploaded-to-github-releases/)
- [Homebrew Test Bot](https://github.com/Homebrew/homebrew-test-bot)
- [GitHub Actions for Homebrew](https://github.com/Homebrew/actions)
