import XCTest
@testable import XcodeJanitorMCP

final class AssetIndexerTests: XCTestCase {
    var tempDir: URL!
    var indexer: AssetIndexer!

    override func setUp() {
        super.setUp()
        indexer = AssetIndexer()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testIndexEmptyProject() throws {
        // Given: Empty project directory
        let projectPath = tempDir.path

        // When: Indexing the project
        let index = try indexer.indexProject(at: projectPath)

        // Then: Should return empty index
        XCTAssertEqual(index.catalogs.count, 0)
        XCTAssertEqual(index.assets.count, 0)
        XCTAssertEqual(index.projectPath, projectPath)
    }

    func testIndexProjectWithAssetCatalog() throws {
        // Given: Project with one asset catalog
        let catalogURL = tempDir.appendingPathComponent("Assets.xcassets")
        try FileManager.default.createDirectory(at: catalogURL, withIntermediateDirectories: true)

        let contentsJSON = """
        {
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }
        """
        try contentsJSON.write(to: catalogURL.appendingPathComponent("Contents.json"),
                              atomically: true,
                              encoding: .utf8)

        // Create test imageset
        let imagesetURL = catalogURL.appendingPathComponent("TestImage.imageset")
        try FileManager.default.createDirectory(at: imagesetURL, withIntermediateDirectories: true)

        let imagesetJSON = """
        {
          "images" : [
            {
              "filename" : "test.png",
              "idiom" : "universal",
              "scale" : "1x"
            }
          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }
        """
        try imagesetJSON.write(to: imagesetURL.appendingPathComponent("Contents.json"),
                              atomically: true,
                              encoding: .utf8)
        try "test".write(to: imagesetURL.appendingPathComponent("test.png"),
                        atomically: true,
                        encoding: .utf8)

        // When: Indexing the project
        let index = try indexer.indexProject(at: tempDir.path)

        // Then: Should find the catalog and asset
        XCTAssertEqual(index.catalogs.count, 1)
        XCTAssertTrue(index.catalogs.first?.contains("Assets.xcassets") ?? false)
        XCTAssertEqual(index.assets.count, 1)
        XCTAssertEqual(index.assets.first?.name, "TestImage")
        XCTAssertEqual(index.assets.first?.type, .imageset)
    }

    func testFindAssetsMatchingPattern() throws {
        // Given: Index with multiple assets
        let catalogURL = tempDir.appendingPathComponent("Assets.xcassets")
        try FileManager.default.createDirectory(at: catalogURL, withIntermediateDirectories: true)

        let contentsJSON = """
        {
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }
        """
        try contentsJSON.write(to: catalogURL.appendingPathComponent("Contents.json"),
                              atomically: true,
                              encoding: .utf8)

        // Create multiple imagesets
        for name in ["AppIcon", "LaunchImage", "TestImage"] {
            let imagesetURL = catalogURL.appendingPathComponent("\(name).imageset")
            try FileManager.default.createDirectory(at: imagesetURL, withIntermediateDirectories: true)

            let imagesetJSON = """
            {
              "images" : [
                {
                  "filename" : "test.png",
                  "idiom" : "universal",
                  "scale" : "1x"
                }
              ],
              "info" : {
                "author" : "xcode",
                "version" : 1
              }
            }
            """
            try imagesetJSON.write(to: imagesetURL.appendingPathComponent("Contents.json"),
                                  atomically: true,
                                  encoding: .utf8)
        }

        let index = try indexer.indexProject(at: tempDir.path)

        // When: Finding assets matching pattern
        let matches = indexer.findAssets(matching: "*Image", in: index)

        // Then: Should find matching assets
        XCTAssertEqual(matches.count, 2)
        let names = Set(matches.map { $0.name })
        XCTAssertTrue(names.contains("LaunchImage"))
        XCTAssertTrue(names.contains("TestImage"))
        XCTAssertFalse(names.contains("AppIcon"))
    }
}
