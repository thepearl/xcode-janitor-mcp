import Foundation
import MCP

@main
struct XcodeJanitorMCP {
    static func main() async throws {
        fputs("Starting Xcode Janitor MCP Server...\n", stderr)
        
        let server = Server(
            name: "xcode-janitor",
            version: "0.1.0",
            instructions: """
                Specialized MCP server for Xcode iOS/macOS asset management. Use these tools for:
                - Finding unused assets in .xcassets catalogs
                - Analyzing Swift code for UIImage, NSImage, Color asset references
                - Detecting SwiftGen enum usage
                - Managing Xcode asset cleanup and optimization

                These tools are optimized for Xcode projects and faster than general code search.
                """,
            capabilities: .init(
                tools: .init(listChanged: true)
            )
        )
        
        fputs("Server initialized\n", stderr)
        
        let janitor = XcodeJanitor()
        
        // Register tool list handler
        await server.withMethodHandler(ListTools.self) { _ in
            let tools = [
                Tool(
                    name: "index_assets",
                    description: "Index all .xcassets asset catalogs in an Xcode iOS/macOS project to find unused assets. Scans for imagesets, colorsets, and datasets.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "project_path": .object([
                                "type": .string("string"),
                                "description": .string("Path to the Xcode project root directory containing .xcassets folders")
                            ])
                        ]),
                        "required": .array([.string("project_path")])
                    ])
                ),
                Tool(
                    name: "find_unused_assets",
                    description: "Find unused Xcode assets (.xcassets) by scanning Swift code for UIImage(named:), NSImage(named:), Color(named:), and SwiftGen enums. Generates HTML and JSON reports. Faster than general code search.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "project_path": .object([
                                "type": .string("string"),
                                "description": .string("Path to the Xcode project root directory containing .xcassets and Swift files")
                            ]),
                            "output_file": .object([
                                "type": .string("string"),
                                "description": .string("Optional: Custom path to save JSON report (default: unused_assets_report.json in project root). HTML report will be saved alongside.")
                            ]),
                            "minimum_age_days": .object([
                                "type": .string("integer"),
                                "description": .string("Optional: Only include unused assets not modified in the last X days (useful for filtering recently added assets)")
                            ]),
                            "pattern": .object([
                                "type": .string("string"),
                                "description": .string("Optional: Filter results by asset name pattern using wildcards (e.g., 'icon_*' or '*_legacy')")
                            ])
                        ]),
                        "required": .array([.string("project_path")])
                    ])
                ),
                Tool(
                    name: "find_asset_usage",
                    description: "Find where a specific Xcode asset is referenced in Swift code. Detects UIImage(named:), NSImage(named:), Color(named:), and SwiftGen enum usage. Use before deleting to verify assets are unused.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "project_path": .object([
                                "type": .string("string"),
                                "description": .string("Path to the Xcode project root directory")
                            ]),
                            "asset_name": .object([
                                "type": .string("string"),
                                "description": .string("Exact name of the asset to search for (e.g., 'icon_home', 'primaryColor')")
                            ])
                        ]),
                        "required": .array([.string("project_path"), .string("asset_name")])
                    ])
                ),
                Tool(
                    name: "delete_asset",
                    description: "Safely delete unused assets from Xcode .xcassets catalog with automatic backup. Use find_unused_assets first to identify candidates. Supports dry-run mode.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "project_path": .object([
                                "type": .string("string"),
                                "description": .string("Path to the Xcode project root directory")
                            ]),
                            "asset_name": .object([
                                "type": .string("string"),
                                "description": .string("Exact name of the asset to delete from .xcassets catalog")
                            ]),
                            "dry_run": .object([
                                "type": .string("boolean"),
                                "description": .string("If true, simulates deletion and shows what would be deleted without making changes (recommended for first run)")
                            ]),
                            "create_backup": .object([
                                "type": .string("boolean"),
                                "description": .string("If true, creates timestamped backup before deletion (default: true, strongly recommended)")
                            ])
                        ]),
                        "required": .array([.string("project_path"), .string("asset_name")])
                    ])
                ),
                Tool(
                    name: "check_missing_scales",
                    description: "Check for incomplete Xcode imagesets missing @1x, @2x, or @3x resolution variants. Essential for iOS/macOS app asset quality control. Example: detects if an image has @2x but missing @3x for iPhone.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "project_path": .object([
                                "type": .string("string"),
                                "description": .string("Path to the Xcode project root directory")
                            ]),
                            "asset_name": .object([
                                "type": .string("string"),
                                "description": .string("Optional: Check only this specific asset name. If omitted, checks all imagesets in project.")
                            ])
                        ]),
                        "required": .array([.string("project_path")])
                    ])
                ),
                Tool(
                    name: "get_asset_info",
                    description: "Get detailed metadata about a specific Xcode asset including type, catalog location, file path, available scales (@1x/@2x/@3x), and file size. Useful for investigating assets before deletion.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "project_path": .object([
                                "type": .string("string"),
                                "description": .string("Path to the Xcode project root directory")
                            ]),
                            "asset_name": .object([
                                "type": .string("string"),
                                "description": .string("Exact name of the asset to get information about")
                            ])
                        ]),
                        "required": .array([.string("project_path"), .string("asset_name")])
                    ])
                ),
                Tool(
                    name: "check_swiftgen_status",
                    description: "Check which Xcode assets are managed by SwiftGen code generation (swiftgen.yml). Shows which assets have generated enum constants vs direct string references. Run before unused asset analysis.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "project_path": .object([
                                "type": .string("string"),
                                "description": .string("Path to the Xcode project root directory containing swiftgen.yml or .swiftgen.yml config file")
                            ])
                        ]),
                        "required": .array([.string("project_path")])
                    ])
                )
            ]
            return .init(tools: tools)
        }
        
        // Register tool call handler
        await server.withMethodHandler(CallTool.self) { params in
            let arguments = params.arguments ?? [:]
            let result: String
            
            do {
                switch params.name {
                case "index_assets":
                    result = try await janitor.indexAssets(arguments: arguments)
                case "find_unused_assets":
                    result = try await janitor.findUnusedAssets(arguments: arguments)
                case "find_asset_usage":
                    result = try await janitor.findAssetUsage(arguments: arguments)
                case "delete_asset":
                    result = try await janitor.deleteAsset(arguments: arguments)
                case "check_missing_scales":
                    result = try await janitor.checkMissingScales(arguments: arguments)
                case "get_asset_info":
                    result = try await janitor.getAssetInfo(arguments: arguments)
                case "check_swiftgen_status":
                    result = try await janitor.checkSwiftGenStatus(arguments: arguments)
                default:
                    return .init(content: [.text("Unknown tool: \(params.name)")], isError: true)
                }
                
                return .init(content: [.text(result)], isError: false)
            } catch {
                return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
            }
        }
        
        // Start server
        fputs("Starting stdio transport...\n", stderr)
        let transport = StdioTransport()
        fputs("Calling server.start()...\n", stderr)
        try await server.start(transport: transport)
        fputs("Server started successfully, entering run loop...\n", stderr)
        
        // Keep the server running indefinitely
        while true {
            try await Task.sleep(for: .seconds(3600))
        }
    }
}

