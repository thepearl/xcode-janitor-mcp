class XcodeJanitorMcp < Formula
  desc "MCP server for cleaning unused assets in Xcode projects"
  homepage "https://github.com/thepearl/xcode-janitor-mcp"
  url "https://github.com/thepearl/xcode-janitor-mcp/archive/refs/tags/v0.12.0.tar.gz"
  sha256 "bffcd3be0eb011405d836025b4c3658d8715dec830d3c91a3267d8be66d831e6"
  license "MIT"
  head "https://github.com/thepearl/xcode-janitor-mcp.git", branch: "master"

  # Bottles will be added here by brew pr-pull workflow
  # Example structure:
  # bottle do
  #   root_url "https://github.com/thepearl/xcode-janitor-mcp/releases/download/v0.12.0"
  #   sha256 cellar: :any_skip_relocation, arm64_sequoia: "..."
  #   sha256 cellar: :any_skip_relocation, arm64_sonoma: "..."
  #   sha256 cellar: :any_skip_relocation, arm64_ventura: "..."
  # end

  depends_on xcode: ["14.0", :build]
  depends_on :macos

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/XcodeJanitorMCP" => "xcode-janitor-mcp"
  end

  test do
    # Test that the binary exists and is executable
    assert_path_exists bin/"xcode-janitor-mcp"
    assert_predicate bin/"xcode-janitor-mcp", :executable?

    # Test basic MCP protocol initialization
    # The server expects JSON-RPC 2.0 initialize message on stdin
    init_msg = '{"jsonrpc":"2.0","id":1,"method":"initialize",' \
               '"params":{"protocolVersion":"2024-11-05","capabilities":{},' \
               '"clientInfo":{"name":"test","version":"1.0"}}}'
    output = pipe_output("#{bin}/xcode-janitor-mcp 2>&1", init_msg)
    assert_match(/"result"/, output)
    assert_match(/"capabilities"/, output)
  end
end
