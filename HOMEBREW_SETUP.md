# Homebrew Setup Guide

This guide explains how to set up Homebrew distribution for Xcode Janitor MCP.

## Prerequisites

1. Push your code to GitHub (including the v0.1.0 tag)
2. Create a GitHub release for v0.1.0

## Step 1: Create GitHub Release

1. Go to: https://github.com/thepearl/xcode-janitor-mcp/releases/new

2. Fill in the release form:
   - **Tag:** v0.1.0
   - **Title:** v0.1.0 - Initial Production Release
   - **Description:** Copy from CHANGELOG.md

3. Click "Publish release"

## Step 2: Get the SHA256 Hash

After creating the release, GitHub automatically creates a source archive. Get its SHA256:

```bash
# Download the release tarball
curl -L https://github.com/thepearl/xcode-janitor-mcp/archive/refs/tags/v0.1.0.tar.gz -o v0.1.0.tar.gz

# Calculate SHA256
shasum -a 256 v0.1.0.tar.gz
```

Copy the hash (the long string of letters/numbers).

## Step 3: Update the Formula

Edit `Formula/xcode-janitor-mcp.rb` and replace the empty `sha256 ""` with:

```ruby
sha256 "YOUR_HASH_HERE"
```

Commit and push:
```bash
git add Formula/xcode-janitor-mcp.rb
git commit -m "chore: Add SHA256 hash to Homebrew formula"
git push
```

## Step 4: Create a Homebrew Tap Repository

A "tap" is a separate repository that contains your Homebrew formulas.

### Option A: Simple (Formula in main repo)

Users will install with:
```bash
brew install thepearl/xcode-janitor-mcp/xcode-janitor-mcp
```

This works immediately - no extra setup needed!

### Option B: Dedicated Tap (Recommended for multiple tools)

1. Create a new GitHub repository: `homebrew-tap`

2. Move the Formula file:
```bash
cp Formula/xcode-janitor-mcp.rb ../homebrew-tap/
cd ../homebrew-tap
git init
git add xcode-janitor-mcp.rb
git commit -m "Add xcode-janitor-mcp formula"
git remote add origin https://github.com/thepearl/homebrew-tap.git
git push -u origin main
```

3. Users install with:
```bash
brew tap thepearl/tap
brew install xcode-janitor-mcp
```

## Step 5: Test Installation

Test the formula locally before publishing:

```bash
# Test installation
brew install --build-from-source ./Formula/xcode-janitor-mcp.rb

# Test the binary
xcode-janitor-mcp --version

# Uninstall
brew uninstall xcode-janitor-mcp
```

## Step 6: Update README

Add Homebrew instructions to README.md (see updated version).

## Troubleshooting

### Build Fails

If the build fails, check:
- Swift version requirements
- Xcode version
- Dependencies

### SHA256 Mismatch

If SHA256 doesn't match:
```bash
# Recalculate
curl -L https://github.com/thepearl/xcode-janitor-mcp/archive/refs/tags/v0.1.0.tar.gz | shasum -a 256
```

### Test Formula

```bash
brew audit --new Formula/xcode-janitor-mcp.rb
brew style Formula/xcode-janitor-mcp.rb
```

## Quick Start Summary

**Easiest path (Formula in main repo):**

1. Push code + tag to GitHub
2. Create release v0.1.0 on GitHub
3. Calculate SHA256 and update Formula
4. Done! Users can install with:
   ```bash
   brew install thepearl/xcode-janitor-mcp/xcode-janitor-mcp
   ```

**Better UX (Dedicated tap):**

1. Same as above
2. Create `homebrew-tap` repository
3. Move formula there
4. Users install with:
   ```bash
   brew tap thepearl/tap
   brew install xcode-janitor-mcp
   ```
