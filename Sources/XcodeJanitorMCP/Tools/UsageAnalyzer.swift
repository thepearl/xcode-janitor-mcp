import Foundation

class UsageAnalyzer {
    private let swiftParser = SwiftCodeParser()
    private let swiftGenParser = SwiftGenParser()
    
    func findAssetUsage(assetName: String, in projectPath: String) -> [UsageReference] {
        var allReferences: [UsageReference] = []
        let fileManager = FileManager.default
        
        let projectURL = URL(fileURLWithPath: projectPath)
        let enumerator = fileManager.enumerator(at: projectURL, includingPropertiesForKeys: nil)
        
        while let fileURL = enumerator?.nextObject() as? URL {
            let ext = fileURL.pathExtension.lowercased()
            
            switch ext {
            case "swift":
                let references = swiftParser.findAssetReferences(in: fileURL.path)
                let filtered = references.filter { $0.asset == assetName }
                allReferences.append(contentsOf: filtered)
            default:
                break
            }
        }
        
        return allReferences
    }
    
    func findUnusedAssets(index: AssetIndex, projectPath: String) -> [UnusedAsset] {
        var unusedAssets: [UnusedAsset] = []
        
        // Parse SwiftGen to get enum mappings (asset -> enum path)
        let swiftGenAssets = (try? swiftGenParser.parseSwiftGenAssets(at: projectPath)) ?? []
        
        // Create lookup: asset name -> SwiftGen enum path
        var assetToEnumPath: [String: String] = [:]
        for swiftGenAsset in swiftGenAssets {
            assetToEnumPath[swiftGenAsset.assetName] = swiftGenAsset.enumPath
        }
        
        for asset in index.assets {
            var isUsed = false
            
            // Check if this asset has SwiftGen enum
            if let enumPath = assetToEnumPath[asset.name] {
                // Asset is managed by SwiftGen - check if the ENUM is used
                isUsed = isSwiftGenEnumUsed(enumPath: enumPath, in: projectPath)
            } else {
                // Not managed by SwiftGen - check for direct string references
                let directUsages = findAssetUsage(assetName: asset.name, in: projectPath)
                isUsed = !directUsages.isEmpty
            }
            
            if !isUsed {
                let daysSince: Int?
                if let lastMod = asset.lastModified {
                    daysSince = Calendar.current.dateComponents([.day], from: lastMod, to: Date()).day
                } else {
                    daysSince = nil
                }
                
                var totalSize: Int64 = 0
                for (_, imagePath) in asset.scales {
                    if let attrs = try? FileManager.default.attributesOfItem(atPath: imagePath),
                       let size = attrs[.size] as? Int64 {
                        totalSize += size
                    }
                }
                
                unusedAssets.append(UnusedAsset(
                    asset: asset,
                    estimatedSize: totalSize,
                    daysSinceModified: daysSince
                ))
            }
        }
        
        return unusedAssets
    }
    
    /// Check if a SwiftGen enum is actually used in the codebase
    private func isSwiftGenEnumUsed(enumPath: String, in projectPath: String) -> Bool {
        let fileManager = FileManager.default
        let projectURL = URL(fileURLWithPath: projectPath)
        let enumerator = fileManager.enumerator(at: projectURL, includingPropertiesForKeys: nil)
        
        while let fileURL = enumerator?.nextObject() as? URL {
            let ext = fileURL.pathExtension.lowercased()
            
            if ext == "swift" {
                let usages = swiftParser.findSwiftGenEnumUsage(enumPath: enumPath, in: fileURL.path)
                if !usages.isEmpty {
                    return true  // Found usage!
                }
            }
        }
        
        return false  // Not used anywhere
    }
}
