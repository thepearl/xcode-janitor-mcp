# Changelog

All notable changes to Xcode Janitor MCP will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.12.0] - 2025-01-26

### Added
- Server-level instructions for improved discoverability by AI assistants
- Detailed examples in tool descriptions showing exact behavior patterns
- Enhanced parameter descriptions with practical context and usage examples
- Cross-references between related tools for better workflow guidance
- Common search queries section in README demonstrating natural language usage patterns
- "When to Use Xcode Janitor" section in README with clear value propositions

### Changed
- Removed "500x faster" performance claim, replaced with "faster" for accuracy
- Added "unused" keyword to tool descriptions for better semantic matching
- Improved all `project_path` parameters to specify "root directory" with expected contents
- Tightened tool descriptions for better UI display and clarity
- Removed misleading "unused" reference from `check_missing_scales` tool description

### Improved
- Tool descriptions now include concrete examples (e.g., detects 'icon_home' as unused if never referenced)
- Parameter descriptions explain expected values, formats, and provide examples
- Cross-tool workflow recommendations (e.g., "use find_unused_assets first")
- Overall discoverability and semantic matching for AI-powered IDEs

## [0.1.0] - 2024-11-20

### Added
- Initial production release
- 7 MCP tools for Xcode asset management:
  - `index_assets`: Index all .xcassets catalogs
  - `find_unused_assets`: Find and report unused assets
  - `find_asset_usage`: Find where specific assets are used
  - `delete_asset`: Safely delete assets with backup
  - `check_missing_scales`: Detect missing @1x/@2x/@3x variants
  - `get_asset_info`: Get detailed asset information
  - `check_swiftgen_status`: Check SwiftGen configuration
- Fast parallel asset scanning (5-20 seconds for typical projects)
- Interactive HTML reports with sorting, filtering, and search
- JSON reports for automation and scripting
- SwiftGen integration and detection
- Automatic exclusion of Pods, .build, DerivedData directories
- Token-efficient operation (~50 tokens vs 25,000+ for manual search)
- Comprehensive documentation and troubleshooting guide
- Installation verification script
- Homebrew installation support

[0.12.0]: https://github.com/thepearl/xcode-janitor-mcp/compare/v0.1.0...v0.12.0
[0.1.0]: https://github.com/thepearl/xcode-janitor-mcp/releases/tag/v0.1.0
