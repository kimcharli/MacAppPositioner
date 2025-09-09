# AI Agents Guide for Mac App Positioner

This document provides guidelines for AI agents working with the Mac App Positioner codebase.

## Quick Reference - Common Commands

⚠️ **Important**: Always use the compiled binaries in the `dist/` folder, not the source files.

```bash
# ✅ CORRECT - Use compiled binaries
./dist/MacAppPositioner detect
./dist/MacAppPositioner apply office
./dist/MacAppPositionerGUI

# ❌ WRONG - Don't run source files directly
./MacAppPositioner/CLI/main.swift
./MacAppPositioner detect
```

### Build Commands

**Recommended: Use provided build scripts**
```bash
# Build CLI only
./Scripts/build.sh

# Build GUI only  
./Scripts/build-gui.sh

# Build both
./Scripts/build.sh && ./Scripts/build-gui.sh
```

**Manual build commands (if needed):**
```bash
# Build CLI only (exclude obsolete ProfileManager.swift)
swiftc -o dist/MacAppPositioner MacAppPositioner/CLI/CocoaMain.swift \
  MacAppPositioner/Shared/ConfigManager.swift \
  MacAppPositioner/Shared/WindowManager.swift \
  MacAppPositioner/Shared/CoordinateManager.swift \
  MacAppPositioner/Shared/CocoaCoordinateManager.swift \
  MacAppPositioner/Shared/CocoaProfileManager.swift \
  MacAppPositioner/Shared/AppUtils.swift \
  -framework Cocoa -framework CoreGraphics

# Build GUI only
swiftc -o dist/MacAppPositionerGUI MacAppPositioner/GUI/*.swift \
  MacAppPositioner/Shared/ConfigManager.swift \
  MacAppPositioner/Shared/WindowManager.swift \
  MacAppPositioner/Shared/CoordinateManager.swift \
  MacAppPositioner/Shared/CocoaCoordinateManager.swift \
  MacAppPositioner/Shared/CocoaProfileManager.swift \
  MacAppPositioner/Shared/AppUtils.swift \
  -framework Cocoa -framework CoreGraphics -framework SwiftUI
```

✅ **Recommended**: The build scripts are up-to-date and include all current files.

## Core Principles

-   **Dynamic Over Static:** Always favor dynamic detection of the monitor setup over hardcoded values. See the [Architecture](ARCHITECTURE.md) document for details.
-   **Terminology Consistency:** Refer to the [Terminology](TERMINOLOGY.md) document for precise definitions of terms like "Primary Monitor" and "Main Display."
-   **Coordinate System Awareness:** The application uses native Cocoa coordinates (bottom-left origin, Y increases upward). See the [Architecture](ARCHITECTURE.md) document for a detailed explanation.
-   **DRY Principles:** Use shared utilities like `AppUtils` for common operations like resolution normalization and profile loading.

## Code Architecture

The application is structured as a **native Swift macOS application** with a modular design:

### Core Components
- **CLI**: `MacAppPositioner/CLI/CocoaMain.swift` - Command-line interface
- **GUI**: `MacAppPositioner/GUI/*.swift` - SwiftUI-based graphical interface  
- **Shared**: `MacAppPositioner/Shared/*.swift` - Core logic shared between CLI and GUI

### Key Classes
- **`CocoaProfileManager`** - Profile detection and application (use this, not obsolete `ProfileManager`)
- **`CocoaCoordinateManager`** - Monitor detection and coordinate handling
- **`AppUtils`** - Shared utilities for resolution normalization and profile loading
- **`ConfigManager`** - JSON configuration loading

For a detailed explanation of the architecture, see the [Architecture](ARCHITECTURE.md) document.

## Common Pitfalls for AI Agents

### ❌ Don't Do This
```bash
# Wrong executable path
./MacAppPositioner detect

# Using obsolete classes (removed)
ProfileManager() 

# Hardcoded resolution formats
"3440.0x1440.0" 

# Duplicate utility functions
private func normalizeResolution()
```

### ✅ Do This Instead  
```bash
# Correct executable path
./dist/MacAppPositioner detect

# Use current classes
CocoaProfileManager()

# Use user-friendly format
"3440x1440"

# Use shared utilities
AppUtils.normalizeResolution()
```

### File Management
- **Active Files**: All files in `MacAppPositioner/Shared/` except removed obsolete ones
- **Removed Files**: `ProfileManager.swift` (replaced by `CocoaProfileManager.swift`)
- **Renamed Files**: `ResolutionUtils.swift` → `AppUtils.swift` (expanded functionality)

## Development

For instructions on how to set up the development environment, run the tests, and contribute to the project, see the [Development Guide](DEVELOPMENT.md).

## Usage

For detailed instructions on how to use the command-line interface and configure the application, see the [Usage Guide](USAGE.md).

## Troubleshooting

For solutions to common problems, see the [Troubleshooting Guide](TROUBLESHOOTING.md).

## Testing Changes

Always test both interfaces after making changes:
```bash
# Test CLI
./dist/MacAppPositioner detect
./dist/MacAppPositioner apply office

# Test GUI (launches in background)
./dist/MacAppPositionerGUI &
```

## Configuration Notes

- **Resolution Format**: Use user-friendly `"3440x1440"` format, not `"3440.0x1440.0"`
- **Profile Structure**: Workspace monitor uses quadrant layout (top_left, top_right, bottom_left, bottom_right)
- **Bundle IDs**: Find with `osascript -e 'id of app "AppName"'`