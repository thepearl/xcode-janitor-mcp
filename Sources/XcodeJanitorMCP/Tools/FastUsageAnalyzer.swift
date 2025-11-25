import Foundation

/// Optimized usage analyzer using single-pass scanning with concurrency
actor FastUsageAnalyzer {
    private let swiftGenParser = SwiftGenParser()
    
    // Compiled regex patterns (cached)
    private static let assetPatterns: [NSRegularExpression] = {
        let patterns = [
            #"UIImage\(named:\s*"([^"]+)"\)"#,
            #"UIImage\(named:\s*'([^']+)'\)"#,
            #"NSImage\(named:\s*"([^"]+)"\)"#,
            #"NSImage\(named:\s*'([^']+)'\)"#,
            #"Image\("([^"]+)"\)"#,
            #"Image\('([^']+)'\)"#,
            #"UIColor\(named:\s*"([^"]+)"\)"#,
            #"NSColor\(named:\s*"([^"]+)"\)"#,
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0) }
    }()
    
    private static let ignoredDirectories: Set<String> = [
        ".build", "Pods", "DerivedData", ".git", "Carthage",
        "build", "xcuserdata", ".swiftpm", "node_modules"
    ]
    
    /// Build usage map in a single pass with parallel processing
    func buildUsageMap(projectPath: String) async -> [String: [UsageReference]] {
        // Collect files synchronously first (fast)
        let swiftFiles = await Task.detached {
            return self.collectSwiftFiles(at: projectPath)
        }.value
        
        fputs("Found \(swiftFiles.count) Swift files to analyze\n", stderr)
        
        // Process files in parallel batches
        let batchSize = 100
        var allReferences: [[String: [UsageReference]]] = []
        
        for i in stride(from: 0, to: swiftFiles.count, by: batchSize) {
            let endIndex = min(i + batchSize, swiftFiles.count)
            let batch = Array(swiftFiles[i..<endIndex])
            
            let batchResults = await withTaskGroup(of: [String: [UsageReference]].self) { group in
                for fileURL in batch {
                    group.addTask {
                        return self.scanFile(fileURL.path)
                    }
                }
                
                var results: [[String: [UsageReference]]] = []
                for await result in group {
                    results.append(result)
                }
                return results
            }
            
            allReferences.append(contentsOf: batchResults)
            
            if i % 500 == 0 {
                fputs("Processed \(min(i + batchSize, swiftFiles.count))/\(swiftFiles.count) files\n", stderr)
            }
        }
        
        // Merge all results
        var usageMap: [String: [UsageReference]] = [:]
        for fileResults in allReferences {
            for (assetName, refs) in fileResults {
                usageMap[assetName, default: []].append(contentsOf: refs)
            }
        }
        
        fputs("Built usage map with \(usageMap.count) unique assets referenced\n", stderr)
        return usageMap
    }
    
    /// Collect Swift files (synchronous, fast)
    nonisolated private func collectSwiftFiles(at projectPath: String) -> [URL] {
        let fileManager = FileManager.default
        let projectURL = URL(fileURLWithPath: projectPath)
        var swiftFiles: [URL] = []
        
        if let enumerator = fileManager.enumerator(at: projectURL, includingPropertiesForKeys: [.isDirectoryKey]) {
            for case let fileURL as URL in enumerator {
                // Skip ignored directories
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey]),
                   resourceValues.isDirectory == true {
                    let dirName = fileURL.lastPathComponent
                    if Self.ignoredDirectories.contains(dirName) {
                        enumerator.skipDescendants()
                        continue
                    }
                }
                
                if fileURL.pathExtension.lowercased() == "swift" {
                    swiftFiles.append(fileURL)
                }
            }
        }
        
        return swiftFiles
    }
    
    /// Scan a single file and return all asset references found
    nonisolated private func scanFile(_ filePath: String) -> [String: [UsageReference]] {
        guard let content = try? String(contentsOfFile: filePath) else {
            return [:]
        }
        
        var results: [String: [UsageReference]] = [:]
        let lines = content.components(separatedBy: .newlines)
        
        for (lineNumber, line) in lines.enumerated() {
            for regex in Self.assetPatterns {
                let range = NSRange(line.startIndex..., in: line)
                let matches = regex.matches(in: line, range: range)
                
                for match in matches {
                    if match.numberOfRanges > 1 {
                        let assetRange = match.range(at: 1)
                        if let swiftRange = Range(assetRange, in: line) {
                            let assetName = String(line[swiftRange])
                            
                            let ref = UsageReference(
                                asset: assetName,
                                file: filePath,
                                line: lineNumber + 1,
                                context: line.trimmingCharacters(in: .whitespaces),
                                type: .swift
                            )
                            
                            results[assetName, default: []].append(ref)
                        }
                    }
                }
            }
        }
        
        return results
    }
    
    /// Fast unused asset detection using pre-built usage map
    func findUnusedAssets(index: AssetIndex, projectPath: String) async -> [UnusedAsset] {
        fputs("Building usage map (single-pass scan)...\n", stderr)
        let usageMap = await buildUsageMap(projectPath: projectPath)
        
        // Get SwiftGen managed assets
        let swiftGenAssets = (try? swiftGenParser.parseSwiftGenAssets(at: projectPath)) ?? []
        let swiftGenAssetNames = Set(swiftGenAssets.map { $0.assetName })
        
        fputs("Checking \(index.assets.count) assets against usage map...\n", stderr)
        
        var unusedAssets: [UnusedAsset] = []
        
        for asset in index.assets {
            let isUsed: Bool
            
            if swiftGenAssetNames.contains(asset.name) {
                // SwiftGen managed - for now mark as used
                // TODO: Check enum usage in future optimization
                isUsed = true
            } else {
                // Check direct string reference
                isUsed = usageMap[asset.name] != nil
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
        
        fputs("Found \(unusedAssets.count) unused assets\n", stderr)
        return unusedAssets
    }
}
