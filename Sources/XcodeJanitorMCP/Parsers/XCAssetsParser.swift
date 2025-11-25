import Foundation

#if canImport(AppKit)
import AppKit
#endif

class XCAssetsParser {
    
    func parseAssetCatalog(at path: String) throws -> [Asset] {
        var assets: [Asset] = []
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: path) else {
            throw ParserError.catalogNotFound(path)
        }
        
        let catalogURL = URL(fileURLWithPath: path)
        let catalogName = catalogURL.lastPathComponent
        
        let enumerator = fileManager.enumerator(at: catalogURL, includingPropertiesForKeys: [.isDirectoryKey])
        
        while let fileURL = enumerator?.nextObject() as? URL {
            let fileName = fileURL.lastPathComponent
            
            if fileName.hasSuffix(".imageset") {
                if let asset = try? parseImageSet(at: fileURL, catalog: catalogName) {
                    assets.append(asset)
                }
            } else if fileName.hasSuffix(".colorset") {
                if let asset = try? parseColorSet(at: fileURL, catalog: catalogName) {
                    assets.append(asset)
                }
            } else if fileName.hasSuffix(".appiconset") {
                if let asset = try? parseAppIconSet(at: fileURL, catalog: catalogName) {
                    assets.append(asset)
                }
            }
        }
        
        return assets
    }
    
    private func parseImageSet(at url: URL, catalog: String) throws -> Asset {
        let assetName = url.deletingPathExtension().lastPathComponent
        let contentsURL = url.appendingPathComponent("Contents.json")
        
        let data = try Data(contentsOf: contentsURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        var scales: [String: String] = [:]
        var metadata = AssetMetadata()
        
        if let images = json?["images"] as? [[String: Any]] {
            for image in images {
                if let filename = image["filename"] as? String,
                   let scale = image["scale"] as? String {
                    let imagePath = url.appendingPathComponent(filename).path
                    scales[scale] = imagePath
                    
                    // Get image metadata for the first available scale
                    if metadata.width == nil {
                        metadata = extractImageMetadata(from: imagePath)
                    }
                }
            }
        }
        
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let lastModified = attributes[.modificationDate] as? Date
        
        return Asset(
            name: assetName,
            type: .imageset,
            catalog: catalog,
            path: url.path,
            scales: scales,
            metadata: metadata,
            lastModified: lastModified
        )
    }
    
    private func parseColorSet(at url: URL, catalog: String) throws -> Asset {
        let assetName = url.deletingPathExtension().lastPathComponent
        
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let lastModified = attributes[.modificationDate] as? Date
        
        return Asset(
            name: assetName,
            type: .colorset,
            catalog: catalog,
            path: url.path,
            scales: [:],
            metadata: AssetMetadata(),
            lastModified: lastModified
        )
    }
    
    private func parseAppIconSet(at url: URL, catalog: String) throws -> Asset {
        let assetName = url.deletingPathExtension().lastPathComponent
        let contentsURL = url.appendingPathComponent("Contents.json")
        
        let data = try Data(contentsOf: contentsURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        var scales: [String: String] = [:]
        
        if let images = json?["images"] as? [[String: Any]] {
            for image in images {
                if let filename = image["filename"] as? String,
                   let size = image["size"] as? String {
                    let imagePath = url.appendingPathComponent(filename).path
                    scales[size] = imagePath
                }
            }
        }
        
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let lastModified = attributes[.modificationDate] as? Date
        
        return Asset(
            name: assetName,
            type: .appiconset,
            catalog: catalog,
            path: url.path,
            scales: scales,
            metadata: AssetMetadata(),
            lastModified: lastModified
        )
    }
    
    private func extractImageMetadata(from path: String) -> AssetMetadata {
        var metadata = AssetMetadata()
        
        #if canImport(AppKit)
        if let image = NSImage(contentsOfFile: path) {
            metadata.width = Int(image.size.width)
            metadata.height = Int(image.size.height)
        }
        #endif
        
        if let attributes = try? FileManager.default.attributesOfItem(atPath: path),
           let size = attributes[.size] as? Int64 {
            metadata.fileSize = size
        }
        
        let pathExtension = URL(fileURLWithPath: path).pathExtension.lowercased()
        metadata.format = pathExtension
        
        return metadata
    }
}

enum ParserError: Error {
    case catalogNotFound(String)
    case invalidFormat(String)
}
