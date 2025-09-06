#!/bin/bash

# Mac App Positioner - Canonical Coordinate System Build Script
# Builds the application with unified coordinate system architecture

set -e  # Exit on any error

echo "🎯 Building Mac App Positioner with Canonical Coordinate System..."

# Check if Swift compiler is available
if ! command -v swiftc &> /dev/null; then
    echo "❌ Error: Swift compiler (swiftc) not found"
    echo "   Please install Xcode Command Line Tools: xcode-select --install"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p MacAppPositioner

echo "📐 Compiling with unified Quartz coordinate system..."

# Compile the CLI application with canonical coordinate system
swiftc -o MacAppPositioner/MacAppPositionerCanonical \
    MacAppPositioner/CLI/CanonicalMain.swift \
    MacAppPositioner/Shared/ConfigManager.swift \
    MacAppPositioner/Shared/CanonicalCoordinateManager.swift \
    MacAppPositioner/Shared/CanonicalProfileManager.swift \
    -framework AppKit \
    -framework Foundation

if [ $? -eq 0 ]; then
    echo "✅ Canonical coordinate system build successful!"
    echo ""
    echo "🎯 Features:"
    echo "   • Single canonical coordinate system (Quartz - top-left origin)"
    echo "   • Translation isolated to API boundaries"
    echo "   • No coordinate system mixing or guessing"
    echo "   • Comprehensive debugging output"
    echo ""
    echo "🚀 Usage:"
    echo "   ./MacAppPositioner/MacAppPositionerCanonical detect"
    echo "   ./MacAppPositioner/MacAppPositionerCanonical apply home"
    echo "   ./MacAppPositioner/MacAppPositionerCanonical test-coordinates"
    echo ""
    echo "🔧 Testing:"
    echo "   swift test_canonical_coordinates.swift"
    echo "   ./MacAppPositioner/MacAppPositionerCanonical test-coordinates"
else
    echo "❌ Build failed"
    exit 1
fi