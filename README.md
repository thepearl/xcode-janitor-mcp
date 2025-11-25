# 🧹 Xcode Asset Janitor MCP

MCP (Model Context Protocol) server for cleaning up unused assets in Xcode projects. Find and remove unused images, colors, and data assets with interactive HTML reports.

## ✨ Features

- 🔍 **Fast Asset Indexing** - Scans all `.xcassets` in your Xcode project
- 🚀 **Parallel Analysis** - Processes 10,000+ Swift files in 10-15 seconds
- 📊 **Interactive HTML Reports** - Sortable and filterable reports
- 💾 **Token Efficient** - Saves results to files instead of consuming tokens (~50 tokens using janitor vs 25,000+ using standard claude code / copilot for a project with 10k swift files) 
- 🔧 **SwiftGen Support** - Automatically detects SwiftGen-managed assets
- ⚡ **Smart Filtering** - Skip Pods, .build, DerivedData automatically

## 📋 Requirements

- macOS 13.0+
- Swift 6.0+
- Claude Code (or Claude CLI), VS Code extension or other MCP compatible IDEs.

## 🚀 Installation

### Homebrew (Recommended)

```bash
brew install thepearl/xcode-janitor-mcp/xcode-janitor-mcp
```

That's it! The `xcode-janitor-mcp` binary will be available in your PATH.

### Build from Source

If you prefer to build from source:

```bash
git clone https://github.com/thepearl/xcode-janitor-mcp.git
cd xcode-janitor-mcp
swift build -c release
```

The binary will be at `.build/release/XcodeJanitorMCP`

**Verify Installation:**
```bash
./verify-installation.sh
```

## Configure MCP Client

After installing, configure your MCP client to use Xcode Janitor.

### General Configuration

Most MCP clients (Cursor, VS Code, Windsurf, Claude Desktop etc) use this JSON format. Add to your client's `mcpServers` configuration:

**If installed via Homebrew:**
```json
{
  "xcode-janitor": {
    "command": "xcode-janitor-mcp"
  }
}
```

**If built from source:**
```json
{
  "xcode-janitor": {
    "command": "/absolute/path/to/xcode-janitor-mcp/.build/release/XcodeJanitorMCP"
  }
}
```

<details>
<summary>💡 How to get absolute path for source build</summary>

```bash
cd xcode-janitor-mcp && pwd
# Example output: /Users/you/projects/xcode-janitor-mcp
# Use: /Users/you/projects/xcode-janitor-mcp/.build/release/XcodeJanitorMCP
```
</details>

### Specific Client Installation Instructions

#### Claude Code CLI

**If installed via Homebrew:**
```bash
claude mcp add xcode-janitor xcode-janitor-mcp
```

**If built from source:**
```bash
claude mcp add xcode-janitor /absolute/path/to/xcode-janitor-mcp/.build/release/XcodeJanitorMCP
```

Verify it's connected:
```bash
claude mcp list
```

You should see:
```
xcode-janitor: xcode-janitor-mcp - ✓ Connected
```

#### Claude Desktop (MacOS)

Edit `~/Library/Application Support/Claude/claude_desktop_config.json`:

**If installed via Homebrew:**
```json
{
  "mcpServers": {
    "xcode-janitor": {
      "command": "xcode-janitor-mcp"
    }
  }
}
```

**If built from source:**
```json
{
  "mcpServers": {
    "xcode-janitor": {
      "command": "/absolute/path/to/xcode-janitor-mcp/.build/release/XcodeJanitorMCP"
    }
  }
}
```

Restart Claude Desktop after making changes.

#### VS Code / Cursor / Windsurf

1. Open Settings (Cmd+,)
2. Search for "MCP" or "Claude: MCP"
3. Add server configuration:

**If installed via Homebrew:**
```json
{
  "xcode-janitor": {
    "command": "xcode-janitor-mcp"
  }
}
```

**If built from source:**
```json
{
  "xcode-janitor": {
    "command": "/absolute/path/to/xcode-janitor-mcp/.build/release/XcodeJanitorMCP"
  }
}
```

4. Restart the extension or reload the window

## 🎯 Usage

### Basic Workflow

1. Navigate to your Xcode project:
```bash
cd ~/your-ios-project
```

2. Ask in chat:
```
Find unused assets and save to file
```

3. Open the HTML report:
```bash
open unused_assets_report.html
```

### Available Commands

Ask naturally:

