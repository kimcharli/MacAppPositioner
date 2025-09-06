#!/bin/bash

# Quick Coordinate System Test
# Fast validation for development workflow

echo "⚡ Quick Coordinate System Test"
echo "==============================="

# Run the simple test (fastest and most reliable)
if swift test_coordinate_system_simple.swift; then
    echo -e "\n✅ Coordinate system is working correctly!"
    echo "💡 Run './test_all.sh' for full test suite"
    exit 0
else
    echo -e "\n❌ Coordinate system issues detected!"
    echo "🔧 Run './test_all.sh' for detailed diagnostics"
    exit 1
fi