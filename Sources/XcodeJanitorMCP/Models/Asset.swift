import Foundation

enum AssetType: String, Codable {
    case imageset
    case colorset
    case dataset
    case appiconset
    case launchimage
}

struct AssetScale {
    var x1: String?
    var x2: String?
    var x3: String?
}

struct AssetMetadata: Codable {
    var width: Int?
    var height: Int?
    var format: String?
    var colorSpace: String?
    var renderingMode: String?
    var fileSize: Int64?
}

struct Asset: Codable {
    let name: String
    let type: AssetType
    let catalog: String
    let path: String
    var scales: [String: String]
    var metadata: AssetMetadata
    var lastModified: Date?
}

struct AssetIndex: Codable {
    let catalogs: [String]
    let assets: [Asset]
    var totalCount: Int { assets.count }
    let lastIndexed: Date
    let projectPath: String
}

struct UsageReference: Codable {
    let asset: String
    let file: String
    let line: Int
    let context: String
    let type: UsageType
}

enum UsageType: String, Codable {
    case swift
    case objectiveC
    case xib
    case storyboard
    case json
}

struct UnusedAsset: Codable {
    let asset: Asset
    let estimatedSize: Int64
    let daysSinceModified: Int?
}

struct MissingScaleReport: Codable {
    let asset: Asset
    let missingScales: [String]
}

struct DeletionResult: Codable {
    let asset: String
    let success: Bool
    let backupPath: String?
    let sizeFreed: Int64
    let error: String?
}
