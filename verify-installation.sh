#!/bin/bash
set -e

echo "🧹 Xcode Janitor MCP - Installation Verification"
echo "================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running in project directory
if [ ! -f "Package.swift" ]; then
    echo -e "${RED}❌ Error: Package.swift not found. Please run this script from the project root.${NC}"
    exit 1
fi

echo "Step 1: Building release binary..."
if swift build -c release 2>&1 | grep -q "Build complete"; then
    echo -e "${GREEN}✅ Build successful${NC}"
else
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

# Check if binary exists
BINARY_PATH=".build/release/XcodeJanitorMCP"
if [ ! -f "$BINARY_PATH" ]; then
    echo -e "${RED}❌ Binary not found at $BINARY_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Binary found at $BINARY_PATH${NC}"

# Check if binary is executable
if [ ! -x "$BINARY_PATH" ]; then
    echo -e "${YELLOW}⚠️  Binary is not executable, fixing...${NC}"
    chmod +x "$BINARY_PATH"
fi

# Test MCP server initialization
echo ""
echo "Step 2: Testing MCP server initialization..."
INIT_REQUEST='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'

if echo "$INIT_REQUEST" | "$BINARY_PATH" 2>&1 | grep -q '"result"'; then
    echo -e "${GREEN}✅ MCP server responds to initialize${NC}"
else
    echo -e "${RED}❌ MCP server failed to initialize${NC}"
    exit 1
fi

# Test tools/list endpoint
echo ""
echo "Step 3: Testing tools/list endpoint..."
LIST_REQUEST='{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'

if echo "$LIST_REQUEST" | "$BINARY_PATH" 2>&1 | grep -q '"tools"'; then
    echo -e "${GREEN}✅ MCP server lists tools correctly${NC}"

    # Count tools
    TOOL_COUNT=$(echo "$LIST_REQUEST" | "$BINARY_PATH" 2>&1 | grep -o '"name"' | wc -l | tr -d ' ')
    echo -e "${GREEN}   Found $TOOL_COUNT tools${NC}"
else
    echo -e "${RED}❌ MCP server failed to list tools${NC}"
    exit 1
fi

# Run unit tests
echo ""
echo "Step 4: Running unit tests..."
if swift test 2>&1 | grep -q "All tests' passed"; then
    echo -e "${GREEN}✅ All unit tests passed${NC}"
else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi

# Print installation instructions
echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}✨ Installation Verified Successfully! ✨${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "To use with Claude Code (VS Code):"
echo "1. Add to your VS Code settings:"
echo ""
echo '   "claude.mcpServers": {'
echo '     "xcode-janitor": {'
echo "       \"command\": \"$(pwd)/$BINARY_PATH\""
echo '     }'
echo '   }'
echo ""
echo "2. Restart Claude Code extension"
echo ""
echo "To use with Claude CLI:"
echo ""
echo "   claude mcp add xcode-janitor $(pwd)/$BINARY_PATH"
echo "   claude mcp list"
echo ""
echo -e "${GREEN}Happy cleaning! 🎉${NC}"
