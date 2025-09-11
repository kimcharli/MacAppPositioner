#!/bin/bash

# Build All Script for Mac App Positioner
# Builds both CLI and GUI applications with proper app bundle structure

set -e

echo "===================="
echo "Mac App Positioner"
echo "Full Build Process"
echo "===================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Build CLI
echo -e "${YELLOW}Building CLI tool...${NC}"
./Scripts/build.sh
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ CLI build successful${NC}"
else
    echo -e "${RED}❌ CLI build failed${NC}"
    exit 1
fi

echo ""

# Build GUI
echo -e "${YELLOW}Building GUI app...${NC}"
./Scripts/build-gui.sh
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ GUI build successful${NC}"
else
    echo -e "${RED}❌ GUI build failed${NC}"
    exit 1
fi

echo ""

# Create app bundle for GUI
echo -e "${YELLOW}Creating app bundle...${NC}"
APP_NAME="MacAppPositionerGUI"
APP_PATH="dist/${APP_NAME}.app"

# Remove old app bundle if exists
if [ -d "$APP_PATH" ]; then
    rm -rf "$APP_PATH"
fi

# Create app bundle structure
mkdir -p "${APP_PATH}/Contents/MacOS"
mkdir -p "${APP_PATH}/Contents/Resources"

# Copy binary
cp "dist/${APP_NAME}" "${APP_PATH}/Contents/MacOS/"

# Copy Info.plist if it exists
if [ -f "Info.plist" ]; then
    cp "Info.plist" "${APP_PATH}/Contents/"
    echo -e "${GREEN}✅ App bundle created${NC}"
else
    echo -e "${YELLOW}⚠️  Info.plist not found, app bundle incomplete${NC}"
fi

echo ""

# Display results
echo -e "${GREEN}===================="
echo "Build Complete!"
echo "====================${NC}"
echo ""
echo "Built artifacts:"
echo "  • CLI tool: dist/MacAppPositioner"
echo "  • GUI app:  dist/MacAppPositionerGUI.app"
echo ""
echo "Installation:"
echo "  • CLI: Add dist/ to PATH or copy to /usr/local/bin"
echo "  • GUI: Copy dist/MacAppPositionerGUI.app to /Applications"
echo ""
echo "Configuration:"
echo "  • Create config at: ~/.config/mac-app-positioner/config.json"
echo "  • Or use: ~/Library/Application Support/MacAppPositioner/config.json"
echo ""
echo "First run:"
echo "  • Grant Accessibility permissions when prompted"
echo "  • GUI app will appear as monitor icon (🖥️) in menu bar"