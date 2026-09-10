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
    ├── LayoutEngine.swift           # Target window geometry (pure)
    ├── CocoaCoordinateManager.swift # Coordinate conversion & AX window positioning
    ├── CocoaProfileManager.swift    # Profile detection & application
    ├── ScreenProviding.swift        # Screen access seam (system / fixture)
    ├── WindowControlling.swift      # Window access seam (system / fixture)
    ├── ConfigManager.swift          # JSON config loading
    ├── AppLogger.swift              # Tees print() to a per-session log file
    ├── AppUtils.swift               # Utility functions & shared constants
    └── PlanModels.swift             # Execution plan data structures
```

### Core Classes

| Class | Responsibility |
|-------|---------------|
| `LayoutEngine` | **Single owner of target window geometry.** Pure — Foundation + CoreGraphics only. Both plan generation and apply call `resolve(...)`, so a preview cannot disagree with an apply. All placement rules belong here. |
| `CocoaCoordinateManager` | Screen detection, coordinate conversion (Cocoa→internal), window positioning via Accessibility API |
| `CocoaProfileManager` | Profile detection, layout application, plan generation, config generation |
| `ScreenProviding` | Seam over `NSScreen` — `SystemScreenProvider` in production, `FixtureScreenProvider` in tests |
| `WindowControlling` | Seam over `NSWorkspace` + the Accessibility API — `SystemWindowController` in production, `FixtureWindowController` in tests |
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
./Scripts/test_all.sh    # Full suite (~8 seconds)
```

The suite uses **two harnesses**, and which one you want depends on what you're testing.

### `run_test` — standalone observation scripts

Run directly by `swift`, with no access to the shipping types. Use these only to observe the live system (screen enumeration, permission checks).

```bash
swift Tests/test_monitor_detection.swift
swift Tests/test_positioning_logic.swift
```

```swift
#!/usr/bin/env swift
import AppKit

print("=== Test Name ===")
var testPass = true

// Test implementation...

print("Result: \(testPass ? "PASS" : "FAIL")")
exit(testPass ? 0 : 1)
```

### `run_compiled_test` — tests against the real sources

`swiftc`-compiles the test together with `MacAppPositioner/Shared/*.swift` and `Tests/TestSupport.swift`, so it asserts on the shipping types rather than a re-implementation. **Prefer this for anything about behaviour.**

Two hard constraints, both of which are compiler errors rather than warnings:

- Use `@main struct … { static func main() }`. Top-level statements are rejected (`expressions are not allowed at the top level`).
- **No hashbang** (`hashbang line is allowed only in the main file`).

```swift
import Foundation

@main
struct MyFeatureTests {
    static func main() {
        let t = TestRunner("My Feature")

        t.section("[1] what is being established")
        t.checkEqual(actual, expected, "plain-language claim")

        t.finish()   // exits 0 if every check passed, else 1
    }
}
```

Inject fixtures instead of depending on the machine's hardware — `FixtureScreenProvider` for displays, `FixtureWindowController` for running apps and their windows. `Tests/test_profile_logic.swift` is the worked example.

Register the new file in `Scripts/test_all.sh`, and add any new `Shared/*.swift` file to **both** `Scripts/build.sh` and `Scripts/build-gui.sh` — they enumerate sources explicitly.

### When to Add Tests

- New positioning or coordinate features
- Bug fixes (add regression tests)
- Monitor setup changes (update expected values)

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

**Conversion happens once**, at the NSScreen API boundary, via `convertCocoaToInternal()`. It is `static` because it depends on nothing but its arguments (an instance forwarder exists for convenience):

```swift
static func convertCocoaToInternal(cocoaRect: CGRect, mainScreenHeight: CGFloat) -> CGRect {
    let internalY = mainScreenHeight - cocoaRect.maxY
    return CGRect(x: cocoaRect.origin.x, y: internalY, width: cocoaRect.width, height: cocoaRect.height)
}
```

After conversion, all internal calculations (quadrant positioning, window placement) use top-left origin coordinates, which aligns with the Accessibility API's coordinate system.

### Critical Rules

1. **Do NOT use `NSScreen.main` for coordinate reference height or monitor identification.** It returns different screens for CLI vs GUI apps (whichever monitor has mouse focus in GUI). Use the first entry of `ScreenProviding.screens` for the menu bar screen (Cocoa origin), and `getBuiltinScreen()` for built-in display identification. Reading `NSScreen` directly outside `SystemScreenProvider` also makes the code untestable.

2. **Convert Cocoa→internal at the boundary only.** `CocoaMonitorInfo.init(from:)` handles this. Do not convert inside business logic.

3. **Use actual window dimensions** for positioning. Never hardcode default sizes — get the real size from `getWindowRect()`.

