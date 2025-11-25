import Foundation

class AssetIndexer {
    private let parser = XCAssetsParser()
    
    func indexProject(at path: String) throws -> AssetIndex {
        let fileManager = FileManager.default
        var allAssets: [Asset] = []
        var catalogPaths: [String] = []
        
        let projectURL = URL(fileURLWithPath: path)
        
        guard fileManager.fileExists(atPath: path) else {
            throw IndexerError.projectNotFound(path)
        }
        
        // Find all .xcassets directories
        let enumerator = fileManager.enumerator(at: projectURL, includingPropertiesForKeys: [.isDirectoryKey])
        
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.pathExtension == "xcassets" {
                catalogPaths.append(fileURL.path)
                
                do {
                    let assets = try parser.parseAssetCatalog(at: fileURL.path)
                    allAssets.append(contentsOf: assets)
                } catch {
                    print("Warning: Failed to parse catalog at \(fileURL.path): \(error)")
                }
            }
        }
        
        return AssetIndex(
            catalogs: catalogPaths,
            assets: allAssets,
            lastIndexed: Date(),
            projectPath: path
        )
    }
    
    func findAssets(matching pattern: String, in index: AssetIndex) -> [Asset] {
        let wildcardPattern = pattern.replacingOccurrences(of: "*", with: ".*")
        guard let regex = try? NSRegularExpression(pattern: wildcardPattern, options: .caseInsensitive) else {
            return []
        }
        
        return index.assets.filter { asset in
            let range = NSRange(asset.name.startIndex..., in: asset.name)
            return regex.firstMatch(in: asset.name, range: range) != nil
        }
    }
}

enum IndexerError: Error {
    case projectNotFound(String)
}
