# AI Agent Guide

Quick reference for AI agents working with the Mac App Positioner codebase.

## Core Principles

- **Dynamic over static**: Always detect monitors at runtime. Never hardcode resolutions or positions.
- **Use shared utilities**: `AppUtils` for resolution normalization, `ConfigManager` for config loading.
- **Avoid `NSScreen.main`**: Use `getBuiltinScreen()` for reliable monitor identification.
- **Consistent coordinate system**: Internal top-left origin. Cocoa conversion happens at the boundary only. See [DEVELOPMENT.md](DEVELOPMENT.md) Section 6.

## Build & Run

```bash
# Build
./Scripts/build-all.sh    # CLI + GUI
./Scripts/build.sh        # CLI only
./Scripts/build-gui.sh    # GUI only

# Run (always from dist/)
./dist/MacAppPositioner detect
./dist/MacAppPositioner apply office
./dist/MacAppPositioner plan
./dist/MacAppPositionerGUI

# Test
./Scripts/test_all.sh
```

## Code Layout

| Directory | Contents |
| --------- | -------- |
| `MacAppPositioner/CLI/` | `CocoaMain.swift` - CLI entry point |
| `MacAppPositioner/GUI/` | SwiftUI views, menu bar manager, view models |
| `MacAppPositioner/Shared/` | Core logic shared between CLI and GUI |

### Key Classes

| Class | Purpose |
| ----- | ------- |
| `CocoaCoordinateManager` | Screen detection, coordinate conversion, quadrant calculations, window positioning |
| `CocoaProfileManager` | Profile detection, layout application, plan generation |
| `ConfigManager` | Config loading/saving from multiple search paths |
| `AppUtils` | Resolution normalization, shared utilities |
| `MenuBarManager` | GUI menu bar interface |

## Common Mistakes to Avoid

| Don't | Do Instead |
| ----- | ---------- |
| `./MacAppPositioner detect` | `./dist/MacAppPositioner detect` |
| Use `ProfileManager` | Use `CocoaProfileManager` |
| Use `CoordinateManager` | Use `CocoaCoordinateManager` |
| Hardcode resolution format `"3440.0x1440.0"` | Use `AppUtils.normalizeResolution()` |
| Rely on `NSScreen.main` | Use `getBuiltinScreen()` |
| Write duplicate utility functions | Use `AppUtils` |

## GUI Deployment Checklist

After GUI changes:

1. `./Scripts/build-gui.sh`
2. `open ./dist/MacAppPositionerGUI` (test the build)
3. Verify build timestamp in About menu
4. Drag `.app` from `dist/` to `/Applications/` (use drag-and-drop, not `cp`)

## Further Reading

- [DEVELOPMENT.md](DEVELOPMENT.md) - Full developer guide with coordinate system rules and terminology
- [ARCHITECTURE.md](ARCHITECTURE.md) - System design and data flow
- [CONFIGURATION.md](CONFIGURATION.md) - Config file format reference
- [USAGE.md](USAGE.md) - CLI and GUI user guide
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