- **"Index assets in this project"**
  - Scans all `.xcassets` catalogs
  - Shows total count and breakdown

- **"Find unused assets and save to file"**
  - Analyzes all Swift files
  - Checks for asset usage
  - Generates JSON + HTML reports
  - Default: `unused_assets_report.{json,html}`

- **"Check SwiftGen status"**
  - Detects SwiftGen configuration
  - Shows managed assets
  - Reports SwiftGen coverage

- **"Find where 'assetName' is used"**
  - Shows all references to specific asset
  - Lists files, line numbers, context

- **"Delete asset 'assetName' from the project"**
  - Creates backup first
  - Removes asset safely
  - Reports size freed

## 📊 HTML Report Features

The generated HTML report includes:

### Summary Dashboard
- Total Assets Scanned
- Unused Assets Count
- Total Size (MB)
- Space Savings %

### Interactive Table
- **Sortable**: Click Asset Name or Size to sort
- **Search**: Filter by asset name (live)
- **Type Filter**: Images, Colors, Data
- **Catalog Filter**: By `.xcassets` file

### Columns
- **Asset Name** - Name of the unused asset
- **Type** - Badge (Image/Color/Data)
- **Catalog** - Which `.xcassets` file
- **Size** - File size in MB
- **Path** - Shortened file path

## ⚡ Performance

For a typical iOS project:

- **Project Size**: tested on iOS project with 8,319 Swift files, 2,498 assets
- **Old Approach**: 3-10 minutes using standard agents
- **Optimized**: 5-20 seconds depending on how big the project is.

### How It's Fast

1. **Single-pass scanning** - Reads each file once
2. **Parallel processing** - Uses all CPU cores
3. **Pre-compiled regex** - Patterns compiled once
4. **Smart filtering** - Skips Pods, .build, DerivedData

## 🔧 SwiftGen Support

