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

- **`CocoaCoordinateManager`**: Coordinate conversion (Cocoa to internal top-left), screen detection, quadrant calculations, window positioning via Accessibility API
- **`CocoaProfileManager`**: Profile detection by resolution matching, layout application, plan generation
- **`ConfigManager`**: JSON configuration loading from multiple search paths, caching
- **`WindowManager`**: Low-level Accessibility API window manipulation
- **`AppUtils`**: Resolution normalization, path utilities

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

```text
1. Load config.json (ConfigManager)
2. Detect monitors, convert to internal coordinates (CocoaCoordinateManager)
3. Match profile by resolution set (CocoaProfileManager)
4. For each app in layout:
   a. Find running app by bundle ID (NSWorkspace)
   b. Get current window position via Accessibility API
   c. Calculate target position in quadrant (CocoaCoordinateManager)
   d. Set new position via Accessibility API
   e. Verify final position
```

### Configuration Search Order

1. `~/.config/mac-app-positioner/config.json`
2. `~/Library/Application Support/MacAppPositioner/config.json`
3. `./config.json` (current directory)
4. `~/.mac-app-positioner/config.json` (legacy)

## Key Design Decisions

- **Shared core logic**: CLI and GUI use identical `CocoaProfileManager` and `CocoaCoordinateManager` to ensure consistent behavior
- **Top-left internal coordinates**: Aligns with Accessibility API, avoiding per-window conversion
- **Explicit builtin screen detection**: `getBuiltinScreen()` avoids `NSScreen.main` inconsistency between CLI and GUI apps
- **Resolution-based matching**: Profiles matched by monitor resolution sets, not by arrangement position
- **Singleton managers**: `ConfigManager.shared` and `CocoaCoordinateManager.shared` ensure consistent state
