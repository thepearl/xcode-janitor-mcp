// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "XcodeJanitorMCP",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.2.0")
    ],
    targets: [
        .executableTarget(
            name: "XcodeJanitorMCP",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk")
            ]
        ),
        .testTarget(
            name: "XcodeJanitorMCPTests",
            dependencies: ["XcodeJanitorMCP"]
        )
    ]
)
