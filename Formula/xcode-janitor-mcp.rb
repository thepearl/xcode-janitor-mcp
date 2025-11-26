class XcodeJanitorMcp < Formula
  desc "MCP server for cleaning unused assets in Xcode projects"
  homepage "https://github.com/thepearl/xcode-janitor-mcp"
  url "https://github.com/thepearl/xcode-janitor-mcp/archive/refs/tags/v0.12.0.tar.gz"
  sha256 "bffcd3be0eb011405d836025b4c3658d8715dec830d3c91a3267d8be66d831e6"
  license "MIT"

  depends_on :macos
  depends_on xcode: ["14.0", :build]

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/XcodeJanitorMCP" => "xcode-janitor-mcp"
  end

  test do
    # Test that the binary runs
    output = shell_output("#{bin}/xcode-janitor-mcp 2>&1", 0)
    assert_match "Starting Xcode Janitor MCP Server", output
  end
end