If your project uses [SwiftGen](https://github.com/SwiftGen/SwiftGen):

- Automatically detects `swiftgen.yml` configuration
- Understands SwiftGen-managed assets and how they're used
- Prevents false positives in unused reports

Supported config files:
- `swiftgen.yml`
- `swiftgen.yaml`
- `.swiftgen.yml`

## 📁 Output Files

### JSON Report (`unused_assets_report.json`)
Machine-readable format for scripts/automation:

```json
{
  "generated_at": "2024-11-20T16:00:00Z",
  "project_path": "/Users/you/project",
  "summary": {
    "total_assets_scanned": 2498,
    "unused_count": 1528,
    "total_size_mb": "245.67"
  },
  "unused_assets": [...]
}
```

### HTML Report (`unused_assets_report.html`)
Interactive web interface:
- Self-contained (no external dependencies)
- Works offline
- Sortable, filterable, searchable
- Mobile responsive

## 🛠️ Advanced Usage

### Custom Output Path
```
Find unused assets and save to ~/Desktop/cleanup_report.json
```

### Filter by Pattern
```
Find unused assets matching "Splash*"
```

### Get Detailed Info
```
Get info about asset "AppIcon-Prod"
```

## 📝 Example Session

```bash
cd ~/dev/my-ios-app

# Ask Claude:
> Find unused assets and save to file

# Claude responds:
✓ Scanned 8,319 Swift files
✓ Found 1,528 unused assets
✓ Total size: 245.67 MB
✓ Reports saved to:
  - unused_assets_report.json
  - unused_assets_report.html

# Open report
open unused_assets_report.html

# Review in browser, then delete specific assets
> Delete asset "legacyHomeBg" from the project

# Verify
> Find unused assets again
```

## 🤝 Development

### Project Structure
```
xcode-janitor-mcp/
├── Package.swift
├── Sources/XcodeJanitorMCP/
│   ├── XcodeJanitorMCP.swift      # Main MCP server
│   ├── Models/
│   │   └── Asset.swift             # Data models
│   ├── Parsers/
│   │   ├── XCAssetsParser.swift   # Parse .xcassets
│   │   ├── SwiftCodeParser.swift  # Parse Swift files
│   │   └── SwiftGenParser.swift   # Parse swiftgen.yml
│   └── Tools/
│       ├── AssetIndexer.swift     # Index assets
│       ├── FastUsageAnalyzer.swift # Find usage (optimized)
│       ├── AssetManager.swift      # Delete assets
│       └── HTMLReportGenerator.swift # Generate HTML
```

### Building
```bash
# Debug build
swift build

# Release build (optimized)
swift build -c release

# Run tests
swift test
```

## 🐛 Troubleshooting

### MCP Server Won't Connect

**Symptom:** Claude Code/CLI doesn't show the xcode-janitor server

**Solutions:**

1. **Verify build succeeded:**
   ```bash
   ./verify-installation.sh
   ```

2. **Check the binary path is absolute:**
   ```bash
   realpath .build/release/XcodeJanitorMCP
   ```
   Must be an absolute path in your MCP config (not relative `~/` paths)

3. **Verify it's executable:**
   ```bash
   chmod +x .build/release/XcodeJanitorMCP
   ```

4. **Test server manually:**
   ```bash
   echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | .build/release/XcodeJanitorMCP
   ```
   Should return a JSON response with `"result"`

5. **Restart your MCP client:**
   - Claude Desktop: Quit and reopen the app
   - VS Code/Cursor/Windsurf: Reload window (Cmd+Shift+P → "Developer: Reload Window")
   - Claude Code CLI: Exit and start new session

### Build Errors

**Symptom:** `swift build` fails

**Solutions:**

1. **Check Swift version:**
   ```bash
   swift --version
   ```
   Requires Swift 6.0+, macOS 13+

2. **Clean build artifacts:**
   ```bash
   rm -rf .build
   swift build -c release
   ```

3. **Update dependencies:**
   ```bash
   swift package update
   ```

### Slow Performance

**Symptom:** Analysis takes longer than expected

**Solutions:**

- ✅ **Use release build:** `swift build -c release` (10x faster than debug)
- ✅ **Check project location:** Network drives are slow; use local SSD
- ✅ **Expected times:**
  - Small projects (<1k files): 2-5 seconds
  - Medium projects (1k-5k files): 5-15 seconds
  - Large projects (5k-15k+ files): 15-60 seconds

### False Positives (Assets Marked Unused Incorrectly)

**Symptom:** Asset is marked unused but you know it's used

**Common Causes:**

1. **Storyboards/XIBs (not supported yet)**
   - XIB/Storyboard asset references aren't detected
   - Workaround: Manually verify before deleting

2. **Dynamic loading (string interpolation)**
   ```swift
   let name = "icon_\(type)"
   UIImage(named: name)  // Won't be detected
   ```
   - Workaround: Use `// janitor:keep icon_*` comment (feature TBD)

3. **Objective-C files (not supported yet)**
   - Only Swift files are scanned
   - Workaround: Search `.m` files manually

4. **External references**
   - Assets used in frameworks/packages
   - Workaround: Check before deleting

**Recommended Workflow:**
1. Review HTML report before deleting
2. Use `dry_run: true` first to simulate deletion
3. Check git diff before committing
4. Create backups (automatic with `create_backup: true`)

### False Negatives (Unused Assets Not Detected)

**Symptom:** You know an asset is unused but it's not in the report

**Common Causes:**

1. **SwiftGen managed assets**
   - Currently all SwiftGen assets marked as "used"
   - Check: `Ask Claude to check SwiftGen status`

2. **Asset name matches code string**
   ```swift
   let str = "MyImage"  // Asset "MyImage" marked as used
   ```

### Tests Failing

**Symptom:** `swift test` reports failures

**Solutions:**

1. **Check write permissions:**
   ```bash
   ls -la /tmp
   ```
   Tests use `/tmp` for temporary files

2. **Clean test artifacts:**
   ```bash
   rm -rf .build
   swift test
   ```

### Report Not Generated

**Symptom:** No HTML/JSON report created

**Solutions:**

1. **Check write permissions:**
   ```bash
   ls -ld /path/to/your/project
   ```

2. **Specify absolute path:**
   ```
   Ask Claude: Find unused assets and save to ~/Desktop/report.json
   ```

3. **Check disk space:**
   ```bash
   df -h .
   ```

## 📄 License

MIT License - See LICENSE file for details

## 🙏 Acknowledgments

- Built with [Swift MCP SDK](https://github.com/modelcontextprotocol/swift-sdk)
- Inspired by the need for better asset cleanup tools
- Tested on real-world iOS projects with 1000+ assets

## 🔗 Links

- [Model Context Protocol](https://modelcontextprotocol.io/)
- [Claude Code](https://code.visualstudio.com/)
- [SwiftGen](https://github.com/SwiftGen/SwiftGen)

---

**Made with ❤️ for iOS developers**
