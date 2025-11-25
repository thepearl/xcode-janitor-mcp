# Changelog

All notable changes to Xcode Janitor MCP will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-11-25

### Added
- Initial release of Xcode Janitor MCP
- Fast asset catalog indexing with parallel processing
- Single-pass unused asset detection (5-20 seconds for most projects)
- Interactive HTML reports with sorting and filtering
- JSON reports for automation/scripting
- SwiftGen integration and detection
- 7 MCP tools:
  - `index_assets` - Index all .xcassets catalogs
  - `find_unused_assets` - Find and report unused assets
  - `find_asset_usage` - Find where specific assets are used
  - `delete_asset` - Safely delete assets with backup
  - `check_missing_scales` - Detect missing @1x/@2x/@3x variants
  - `get_asset_info` - Get detailed asset information
  - `check_swiftgen_status` - Check SwiftGen configuration
- Automatic exclusion of Pods, .build, DerivedData
- Unit tests for core functionality
- Installation verification script
- Comprehensive documentation and troubleshooting guide

### Performance
- Processes 10,000+ Swift files in 10-15 seconds
- Single-pass parallel scanning with compiled regex patterns
- Token-efficient: ~50 tokens vs 25,000+ for standard approaches

### Known Limitations
- Only Swift files are scanned (Objective-C not supported)
- Storyboard/XIB asset references not detected
- Dynamic asset loading (string interpolation) not detected
- SwiftGen assets currently all marked as "used"

## [Unreleased]

### Planned Features
- Objective-C file support
- Storyboard/XIB asset detection
- Smart SwiftGen enum usage detection
- Asset keep/ignore comments
- Duplicate asset detection
- Asset optimization suggestions
- CI/CD integration examples
