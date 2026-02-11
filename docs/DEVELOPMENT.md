# Development Guide

This guide covers everything needed to contribute to Mac App Positioner: setup, building, testing, architecture rules, and key terminology.

## 1. Prerequisites

- **macOS 11.0** (Big Sur) or later
- **Xcode Command Line Tools** (or full Xcode 12.0+)
- **Swift 5.0+**

```bash
xcode-select --install
```

Grant Accessibility permissions for your terminal or IDE in **System Settings > Privacy & Security > Accessibility**.

## 2. Project Structure

```
MacAppPositioner/
├── CLI/
│   └── CocoaMain.swift              # CLI entry point
├── GUI/
│   ├── App.swift                    # SwiftUI app definition
│   ├── ContentView.swift            # Main tabbed interface
│   ├── DashboardViewModel.swift     # View model
│   ├── MenuBarManager.swift         # Menu bar functionality
│   ├── MonitorVisualizationView.swift
│   ├── ProfileManagerView.swift
│   └── SettingsView.swift
└── Shared/
    ├── CocoaCoordinateManager.swift # Coordinate system & window positioning
    ├── CocoaProfileManager.swift    # Profile detection & application
    ├── ConfigManager.swift          # JSON config loading
    ├── WindowManager.swift          # Legacy window manipulation
    ├── AppUtils.swift               # Utility functions
    └── PlanModels.swift             # Execution plan data structures
```

### Core Classes

| Class | Responsibility |
|-------|---------------|
| `CocoaCoordinateManager` | Screen detection, coordinate conversion (Cocoa→internal), quadrant calculations, window positioning via Accessibility API |
| `CocoaProfileManager` | Profile detection, layout application, plan generation, config generation |
| `ConfigManager` | Loading/saving `config.json` from multiple search paths |
| `AppUtils` | Resolution normalization, shared utilities |
| `MenuBarManager` | GUI menu bar icon and menu structure |

## 3. Building

Use the provided build scripts (they stay current with all source files and flags):

```bash
./Scripts/build-all.sh    # Build CLI + GUI with app bundle
./Scripts/build.sh        # CLI only
./Scripts/build-gui.sh    # GUI only
```

Binaries go to `dist/`. Always run from there:

```bash
./dist/MacAppPositioner detect
./dist/MacAppPositionerGUI
```

## 4. GUI Deployment

After GUI changes, follow this sequence:

1. **Build**: `./Scripts/build-gui.sh`
2. **Test from dist/**: `open ./dist/MacAppPositionerGUI`
3. **Verify build timestamp** in the About menu
4. **Install**: Drag `dist/MacAppPositionerGUI.app` to `/Applications/`

Use drag-and-drop to install — `cp` commands can cause permission issues.

## 5. Testing

```bash
./Scripts/test_all.sh    # Full test suite (~10 seconds)
```

Individual tests in `Tests/`:

```bash
swift Tests/test_monitor_detection.swift
swift Tests/test_positioning_logic.swift
```

### When to Add Tests

- New positioning or coordinate features
- Bug fixes (add regression tests)
- Monitor setup changes (update expected values)

### Test Template

```swift
#!/usr/bin/env swift
import AppKit

print("=== Test Name ===")
var testPass = true

// Test implementation...

print("Result: \(testPass ? "PASS" : "FAIL")")
exit(testPass ? 0 : 1)
```

## 6. Coordinate System Rules

### Architecture

The application uses a **top-left origin internal coordinate system** (Y increases downward). This was established in commit `8aac8c6` ("Unify coordinate system to top-left origin").

```
NSScreen (Cocoa)              Internal / Accessibility API
┌──────────────┐              ┌──────────────┐
│              │ Y increases  │              │ Y increases
│   (0,0) at  │ upward       │   (0,0) at  │ downward
│ bottom-left  │              │  top-left    │
└──────────────┘              └──────────────┘
```

**Conversion happens once**, at the NSScreen API boundary, via `convertCocoaToInternal()`:

```swift
func convertCocoaToInternal(cocoaRect: CGRect, mainScreenHeight: CGFloat) -> CGRect {
    let internalY = mainScreenHeight - cocoaRect.maxY
    return CGRect(x: cocoaRect.origin.x, y: internalY, width: cocoaRect.width, height: cocoaRect.height)
}
```

After conversion, all internal calculations (quadrant positioning, window placement) use top-left origin coordinates, which aligns with the Accessibility API's coordinate system.

### Critical Rules

1. **Do NOT use `NSScreen.main` for monitor identification.** It returns different screens for CLI vs GUI apps (whichever monitor has mouse focus in GUI). Use `getBuiltinScreen()` instead.

2. **Convert Cocoa→internal at the boundary only.** `CocoaMonitorInfo.init(from:)` handles this. Do not convert inside business logic.

3. **Use actual window dimensions** for positioning. Never hardcode default sizes — get the real size from `getCurrentWindowPosition()`.

4. **Verify positioning visually.** Debug output alone is insufficient. Use AppleScript or visual confirmation:
   ```bash
   osascript -e 'tell application "Chrome" to get bounds of front window'
   ```

5. **Always specify the correct profile** when detecting monitors. The workspace monitor comes from the profile config, not from `NSScreen.screens` order.

### Historical Bugs to Avoid

| Bug | Root Cause | Prevention |
|-----|-----------|-----------|
| Chrome on wrong monitor | `getAllMonitors()` used first profile instead of specified profile | Always pass profile name to `getAllMonitors(for:)` |
| Wrong Y coordinates | `NSScreen.main` returned different screens in CLI vs GUI | Use `getBuiltinScreen()` instead |
| Incorrect bottom-left position | Used default window size instead of actual | Always read actual window dimensions |

## 7. Terminology

### Monitor Types

| Term | Definition |
|------|-----------|
| **Workspace Monitor** | The target monitor for quadrant-based app positioning. Set via `position: "workspace"` in config. Independent from macOS "main display." |
| **Main Display** (macOS) | The display with the menu bar and dock. Has origin (0,0) in Cocoa coordinates. Detected via `NSScreen.main` — but **do not use this** for positioning logic. |
| **Built-in Display** | The MacBook's internal screen. Referenced as `"macbook"` or `"builtin"` in config. Detected via `getBuiltinScreen()`. |
| **Secondary Monitor** | Any additional monitor that isn't workspace or built-in. |

### Positioning Terms

| Term | Definition |
|------|-----------|
| **Quadrant Layout** | Division of workspace monitor into four zones: `top_left`, `top_right`, `bottom_left`, `bottom_right` |
| **Profile** | A named monitor configuration + layout. Examples: `"home"`, `"office"` |
| **Resolution Matching** | Monitors are identified by resolution strings (e.g., `"3440x1440"`) to match config profiles to detected hardware |

### Key Principle

**Workspace != Main**: The positioning target (workspace) is configured independently from the macOS main display setting.

## 8. Debugging

```bash
# Stream GUI logs
log stream --predicate 'process == "MacAppPositionerGUI"'

# Recent logs
log show --predicate 'process == "MacAppPositionerGUI"' --last 15m

# System display info
system_profiler SPDisplaysDataType
```

### Common Issues

**GUI changes not reflected**: You're running an old version from `/Applications/` instead of the newly built `dist/` version. Check the About menu build timestamp.

**Permission errors**: Grant Accessibility permissions to your terminal app (for CLI) or to Mac App Positioner (for GUI) in System Settings > Privacy & Security > Accessibility.

## 9. Contributing

### Code Style

- Follow Swift naming conventions and Apple's API Design Guidelines
- Add comments for complex logic
- Keep functions focused and testable

### Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `refactor:` Code restructuring
- `test:` Test changes

### Pull Request Process

1. Fork and create a feature branch
2. Add tests for new functionality
3. Run `./Scripts/test_all.sh`
4. Update docs if needed
5. Submit PR with clear description

## 10. Resources

- [Apple Accessibility API](https://developer.apple.com/documentation/applicationservices/accessibility)
- [NSScreen Documentation](https://developer.apple.com/documentation/appkit/nsscreen)
- [Cocoa Drawing Guide - Coordinate Systems](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CocoaDrawingGuide/Transforms/Transforms.html)
