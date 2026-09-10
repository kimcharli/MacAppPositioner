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
| `LayoutEngine` | **Single owner of target window geometry.** Pure; no AppKit/AX/singletons. Put all placement rules here. |
| `CocoaCoordinateManager` | Screen detection, coordinate conversion, window positioning |
| `CocoaProfileManager` | Profile detection, plan generation, plan execution |
| `ScreenProviding` | Seam over `NSScreen`. `SystemScreenProvider` in production, `FixtureScreenProvider` in tests |
| `WindowControlling` | Seam over `NSWorkspace` + the AX API. `SystemWindowController` in production, `FixtureWindowController` in tests |
| `ConfigManager` | Config loading/saving from multiple search paths |
| `AppLogger` | Shared file logger — tees `print()` to stdout + log file |
| `AppUtils` | Resolution normalization, Accessibility permission check, shared constants |
| `MenuBarManager` | GUI menu bar interface |

## Common Mistakes to Avoid

| Don't | Do Instead |
| ----- | ---------- |
| `./MacAppPositioner detect` | `./dist/MacAppPositioner detect` |
| Compute a window target anywhere but `LayoutEngine` | Add the rule to `LayoutEngine.resolve` — plan and apply both consume it |
| Add a positioning branch to `applyProfile` | `applyProfile` only executes `generatePlan`'s output; change the engine |
| Use `ProfileManager` | Use `CocoaProfileManager` |
| Use `CoordinateManager` | Use `CocoaCoordinateManager` |
| Hardcode resolution format `"3440.0x1440.0"` | Use `AppUtils.normalizeResolution()` |
| Rely on `NSScreen.main` | Use `getBuiltinScreen()` |
| Write duplicate utility functions | Use `AppUtils` |
| `NSWorkspace.shared.runningApplications.first(where:)` for PID lookup | Use `addressablePID(bundleID:)` on `WindowControlling` — handles multiple processes with the same bundle ID |
| Read `NSScreen` or call the AX API from `CocoaProfileManager` | Go through the `ScreenProviding` / `WindowControlling` seams, or the tests cannot run without your hardware |

### Multi-Instance Apps

Some apps (e.g. Google Chrome) run multiple processes with the same bundle ID simultaneously — a regular window instance and a headless/debugging instance. `NSWorkspace.shared.runningApplications.first(where:)` returns whichever the OS lists first, which may be the headless one with no AX-accessible windows.

`WindowControlling.addressablePID(bundleID:)` handles this: `runningPIDs(bundleID:)` returns matches sorted most-recently-launched first, and `addressablePID` returns the first whose `hasMovableWindow(pid:)` is true. The probe does not activate the app, so skipped processes don't flicker. Use `currentWindowFrame(bundleID:)` when you want the frame as well.

### Testing

Two harnesses, both driven by `./Scripts/test_all.sh`:

- `run_test` — runs a standalone `Tests/*.swift` script via `swift`. For observation scripts that only read the live system.
- `run_compiled_test` — `swiftc`-compiles a test together with `MacAppPositioner/Shared/*.swift` and `Tests/TestSupport.swift`. For anything asserting on shipping types. Such a file **must** use `@main struct X { static func main() }` and **must not** have a hashbang or top-level statements.

Use the fixture providers rather than real hardware; see `Tests/test_profile_logic.swift`.

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
