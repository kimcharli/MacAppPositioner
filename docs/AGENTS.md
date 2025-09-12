# AI Agent Guide for Mac App Positioner

This document provides guidelines and quick reference material for AI agents working with the Mac App Positioner codebase.

## 1. Core Principles

-   **Dynamic Over Static:** Always favor dynamic detection of the monitor setup over hardcoded values. See [ARCHITECTURE.md](ARCHITECTURE.md) for details.
-   **Terminology Consistency:** Refer to [TERMINOLOGY.md](TERMINOLOGY.md) for precise definitions of terms like "Primary Monitor" and "Main Display."
-   **Coordinate System Awareness:** The application uses native Cocoa coordinates (bottom-left origin, Y increases upward). See [COORDINATE_SYSTEM_GUIDE.md](COORDINATE_SYSTEM_GUIDE.md) for a detailed explanation.
-   **DRY Principles:** Use shared utilities like `AppUtils` for common operations like resolution normalization and profile loading.

## 2. Quick Reference: Commands & Paths

⚠️ **Important**: Always use the compiled binaries in the `dist/` folder for execution.

### Build Commands

**Recommended: Use provided build scripts.** They are kept up-to-date with all necessary source files and flags.

```bash
# Build CLI only
./Scripts/build.sh

# Build GUI only
./Scripts/build-gui.sh

# Build both CLI and GUI
./Scripts/build-all.sh

# Run all tests
./Scripts/test_all.sh
```

<details>
<summary>Manual Build Commands (for reference only)</summary>

```bash
# Build CLI only
swiftc -o dist/MacAppPositioner MacAppPositioner/CLI/CocoaMain.swift \
  MacAppPositioner/Shared/*.swift \
  -framework Cocoa -framework CoreGraphics

# Build GUI only
swiftc -o dist/MacAppPositionerGUI MacAppPositioner/GUI/*.swift \
  MacAppPositioner/Shared/*.swift \
  -framework Cocoa -framework CoreGraphics -framework SwiftUI
```
</details>

### Execution Commands

```bash
# --- CLI Usage ---
# Detect current setup
./dist/MacAppPositioner detect

# Auto-detect and apply the matching profile
./dist/MacAppPositioner apply

# Apply a specific profile by name
./dist/MacAppPositioner apply office

# Test and display coordinate system information
./dist/MacAppPositioner test-coordinates

# --- GUI Usage ---
# Launch GUI app for development testing
./dist/MacAppPositionerGUI

# Launch installed GUI app
open /Applications/MacAppPositionerGUI.app
```

## 3. GUI Deployment Checklist

**After any GUI changes, ALWAYS follow this sequence:**

1.  `./Scripts/build-gui.sh` - Build the application first.
2.  `open ./dist/MacAppPositionerGUI` - **Test the build from the `dist/` directory.**
3.  Manually copy the app from `dist/` to `/Applications/`. **Drag-and-drop is recommended** to handle permissions correctly.
4.  Verify the "About" menu in the running app shows the current build timestamp to confirm it's the updated version.

### Common Deployment Mistakes
-   Testing the `/Applications/` version without copying the newly built app from `dist/`.
-   Forgetting to rebuild after code changes.
-   Using `cp` or `mv` commands, which can cause permission issues. Use drag-and-drop.
-   Not checking the build timestamp in the "About" menu to confirm the update.

## 4. Code Architecture

The application is a native Swift macOS app with a modular design.

-   **CLI**: `MacAppPositioner/CLI/CocoaMain.swift` - Command-line interface.
-   **GUI**: `MacAppPositioner/GUI/*.swift` - SwiftUI-based graphical interface.
-   **Shared**: `MacAppPositioner/Shared/*.swift` - Core logic shared between CLI and GUI.

### Key Classes
-   **`CocoaProfileManager`**: Handles profile detection and application logic.
-   **`CocoaCoordinateManager`**: Manages monitor detection and coordinate handling.
-   **`WindowManager`**: Contains the core window positioning logic.
-   **`ConfigManager`**: Handles loading and parsing of the JSON configuration.
-   **`AppUtils`**: Provides shared utilities for resolution normalization, etc.
-   **`MenuBarManager`**: Manages the GUI's menu bar interface.

## 5. Common Pitfalls & Best Practices

| ❌ Don't Do This                                       | ✅ Do This Instead                                           |
| ------------------------------------------------------ | ------------------------------------------------------------ |
| `./MacAppPositioner detect` (Wrong path)               | `./dist/MacAppPositioner detect` (Correct path)              |
| Use obsolete classes like `ProfileManager`             | Use current classes like `CocoaProfileManager`               |
| Hardcode resolution formats like `"3440.0x1440.0"`     | Use user-friendly format `"3440x1440"` and `AppUtils`          |
| Write duplicate utility functions                      | Use shared utilities from `AppUtils`                         |

### File Management Notes
-   **Active Files**: All files in `MacAppPositioner/Shared/` are actively used.
-   **Obsolete Files**: `ProfileManager.swift` was removed and replaced by `CocoaProfileManager.swift`.

## 6. Auto-Documentation System

This project uses an AI-assisted documentation system. When you mention the following trigger phrases, I will automatically review and update relevant documentation.

```yaml
Primary Triggers:
  - "deployment docs need updating"
  - "documentation maintenance needed"
  - "add this to troubleshooting guide"
  - "deployment process broken"
  - "GUI deployment issue"
  - "docs are outdated"

Technical Triggers:
  - "NSScreen.main issue"
  - "wrong build date in About"
  - "permission denied Applications"
  - "cached version problem"
  - "positioning still broken"
```

### Manual Documentation Tasks
You can also invoke documentation tasks manually:
```bash
# Invoke a comprehensive documentation review
/task "Review and update all documentation for consistency" --agent document-reviewer

# Sync this guide with DEVELOPMENT.md
/task "Synchronize deployment docs between AGENTS.md and DEVELOPMENT.md" --agent document-reviewer
```

## 7. Further Reading

-   **Architecture**: [ARCHITECTURE.md](ARCHITECTURE.md)
-   **Development Guide**: [DEVELOPMENT.md](DEVELOPMENT.md)
-   **Usage Guide**: [USAGE.md](USAGE.md)
-   **Troubleshooting**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
-   **Terminology**: [TERMINOLOGY.md](TERMINOLOGY.md)
