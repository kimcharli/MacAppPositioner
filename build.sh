#!/bin/bash

# Mac App Positioner - Command Line Build Script
# Compiles Swift source files into a command-line executable

set -e  # Exit on any error

echo "🏗️  Building Mac App Positioner..."

# Check if Swift compiler is available
if ! command -v swiftc &> /dev/null; then
    echo "❌ Error: Swift compiler (swiftc) not found"
    echo "   Please install Xcode Command Line Tools: xcode-select --install"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p MacAppPositioner

# Compile the application
swiftc -o MacAppPositioner/MacAppPositioner \
    MacAppPositioner/Source/main.swift \
    MacAppPositioner/Source/WindowManager.swift \
    MacAppPositioner/Source/ConfigManager.swift \
    MacAppPositioner/Source/ProfileManager.swift \
    MacAppPositioner/Source/CoordinateManager.swift \
    -framework AppKit

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "   Run with: ./MacAppPositioner/MacAppPositioner <command>"
    echo "   Examples:"
    echo "     ./MacAppPositioner/MacAppPositioner detect"
    echo "     ./MacAppPositioner/MacAppPositioner apply office"
else
    echo "❌ Build failed"
    exit 1
fi
