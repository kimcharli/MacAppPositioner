#!/bin/bash

# Mac App Positioner - SwiftUI GUI Build Script
# Compiles the SwiftUI application that uses shared core logic

set -e  # Exit on any error

echo "🎨 Building Mac App Positioner GUI with Canonical Coordinate System..."

# Check if Swift compiler is available
if ! command -v swiftc &> /dev/null; then
    echo "❌ Error: Swift compiler (swiftc) not found"
    echo "   Please install Xcode Command Line Tools: xcode-select --install"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p MacAppPositioner

# Compile the GUI application with canonical coordinate system
swiftc -o MacAppPositioner/MacAppPositionerGUI \
    MacAppPositioner/GUI/App.swift \
    MacAppPositioner/GUI/ContentView.swift \
    MacAppPositioner/GUI/MonitorVisualizationView.swift \
    MacAppPositioner/GUI/ProfileManagerView.swift \
    MacAppPositioner/GUI/SettingsView.swift \
    MacAppPositioner/Shared/ConfigManager.swift \
    MacAppPositioner/Shared/CanonicalCoordinateManager.swift \
    MacAppPositioner/Shared/CanonicalProfileManager.swift \
    -framework AppKit \
    -framework SwiftUI

if [ $? -eq 0 ]; then
    echo "✅ GUI Build successful!"
    echo "   Run with: ./MacAppPositioner/MacAppPositionerGUI"
    echo "   Note: GUI app will launch in window mode"
else
    echo "❌ GUI Build failed"
    exit 1
fi