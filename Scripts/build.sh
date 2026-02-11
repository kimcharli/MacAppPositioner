#!/bin/bash

# Mac App Positioner - Command Line Build Script
# Compiles Swift source files into a command-line executable

set -e  # Exit on any error

echo "🏗️  Building Mac App Positioner with Native Cocoa Coordinate System..."

# Check if Swift compiler is available
if ! command -v swiftc &> /dev/null; then
    echo "❌ Error: Swift compiler (swiftc) not found"
    echo "   Please install Xcode Command Line Tools: xcode-select --install"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p dist

# Compile the application with Native Cocoa Coordinate System
swiftc -o dist/MacAppPositioner \
    MacAppPositioner/CLI/CocoaMain.swift \
    MacAppPositioner/Shared/ConfigManager.swift \
    MacAppPositioner/Shared/CocoaCoordinateManager.swift \
    MacAppPositioner/Shared/CocoaProfileManager.swift \
    MacAppPositioner/Shared/AppUtils.swift \
    MacAppPositioner/Shared/PlanModels.swift \
    -framework AppKit -framework CoreGraphics

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "   Run with: ./dist/MacAppPositioner <command>"
    echo "   Examples:"
    echo "     ./dist/MacAppPositioner detect"
    echo "     ./dist/MacAppPositioner apply office"
    
    # Optional: Run coordinate system validation tests
    echo ""
    echo "💡 Tip: Run './Scripts/test_all.sh' to validate coordinate system before using"
else
    echo "❌ Build failed"
    exit 1
fi