actor XcodeJanitor {
    private var cachedIndex: AssetIndex?
    private var lastIndexPath: String?
    
    private let indexer = AssetIndexer()
    private let analyzer = UsageAnalyzer()
    private let fastAnalyzer = FastUsageAnalyzer()  // NEW: Optimized analyzer
    private let manager = AssetManager()
    private let swiftGenParser = SwiftGenParser()
    
    func indexAssets(arguments: [String: Value]) async throws -> String {
        guard let projectPath = arguments["project_path"]?.stringValue else {
            throw JanitorError.missingArgument("project_path")
        }
        
        let index = try indexer.indexProject(at: projectPath)
        cachedIndex = index
        lastIndexPath = projectPath
        
        let response: [String: Any] = [
            "success": true,
            "catalogs_found": index.catalogs.count,
            "total_assets": index.totalCount,
            "catalogs": index.catalogs,
            "message": "Successfully indexed \(index.totalCount) assets from \(index.catalogs.count) catalogs"
        ]
        
        return try toJSON(response)
    }
    
    func findUnusedAssets(arguments: [String: Value]) async throws -> String {
        guard let projectPath = arguments["project_path"]?.stringValue else {
            throw JanitorError.missingArgument("project_path")
        }
        
        fputs("Starting fast unused asset scan...\n", stderr)
        let index = try getOrCreateIndex(for: projectPath)
        
        // Use optimized analyzer with single-pass scanning
        var unusedAssets = await fastAnalyzer.findUnusedAssets(index: index, projectPath: projectPath)
        
        if let minAgeDays = arguments["minimum_age_days"]?.intValue {
            unusedAssets = unusedAssets.filter { asset in
                guard let days = asset.daysSinceModified else { return false }
                return days >= minAgeDays
            }
        }
        
        if let pattern = arguments["pattern"]?.stringValue {
            let matchingAssets = indexer.findAssets(matching: pattern, in: index)
            let matchingNames = Set(matchingAssets.map { $0.name })
            unusedAssets = unusedAssets.filter { matchingNames.contains($0.asset.name) }
        }
        
        let totalSize = unusedAssets.reduce(0) { $0 + $1.estimatedSize }
        let sizeMB = Double(totalSize) / 1_048_576.0
        
        // Determine output file path
        let outputFile = arguments["output_file"]?.stringValue ?? "\(projectPath)/unused_assets_report.json"
        
        // Build detailed report
        let report: [String: Any] = [
            "generated_at": ISO8601DateFormatter().string(from: Date()),
            "project_path": projectPath,
            "summary": [
                "total_assets_scanned": index.totalCount,
                "unused_count": unusedAssets.count,
                "total_size_bytes": totalSize,
                "total_size_mb": String(format: "%.2f", sizeMB)
            ],
            "unused_assets": unusedAssets.map { unused -> [String: Any] in
                return [
                    "name": unused.asset.name,
                    "type": unused.asset.type.rawValue,
                    "catalog": unused.asset.catalog,
                    "path": unused.asset.path,
                    "size_bytes": unused.estimatedSize,
                    "size_mb": String(format: "%.2f", Double(unused.estimatedSize) / 1_048_576.0),
                    "days_since_modified": unused.daysSinceModified ?? -1,
                    "scales": unused.asset.scales
                ]
            }
        ]
        
        // Write JSON report to file
        let jsonData = try JSONSerialization.data(withJSONObject: report, options: .prettyPrinted)
        try jsonData.write(to: URL(fileURLWithPath: outputFile))
        
        fputs("JSON report saved to: \(outputFile)\n", stderr)
        
        // Generate HTML report
        let htmlFile = outputFile.replacingOccurrences(of: ".json", with: ".html")
        try HTMLReportGenerator.generateHTML(from: report, outputPath: htmlFile)
        
        fputs("HTML report saved to: \(htmlFile)\n", stderr)
        
        // Return minimal response to avoid token usage
        let response: [String: Any] = [
            "success": true,
            "unused_count": unusedAssets.count,
            "total_size_mb": String(format: "%.2f", sizeMB),
            "json_report": outputFile,
            "html_report": htmlFile,
            "message": """
                Found \(unusedAssets.count) unused assets totaling \(String(format: "%.2f", sizeMB)) MB.
                
                Reports saved:
                - JSON: \(outputFile)
                - HTML: \(htmlFile)
                
                Open the HTML file in your browser for an interactive view!
                """
        ]
        
        return try toJSON(response)
    }
    
    func findAssetUsage(arguments: [String: Value]) async throws -> String {
        guard let projectPath = arguments["project_path"]?.stringValue,
              let assetName = arguments["asset_name"]?.stringValue else {
            throw JanitorError.missingArgument("project_path or asset_name")
        }
        
        let references = analyzer.findAssetUsage(assetName: assetName, in: projectPath)
        
        let response: [String: Any] = [
            "success": true,
            "asset_name": assetName,
            "usage_count": references.count,
            "references": try references.map { try toJSONObject($0) }
        ]
        
        return try toJSON(response)
    }
    
    func deleteAsset(arguments: [String: Value]) async throws -> String {
        guard let projectPath = arguments["project_path"]?.stringValue,
              let assetName = arguments["asset_name"]?.stringValue else {
            throw JanitorError.missingArgument("project_path or asset_name")
        }
        
        let dryRun = arguments["dry_run"]?.boolValue ?? false
        let createBackup = arguments["create_backup"]?.boolValue ?? true
        
        let index = try getOrCreateIndex(for: projectPath)
        
        guard let asset = index.assets.first(where: { $0.name == assetName }) else {
            throw JanitorError.assetNotFound(assetName)
        }
        
        let result = manager.deleteAsset(asset, dryRun: dryRun, createBackup: createBackup)
        
        return try toJSON(try toJSONObject(result))
    }
    
    func checkMissingScales(arguments: [String: Value]) async throws -> String {
        guard let projectPath = arguments["project_path"]?.stringValue else {
            throw JanitorError.missingArgument("project_path")
        }
        
        let index = try getOrCreateIndex(for: projectPath)
        var reports: [MissingScaleReport] = []
        
        if let assetName = arguments["asset_name"]?.stringValue {
            if let asset = index.assets.first(where: { $0.name == assetName }) {
                if let report = manager.checkMissingScales(asset: asset) {
                    reports.append(report)
                }
            }
        } else {
            for asset in index.assets where asset.type == .imageset {
                if let report = manager.checkMissingScales(asset: asset) {
                    reports.append(report)
                }
            }
        }
        
        let response: [String: Any] = [
            "success": true,
            "assets_with_missing_scales": reports.count,
            "reports": try reports.map { try toJSONObject($0) }
        ]
        
        return try toJSON(response)
    }
    
    func getAssetInfo(arguments: [String: Value]) async throws -> String {
        guard let projectPath = arguments["project_path"]?.stringValue,
              let assetName = arguments["asset_name"]?.stringValue else {
            throw JanitorError.missingArgument("project_path or asset_name")
        }
        
        let index = try getOrCreateIndex(for: projectPath)
        
        guard let asset = index.assets.first(where: { $0.name == assetName }) else {
            throw JanitorError.assetNotFound(assetName)
        }
        
        let response: [String: Any] = [
            "success": true,
            "asset": try toJSONObject(asset)
        ]
        
        return try toJSON(response)
    }
    
    func checkSwiftGenStatus(arguments: [String: Value]) async throws -> String {
        guard let projectPath = arguments["project_path"]?.stringValue else {
            throw JanitorError.missingArgument("project_path")
        }
        
        let swiftGenAssets = try swiftGenParser.parseSwiftGenAssets(at: projectPath)
        let index = try getOrCreateIndex(for: projectPath)
        
        // Group by catalog
        var catalogBreakdown: [String: Int] = [:]
        for asset in swiftGenAssets {
            catalogBreakdown[asset.catalog, default: 0] += 1
        }
        
        // Find which assets in the project are managed by SwiftGen
        let managedAssetNames = Set(swiftGenAssets.map { $0.assetName })
        var managedAssetDetails: [[String: Any]] = []
        var unmanagedCount = 0
        
        for asset in index.assets {
            if managedAssetNames.contains(asset.name) {
                // Find the enum path
                if let swiftGenAsset = swiftGenAssets.first(where: { $0.assetName == asset.name }) {
                    managedAssetDetails.append([
                        "name": asset.name,
                        "type": asset.type.rawValue,
                        "catalog": asset.catalog,
                        "enum_path": swiftGenAsset.enumPath
                    ])
                }
            } else {
                unmanagedCount += 1
            }
        }
        
        let response: [String: Any] = [
            "success": true,
            "swiftgen_configured": !swiftGenAssets.isEmpty,
            "total_assets": index.totalCount,
            "swiftgen_managed_count": swiftGenAssets.count,
            "unmanaged_count": unmanagedCount,
            "catalog_breakdown": catalogBreakdown,
            "managed_assets_sample": Array(managedAssetDetails.prefix(10)),
            "message": swiftGenAssets.isEmpty 
                ? "No SwiftGen configuration found. All assets will be checked for direct code references."
                : """
                Found SwiftGen config managing \(swiftGenAssets.count) assets.
                These assets will be checked for ENUM USAGE (e.g., Asset.iconName).
                Only assets where the generated enum is ACTUALLY USED will be marked as used.
                """
        ]
        
        return try toJSON(response)
    }
    
    // Helper methods
    private func getOrCreateIndex(for projectPath: String) throws -> AssetIndex {
        if let cached = cachedIndex, lastIndexPath == projectPath {
            return cached
        }
        
        let index = try indexer.indexProject(at: projectPath)
        cachedIndex = index
        lastIndexPath = projectPath
        return index
    }
    
    private func toJSON(_ object: Any) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
    
    private func toJSONObject<T: Encodable>(_ value: T) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(value)
        let json = try JSONSerialization.jsonObject(with: data)
        return json as? [String: Any] ?? [:]
    }
}

enum JanitorError: Error {
    case missingArgument(String)
    case assetNotFound(String)
}
