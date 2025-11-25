# Release Checklist

Step-by-step guide for releasing a new version.

## Pre-Release

- [ ] All features working and tested
- [ ] Unit tests passing (`swift test`)
- [ ] No compiler warnings (`swift build -c release`)
- [ ] README.md updated
- [ ] CHANGELOG.md updated with new version
- [ ] Version bumped in relevant files

## Release Steps

### 1. Commit and Push

```bash
# Make sure everything is committed
git status

# Push to GitHub
git push origin main
git push --tags
```

### 2. Create GitHub Release

1. Go to: https://github.com/thepearl/xcode-janitor-mcp/releases/new

2. Fill in:
   - **Tag:** v0.1.0 (or your version)
   - **Title:** v0.1.0 - Initial Production Release
   - **Description:** Copy from CHANGELOG.md

3. Click **"Publish release"**

### 3. Calculate SHA256 for Homebrew

GitHub automatically creates a source archive. Get its SHA256:

```bash
# Download the release tarball
curl -L https://github.com/thepearl/xcode-janitor-mcp/archive/refs/tags/v0.1.0.tar.gz -o v0.1.0.tar.gz

# Calculate SHA256
shasum -a 256 v0.1.0.tar.gz

# Copy the hash (first part of output)
```

### 4. Update Homebrew Formula

Edit `Formula/xcode-janitor-mcp.rb`:

```ruby
class XcodeJanitorMcp < Formula
  # ...
  url "https://github.com/thepearl/xcode-janitor-mcp/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "PASTE_YOUR_HASH_HERE"  # ← Update this
  # ...
end
```

Commit and push:
```bash
git add Formula/xcode-janitor-mcp.rb
git commit -m "chore: Update Homebrew formula SHA256 for v0.1.0"
git push
```

### 5. Test Homebrew Installation

Test that users can install:

```bash
# Test from GitHub
brew install --build-from-source thepearl/xcode-janitor-mcp/xcode-janitor-mcp

# Verify it works
xcode-janitor-mcp --help

# Test with MCP client
claude mcp add xcode-janitor xcode-janitor-mcp
claude mcp list

# Clean up test
brew uninstall xcode-janitor-mcp
claude mcp remove xcode-janitor
```

### 6. Announce (Optional)

- [ ] Post on Twitter/X
- [ ] Post in relevant communities
- [ ] Update any documentation sites

## Quick Reference

### Version Bump Process

1. Update CHANGELOG.md with new version
2. Update version in Package.swift (if versioned)
3. Commit: `git commit -m "chore: Bump version to vX.Y.Z"`
4. Tag: `git tag -a vX.Y.Z -m "Release vX.Y.Z"`
5. Push: `git push && git push --tags`

### Homebrew Formula Template

```ruby
class XcodeJanitorMcp < Formula
  desc "MCP server for cleaning unused assets in Xcode projects"
  homepage "https://github.com/thepearl/xcode-janitor-mcp"
  url "https://github.com/thepearl/xcode-janitor-mcp/archive/refs/tags/vX.Y.Z.tar.gz"
  sha256 "CALCULATE_THIS_AFTER_RELEASE"
  license "MIT"

  depends_on :macos
  depends_on xcode: ["14.0", :build]

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/XcodeJanitorMCP" => "xcode-janitor-mcp"
  end

  test do
    output = shell_output("#{bin}/xcode-janitor-mcp 2>&1", 0)
    assert_match "Starting Xcode Janitor MCP Server", output
  end
end
```

## Common Issues

### SHA256 doesn't match
- Make sure you're using the exact URL from the formula
- GitHub may take a minute to generate the archive after release
- Wait 1-2 minutes and try downloading again

### Build fails during Homebrew install
- Check Swift/Xcode version requirements
- Test build locally first: `swift build -c release`
- Check the Homebrew build logs

### Formula audit fails
```bash
brew audit --new Formula/xcode-janitor-mcp.rb
brew style Formula/xcode-janitor-mcp.rb
```

## Post-Release

- [ ] Test Homebrew installation
- [ ] Verify README installation instructions work
- [ ] Check GitHub release looks good
- [ ] Monitor for issues/feedback
- [ ] Respond to any installation questions

---

**Current Version:** v0.1.0
**Last Release:** 2024-11-25
**Next Release:** TBD
