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

## Build & Toolchain

Both `Scripts/build.sh` and `Scripts/build-gui.sh` **enumerate sources
explicitly**. A new file under `MacAppPositioner/Shared/` must be added to both
or it will not compile into one of the targets.

There is no SPM package and no Xcode project. `swift test` cannot work here:
the Command Line Tools ship neither `XCTest` nor `Testing`. `Scripts/test_all.sh`
is the supported harness.

> **Current environment note (2026-09-10):** the Command Line Tools 27.0 update
> ships no `libSwiftUIMacros.dylib`, so **no SwiftUI file compiles** — `@State`
> cannot expand and `Scripts/build-all.sh` fails. `Scripts/build.sh` (CLI) and
> `Scripts/test_all.sh` are unaffected. Reproduced on a clean checkout, so it is
> environmental, not a regression. GUI changes cannot be verified by building
> until Xcode is installed or the toolchain is repaired — say so explicitly
> rather than implying a GUI change was tested.

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
| Build a profile's `monitors` array inline | Use `CocoaCoordinateManager.profileMonitors(preservingWorkspace:)` — doing it by hand loses the `workspace` role and silently drops every `layout.workspace` app |
| Read screen geometry in a new executable without an `NSApplication` | Initialise `NSApplication.shared` first, or `visibleFrame` under-reports the external-display menu bar and targets become unreachable |
| `print()` progress or status messages | `printDiagnostic(...)` — stdout is reserved for pipeable output like `generate-config` |
| Call `print()` from anything `AppLogger.start()` touches | `Swift.print` or `FileHandle.standardError` — the global `print` is shadowed and will recurse |
| Trust a rect's label without checking the space | `CocoaMonitorInfo.frame` is internal top-left; `NSScreen.frame` is Cocoa bottom-left |
| `git add -A` | Stage explicit paths — a hook writes `graphify-out/` on every commit |

## Traps That Have Already Bitten

Each of these was found the expensive way. They look fine in review.

**Silence is the failure mode.** This codebase's bugs mostly do not throw — they
produce a shorter list. An app missing from `plan` output means it is not in
`layout`; `UNAVAILABLE` means it *is* listed but exposes no moveable window.
A profile with no `workspace` monitor drops every workspace app with no error
at all. When something "does nothing", count the entries before assuming the
positioning logic is wrong.

**Config semantics that surprise people:**

- `layout` is **global**, not per-profile. Profiles change which *monitor* the
  layout targets, not the arrangement. (`README.md:18` still promises per-profile
  layouts — open item 3b.4.)
- Only `workspace` and `builtin` can host apps. A monitor labelled `secondary`,
  `left` or `right` is recorded but can never receive one.
- Profile matching is **exact set equality** over normalised resolutions.
  Not a subset. Duplicate resolutions collapse into one set entry.
- `AppLayoutEntry.sizing` defaults to `"keep"`. That, not
  `AppConstants.defaultWindowSize`, is why windows keep their size.
- An invalid `position` behaves differently by form: the object form
  (`{"position": "bogus"}`) **throws and fails the whole config load**, while the
  legacy bare string silently becomes `center`. `decodeIfPresent` throws on
  present-but-invalid; the `?? .center` only covers an absent key.
- `saveConfig` re-encodes from the `Config` struct, so any top-level key the
  schema does not model is **dropped**. Everything modelled survives.
- `generate-config` does **not** inspect running apps — its `layout` is a fixed
  five-app template — and it prints a whole fresh config, so redirecting it over
  an existing file destroys other profiles. `update` is the additive one.

**Verify by running, not by reading.** Three claims in this codebase were nearly
documented backwards from a confident read of the source, and were only caught
by executing the code. If you are about to assert what something does, run it
first — especially before writing it into a doc or a commit message.

**Touching the operator's live config:** back it up, make the change, and
restore with a `shasum` comparison to prove the machine was left as found.
`plan` is read-only and safe; `apply` moves real windows.

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