4. **Restore focus after positioning.** `setWindowPosition` activates the target app — the Accessibility API will not reliably move a window otherwise — so applying a profile leaves focus on whichever app was positioned last. `executePlan` therefore captures `frontmostBundleID()` before the loop and calls `activate(bundleID:)` afterwards, returning focus to where the user left it. Preserve that if you change the loop.

5. **Verify positioning visually.** Debug output alone is insufficient. Use AppleScript or visual confirmation:
   ```bash
   osascript -e 'tell application "Chrome" to get bounds of front window'
   ```

6. **Always resolve the workspace monitor from the profile.** The workspace monitor comes from the profile config, not from `NSScreen.screens` order. Pass it in via `getAllMonitors(workspaceResolution:)`; do not have monitor detection load config itself.

### Historical Bugs to Avoid

| Bug | Root Cause | Prevention |
|-----|-----------|-----------|
| GUI menu bar Apply does nothing visible / positions to wrong location | `getAllMonitors()` used `NSScreen.main?.frame.height` for Cocoa→internal conversion. In GUI apps, `NSScreen.main` returns the screen with mouse focus (not the menu bar screen), producing wrong `mainScreenHeight` and therefore wrong Y coordinates for all monitors | Use `NSScreen.screens.first?.frame.height` — `screens.first` always returns the menu bar screen regardless of app type |
| Chrome on wrong monitor | `getAllMonitors()` used the first profile instead of the specified one | Pass the profile's workspace resolution: `getAllMonitors(workspaceResolution:)`. It takes a resolution rather than a profile name so that monitor detection does no config I/O of its own — see the plan's item 2.6 |
| Incorrect bottom-left position | Used default window size instead of actual | Always read actual window dimensions |
| `top_left` / `top_right` windows land 30pt short and **never converge** — `apply` reports failure, next `plan` says `MOVE` again, forever | `NSScreen.visibleFrame` under-reports the menu bar inset on **external** displays until the process owns an `NSApplication`. The CLI had none, so external screens claimed 30pt at the top that the window server would not surrender | The CLI calls `NSApplication.shared.setActivationPolicy(.accessory)` before reading any screen. Never remove it; it is not GUI scaffolding. GUI apps are immune because they have an `NSApplication` by construction |
| Profile written with no `workspace` monitor — every `layout.workspace` app silently disappears from the plan | `getAllMonitors()` was called with no `workspaceResolution`, so `isWorkspace` was false everywhere and `positionLabel(for:)` could only return `.builtin` / `.secondary` | Never build a profile's monitor list by hand. Use `CocoaCoordinateManager.profileMonitors(preservingWorkspace:)`, the single writer |

### Platform Gotchas

Non-obvious AppKit and toolchain behaviour that has already cost time here.

- **`NSScreen.visibleFrame` needs an `NSApplication`.** On external displays it
  reports a 0pt top inset until `NSApplication.shared` is touched, then reports
  the true menu bar height. Measured in one process:

  ```text
  [before NSApplication.shared] SAMSUNG: reservedTop=0.0
  [after  NSApplication.shared] SAMSUNG: reservedTop=30.0
  ```

  Any new executable that reads screen geometry must initialise `NSApplication`
  first.

- **`CocoaMonitorInfo.frame` / `.visibleFrame` are internal top-left, Y down** —
  *not* Cocoa. They are already converted. `NSScreen.frame` is bottom-left, Y up.
  Mixing them silently produces plausible-looking wrong coordinates. Label any
  rect you print with the space it is in; `test-coordinates` once claimed
  "[Native Cocoa]" over converted values, and that mislabel hid a real bug.

- **`AppLogger` shadows the global `print()`.** Anything invoked during logger
  startup must use `Swift.print` or write to `FileHandle.standardError`
  directly, or it recurses. That is why `resolveLogDirectory()` re-implements a
  minimal config read instead of using `ConfigManager`.

- **stdout is for pipeable results only.** Progress and status go to
  `printDiagnostic(...)`, which writes to stderr plus the log file. `print()`
  reaches stdout. `generate-config > config.json` depends on this split.

- **The window server clamps silently.** `setWindowPosition` requests are
  granted at the nearest legal position and the AX call still returns success.
  The only way to detect it is to re-read the frame, which `setWindowPosition`
  does. Treat a mismatch as a real signal, not noise.

- **`tac` does not exist on macOS.** Use `git log --reverse`.

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

**Permission errors**: Grant Accessibility permissions to your terminal app (for CLI) or to Mac App Positioner (for GUI) in System Settings > Privacy & Security > Accessibility. If the GUI was rebuilt, you must **remove and re-add** the app in the Accessibility list — macOS TCC invalidates the old entry when the binary's code signature changes. The build script ad-hoc signs the bundle to reduce this, but replacing the binary still may require re-granting. See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) section 1 for details.

**Check logs first**: Both CLI and GUI write per-session logs to `~/Library/Logs/mac-app-positioner/`. The first lines show whether Accessibility permission is granted — this is the most common cause of "nothing moves" issues.

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
