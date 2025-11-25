import Foundation

struct SwiftGenConfig: Codable {
    struct XCAssets: Codable {
        let inputs: [String]?
        let outputs: [Output]?
        
        struct Output: Codable {
            let templateName: String?
            let output: String?
        }
    }
    
    let xcassets: XCAssets?
}

struct SwiftGenAsset {
    let assetName: String
    let enumPath: String  // e.g., "Asset.euroSymbol"
    let catalog: String
}

class SwiftGenParser {
    
    /// Parse SwiftGen config and generated files to get actual enum mappings
    func parseSwiftGenAssets(at projectPath: String) throws -> [SwiftGenAsset] {
        var swiftGenAssets: [SwiftGenAsset] = []
        
        // Find SwiftGen config
        guard let configPath = findSwiftGenConfig(at: projectPath) else {
            return []
        }
        
        // Parse config to find output files
        let outputFiles = try parseConfigForOutputs(at: configPath, projectPath: projectPath)
        
        // Parse each generated file to extract enum mappings
        for outputFile in outputFiles {
            let assets = try parseGeneratedFile(at: outputFile.path, catalog: outputFile.catalog)
            swiftGenAssets.append(contentsOf: assets)
        }
        
        return swiftGenAssets
    }
    
    private func findSwiftGenConfig(at projectPath: String) -> String? {
        let fileManager = FileManager.default
        let configFiles = [
            "swiftgen.yml",
            "swiftgen.yaml",
            ".swiftgen.yml",
            "swiftgen.config.yml"
        ]
        
        for configFile in configFiles {
            let configPath = (projectPath as NSString).appendingPathComponent(configFile)
            if fileManager.fileExists(atPath: configPath) {
                return configPath
            }
        }
        return nil
    }
    
    private struct OutputFile {
        let path: String
        let catalog: String
    }
    
    private func parseConfigForOutputs(at configPath: String, projectPath: String) throws -> [OutputFile] {
        guard let content = try? String(contentsOfFile: configPath) else {
            throw SwiftGenError.configNotFound(configPath)
        }
        
        var outputs: [OutputFile] = []
        let lines = content.components(separatedBy: .newlines)
        
        var currentInputs: String?
        var currentOutputDir: String?
        var inXCAssetsSection = false
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Find output_dir (global or in xcassets section)
            if trimmed.starts(with: "output_dir:") {
                currentOutputDir = trimmed.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
            }
            
            // Check for xcassets section
            if trimmed.starts(with: "xcassets:") {
                inXCAssetsSection = true
                continue
            }
            
            // Leave xcassets section
            if inXCAssetsSection && !line.starts(with: " ") && !line.starts(with: "\t") && !trimmed.isEmpty && !trimmed.starts(with: "-") {
                inXCAssetsSection = false
            }
            
            // Parse inputs
            if inXCAssetsSection && trimmed.starts(with: "inputs:") {
                let inputPath = trimmed.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                if !inputPath.isEmpty {
                    currentInputs = inputPath
                }
            }
            
            if inXCAssetsSection && trimmed.starts(with: "- inputs:") {
                currentInputs = trimmed.dropFirst(9).trimmingCharacters(in: .whitespaces)
            }
            
            // Parse output
            if inXCAssetsSection && trimmed.starts(with: "output:") {
                let outputPath = trimmed.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                if !outputPath.isEmpty, let catalog = currentInputs {
                    // Resolve full path
                    var fullPath: String
                    if let outputDir = currentOutputDir {
                        let resolvedDir = resolveSwiftGenPath(outputDir, relativeTo: projectPath)
                        fullPath = (resolvedDir as NSString).appendingPathComponent(outputPath)
                    } else {
                        fullPath = resolveSwiftGenPath(outputPath, relativeTo: projectPath)
                    }
                    
                    outputs.append(OutputFile(path: fullPath, catalog: catalog))
                }
            }
        }
        
        return outputs
    }
    
    private func parseGeneratedFile(at path: String, catalog: String) throws -> [SwiftGenAsset] {
        guard let content = try? String(contentsOfFile: path) else {
            return []
        }
        
        var assets: [SwiftGenAsset] = []
        let lines = content.components(separatedBy: .newlines)
        
        // Look for patterns like:
        // internal static let euroSymbol = ImageAsset(name: "euro_symbol")
        // internal static let icAddCarte = ImageAsset(name: "ic_add_carte")
        
        let pattern = #"static\s+let\s+(\w+)\s+=\s+(?:Image|Color)Asset\(name:\s*"([^"]+)"\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        
        for line in lines {
            let range = NSRange(line.startIndex..., in: line)
            if let match = regex.firstMatch(in: line, range: range) {
                if match.numberOfRanges >= 3 {
                    if let enumNameRange = Range(match.range(at: 1), in: line),
                       let assetNameRange = Range(match.range(at: 2), in: line) {
                        let enumName = String(line[enumNameRange])
                        let assetName = String(line[assetNameRange])
                        
                        // Determine enum path (Asset.enumName or ColorName.enumName, etc.)
                        let enumPath = determineEnumPath(from: content, enumName: enumName)
                        
                        assets.append(SwiftGenAsset(
                            assetName: assetName,
                            enumPath: enumPath,
                            catalog: catalog
                        ))
                    }
                }
            }
        }
        
        return assets
    }
    
    private func determineEnumPath(from content: String, enumName: String) -> String {
        // Look for enum declaration like "internal enum Asset" or "internal enum ColorName"
        let enumPattern = #"enum\s+(\w+)\s*\{"#
        if let regex = try? NSRegularExpression(pattern: enumPattern),
           let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
           let range = Range(match.range(at: 1), in: content) {
            let parentEnum = String(content[range])
            return "\(parentEnum).\(enumName)"
        }
        
        return "Asset.\(enumName)"  // Default fallback
    }
    
    private func resolveSwiftGenPath(_ path: String, relativeTo projectPath: String) -> String {
        if path.hasPrefix("/") {
            return path
        }
        
        var cleanPath = path
        if cleanPath.hasPrefix("./") {
            cleanPath = String(cleanPath.dropFirst(2))
        }
        
        return (projectPath as NSString).appendingPathComponent(cleanPath)
    }
}

enum SwiftGenError: Error {
    case configNotFound(String)
    case invalidYAML(String)
}
