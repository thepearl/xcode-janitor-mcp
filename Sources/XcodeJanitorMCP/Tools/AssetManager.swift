import Foundation

class AssetManager {
    
    func deleteAsset(_ asset: Asset, dryRun: Bool = false, createBackup: Bool = true) -> DeletionResult {
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: asset.path) else {
            return DeletionResult(
                asset: asset.name,
                success: false,
                backupPath: nil,
                sizeFreed: 0,
                error: "Asset not found at path: \(asset.path)"
            )
        }
        
        var totalSize: Int64 = 0
        var backupPath: String?
        
        // Calculate total size
        if let enumerator = fileManager.enumerator(atPath: asset.path) {
            while let file = enumerator.nextObject() as? String {
                let filePath = (asset.path as NSString).appendingPathComponent(file)
                if let attrs = try? fileManager.attributesOfItem(atPath: filePath),
                   let size = attrs[.size] as? Int64 {
                    totalSize += size
                }
            }
        }
        
        // Dry run - don't actually delete
        if dryRun {
            return DeletionResult(
                asset: asset.name,
                success: true,
                backupPath: nil,
                sizeFreed: totalSize,
                error: nil
            )
        }
        
        // Create backup if requested
        if createBackup {
            let backupDir = (asset.catalog as NSString).appendingPathComponent(".janitor-backup")
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let backupDest = (backupDir as NSString).appendingPathComponent("\(asset.name)-\(timestamp)")
            
            do {
                try fileManager.createDirectory(atPath: backupDir, withIntermediateDirectories: true)
                try fileManager.copyItem(atPath: asset.path, toPath: backupDest)
                backupPath = backupDest
            } catch {
                return DeletionResult(
                    asset: asset.name,
                    success: false,
                    backupPath: nil,
                    sizeFreed: 0,
                    error: "Failed to create backup: \(error.localizedDescription)"
                )
            }
        }
        
        // Delete the asset
        do {
            try fileManager.removeItem(atPath: asset.path)
            return DeletionResult(
                asset: asset.name,
                success: true,
                backupPath: backupPath,
                sizeFreed: totalSize,
                error: nil
            )
        } catch {
            return DeletionResult(
                asset: asset.name,
                success: false,
                backupPath: backupPath,
                sizeFreed: 0,
                error: "Failed to delete: \(error.localizedDescription)"
            )
        }
    }
    
    func checkMissingScales(asset: Asset) -> MissingScaleReport? {
        guard asset.type == .imageset else { return nil }
        
        let expectedScales = ["1x", "2x", "3x"]
        let missingScales = expectedScales.filter { asset.scales[$0] == nil }
        
        if missingScales.isEmpty {
            return nil
        }
        
        return MissingScaleReport(asset: asset, missingScales: missingScales)
    }
}
