# Architecture

Native macOS window positioning application using Swift, AppKit, and the Accessibility API.

## Overview

Mac App Positioner automatically positions application windows according to predefined layouts across multiple monitors. It provides both a CLI and a SwiftUI GUI that share the same core logic.

## Component Architecture

### CLI Interface

- **`CocoaMain.swift`**: Entry point. Parses command-line arguments and dispatches to core logic.
- **Commands**: `detect`, `apply`, `plan`, `update`, `generate-config`, `test-coordinates`

### GUI Interface

- **`App.swift`**: SwiftUI app definition
- **`ContentView.swift`**: Main tabbed interface (Dashboard, Profiles, Settings)
- **`MenuBarManager.swift`**: Menu bar icon with quick profile switching
- **`DashboardViewModel.swift`**: Observable state management for the dashboard
- **`MonitorVisualizationView.swift`**: Visual monitor layout representation
- **`ProfileManagerView.swift`**: Profile management UI
- **`SettingsView.swift`**: Application preferences

### Shared Core (`MacAppPositioner/Shared/`)

- **`LayoutEngine`**: **Single owner of target window geometry.** Pure (Foundation + CoreGraphics only — no AppKit, no Accessibility API, no singletons). Both plan generation and layout application call `LayoutEngine.resolve(...)`, which is what prevents a preview from disagreeing with an apply.
- **`CocoaCoordinateManager`**: Coordinate conversion (Cocoa to internal top-left), screen detection, window positioning via Accessibility API
- **`CocoaProfileManager`**: Profile detection by resolution matching, plan generation, plan execution
- **`ConfigManager`**: JSON configuration loading from multiple search paths, caching
- **`AppLogger`**: Shared file logger that overrides `print()` to tee all output to both stdout and a timestamped log file under the configured `log_directory`
- **`AppUtils`**: Resolution normalization, Accessibility permission check, shared constants
- **`PlanModels`**: `ExecutionPlan` / `AppAction` data structures

## Technology Stack

- **Language**: Swift 5.0+
- **Frameworks**: AppKit (NSScreen, NSWorkspace), SwiftUI (GUI), Accessibility (AXUIElement), Foundation
- **Configuration**: JSON-based with profile support
- **Build**: Shell scripts wrapping `swiftc` (no Xcode project required)

## Coordinate System

The application converts NSScreen's Cocoa coordinates (bottom-left origin, Y up) to an internal top-left origin system (Y down) at the API boundary. This internal system aligns with the Accessibility API's coordinate space, so no further conversion is needed for window positioning.

See [DEVELOPMENT.md](DEVELOPMENT.md) Section 6 for detailed rules and historical context.

## Data Flow

### Profile Detection

```text
NSScreen.screens -> resolution strings -> compare against config profiles -> matched profile name
```

### Layout Application

`applyProfile(name)` is defined as `generatePlan(name)` followed by `executePlan(plan)`. There is no second geometry path — what the preview describes is literally what runs.

```text
1. Load config.json (ConfigManager)
2. Detect monitors, convert to internal coordinates (CocoaCoordinateManager)
3. Match profile by resolution set (CocoaProfileManager)
4. Build the plan — for each app in the layout:
   a. Find running app by bundle ID, pick the PID with a moveable window
   b. Read its current frame via the Accessibility API
   c. LayoutEngine.resolve(...) -> target frame + decision
      (move / keepConfigured / keepAlreadyPlaced / keepOnTargetScreen / appUnavailable)
5. Execute the plan — for each action whose decision is `move`:
   a. Re-resolve the PID by bundle ID (plans carry no PIDs)
   b. Set the position via the Accessibility API and verify it
6. Restore focus to the previously frontmost app
```

### Configuration Search Order

1. `~/.config/mac-app-positioner/config.json`
2. `~/Library/Application Support/MacAppPositioner/config.json`
3. `./config.json` (current directory)
4. `~/.mac-app-positioner/config.json` (legacy)

## Key Design Decisions

- **Shared core logic**: CLI and GUI use identical `CocoaProfileManager` and `CocoaCoordinateManager` to ensure consistent behavior
- **Plan is the only geometry path**: `applyProfile` executes `generatePlan`'s output, so a preview and an apply cannot drift. Target geometry lives solely in the pure `LayoutEngine`.
- **Top-left internal coordinates**: Aligns with Accessibility API, avoiding per-window conversion
- **Explicit builtin screen detection**: `getBuiltinScreen()` avoids `NSScreen.main` inconsistency between CLI and GUI apps
- **Resolution-based matching**: Profiles matched by monitor resolution sets, not by arrangement position
- **Singleton managers**: `ConfigManager.shared`, `CocoaCoordinateManager.shared`, and `AppLogger.shared` ensure consistent state
- **Global print() override**: `AppLogger` shadows `Swift.print` at module scope so all output is logged without call-site changes
