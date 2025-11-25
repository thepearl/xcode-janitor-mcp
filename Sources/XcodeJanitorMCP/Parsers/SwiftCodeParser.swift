import Foundation

class SwiftCodeParser {
    
    func findAssetReferences(in filePath: String) -> [UsageReference] {
        guard let content = try? String(contentsOfFile: filePath) else {
            return []
        }
        
        var references: [UsageReference] = []
        let lines = content.components(separatedBy: .newlines)
        
        // Patterns for Swift asset usage
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
        
        for (lineNumber, line) in lines.enumerated() {
            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let range = NSRange(line.startIndex..., in: line)
                    let matches = regex.matches(in: line, range: range)
                    
                    for match in matches {
                        if match.numberOfRanges > 1 {
                            let assetRange = match.range(at: 1)
                            if let swiftRange = Range(assetRange, in: line) {
                                let assetName = String(line[swiftRange])
                                
                                references.append(UsageReference(
                                    asset: assetName,
                                    file: filePath,
                                    line: lineNumber + 1,
                                    context: line.trimmingCharacters(in: .whitespaces),
                                    type: .swift
                                ))
                            }
                        }
                    }
                }
            }
        }
        
        return references
    }
    
    /// Find SwiftGen enum usage patterns (e.g., Asset.euroSymbol, ColorName.primary)
    func findSwiftGenEnumUsage(enumPath: String, in filePath: String) -> [UsageReference] {
        guard let content = try? String(contentsOfFile: filePath) else {
            return []
        }
        
        var references: [UsageReference] = []
        let lines = content.components(separatedBy: .newlines)
        
        // Escape dots in enum path for regex
        let escapedPath = NSRegularExpression.escapedPattern(for: enumPath)
        
        // Patterns to match SwiftGen usage:
        // - Asset.euroSymbol
        // - Asset.euroSymbol.image
        // - Asset.euroSymbol.color
        // - ColorName.primary.color
        let patterns = [
            escapedPath + #"(?:\.image|\.color|\.name)?"#,  // Direct usage
            escapedPath + #"\s*\."#,  // Chained access
        ]
        
        for (lineNumber, line) in lines.enumerated() {
            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let range = NSRange(line.startIndex..., in: line)
                    if regex.firstMatch(in: line, range: range) != nil {
                        references.append(UsageReference(
                            asset: enumPath,
                            file: filePath,
                            line: lineNumber + 1,
                            context: line.trimmingCharacters(in: .whitespaces),
                            type: .swift
                        ))
                        break  // Only count once per line
                    }
                }
            }
        }
        
        return references
    }
}
