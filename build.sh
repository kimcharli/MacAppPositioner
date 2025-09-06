#!/bin/bash

# Mac App Positioner - Command Line Build Script
# Compiles Swift source files into a command-line executable

set -e  # Exit on any error

echo "🏗️  Building Mac App Positioner with Canonical Coordinate System..."

# Check if Swift compiler is available
if ! command -v swiftc &> /dev/null; then
    echo "❌ Error: Swift compiler (swiftc) not found"
    echo "   Please install Xcode Command Line Tools: xcode-select --install"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p MacAppPositioner

# Compile the application with Canonical Coordinate System
swiftc -o MacAppPositioner/MacAppPositioner \
    MacAppPositioner/CLI/main.swift \
    MacAppPositioner/Shared/ConfigManager.swift \
    MacAppPositioner/Shared/CanonicalProfileManager.swift \
    MacAppPositioner/Shared/CanonicalCoordinateManager.swift \
    -framework AppKit

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "   Run with: ./MacAppPositioner/MacAppPositioner <command>"
    echo "   Examples:"
    echo "     ./MacAppPositioner/MacAppPositioner detect"
    echo "     ./MacAppPositioner/MacAppPositioner apply office"
    
    # Optional: Run coordinate system validation tests
    echo ""
    echo "💡 Tip: Run './test_all.sh' to validate coordinate system before using"
else
    echo "❌ Build failed"
    exit 1
fi
