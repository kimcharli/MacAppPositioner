# MacAppPositioner Architecture

Native macOS window positioning application using Apple's Cocoa coordinate system.

## Overview

Mac App Positioner is a native macOS application written in Swift that automatically positions application windows according to predefined layouts across multiple monitors. The application uses native AppKit and Accessibility APIs without coordinate conversions.

**CURRENT ARCHITECTURE**: Uses Apple's native Cocoa coordinate system throughout, eliminating coordinate conversion bugs and following macOS best practices.

## Core Components

### CLI Interface
- **`CocoaMain.swift`**: Main CLI entry point using native Cocoa coordinates
- **Command-line arguments**: detect, apply, generate-config, test-coordinates

### GUI Interface  
- **`ContentView.swift`**: Main GUI with tabbed interface
- **`MonitorVisualizationView.swift`**: Visual monitor representation
- **`ProfileManagerView.swift`**: Profile management interface
- **`SettingsView.swift`**: Application preferences

### Core Logic (`MacAppPositioner/Shared/`)
- **`CocoaCoordinateManager.swift`**: Native Cocoa coordinate system manager (no conversions)
- **`CocoaProfileManager.swift`**: Profile-based window positioning using native coordinates
- **`ConfigManager.swift`**: JSON configuration management

## Technology Stack

- **Language**: Swift 5.0+
- **Frameworks**: 
  - AppKit (NSScreen, NSWorkspace, NSApplication)
  - Accessibility (AXUIElement APIs)
  - Foundation (JSON parsing, file I/O)
- **Configuration**: JSON-based configuration with profile support
- **Build System**: Xcode project with command-line target

## Detailed Component Architecture

### 1. Monitor Detection System

The application uses **NSScreen** from AppKit for comprehensive monitor detection:

-   **Primary API: `NSScreen.screens`**
    -   **Purpose:** Provides real-time information about all connected displays
    -   **Data:** Screen dimensions, positions, backing scale factors, and visual frame
    -   **Reliability:** Native macOS framework, always available and up-to-date
-   **Dynamic Detection**: No hardcoded monitor configurations - all setup detected at runtime
-   **Resolution Matching**: Monitors identified by resolution strings (e.g., "3440x1440", "macbook")

### 2. Coordinate System Management

The most critical architectural component, handling macOS coordinate system complexities:

-   **Problem:** macOS uses different coordinate systems:
    -   **Cocoa/NSScreen**: Bottom-left origin for display arrangement
    -   **Accessibility/Window Positioning**: Top-left origin for window placement

-   **Solution:** The `CoordinateManager` class provides coordinate translation:

    ```swift
    func translateRectFromCocoaToQuartz(rect: CGRect) -> CGRect {
        guard let primaryScreen = NSScreen.main else { return rect }
        let primaryScreenHeight = primaryScreen.frame.height
        
        // Flip Y coordinate from bottom-left to top-left origin
        let newY = primaryScreenHeight - rect.origin.y - rect.height
        return CGRect(x: rect.origin.x, y: newY, width: rect.width, height: rect.height)
    }
    ```

-   **Key Insight:** X coordinates remain unchanged; only Y coordinates require transformation
-   **Dynamic Calculation**: Uses current primary screen height for accurate conversion

### 3. Window Positioning System

The `WindowManager` class handles all window manipulation using macOS Accessibility APIs:

-   **Technology:** Direct Swift integration with **Accessibility API** (`AXUIElement`)
-   **Process Flow:**
    1.  Identify running applications via `NSWorkspace.shared.runningApplications`
    2.  Get application process ID (PID) and create `AXUIElementCreateApplication(pid)`
    3.  Access main window using `kAXMainWindowAttribute`
    4.  Read current position/size with `AXUIElementCopyAttributeValue`
    5.  Calculate new position based on quadrant layout
    6.  Apply coordinate system conversion via `CoordinateManager`
    7.  Set new position using `AXUIElementSetAttributeValue` with `kAXPositionAttribute`

-   **Error Handling:** Comprehensive error checking at each API call level
-   **Application-Specific Strategies:** Support for positioning strategies defined in `config.json` for resistant applications

## Application Data Flow

### Command Execution Flow

1.  **Command Parsing**: `main.swift` processes command-line arguments (detect, apply, update, generate-config)
2.  **Configuration Loading**: `ConfigManager` loads and parses `config.json`
3.  **Monitor Detection**: `ProfileManager` queries `NSScreen.screens` for current setup
4.  **Profile Matching**: Compare detected monitors with configured profiles
5.  **Layout Application**: Position applications according to matched profile's layout

### Profile Detection Algorithm

```
1. Get current monitor resolutions from NSScreen.screens
2. Handle special case for built-in display (backing scale factor > 1.0)  
3. Create set of current resolutions
4. Compare against each profile's monitor definitions
5. Return matching profile name or nil
```

### Window Positioning Workflow

```
For each application in layout:
  1. Find running app by bundle identifier
  2. Get current window frame via Accessibility API
  3. Calculate target position in screen quadrant
  4. Convert coordinates from Cocoa to Quartz system
  5. Apply new position via Accessibility API
  6. Validate final position (optional)
```

## Configuration Architecture

- **Profiles**: Named monitor configurations with resolution and position data
- **Layout**: Application-to-quadrant mappings for the primary monitor
- **Applications**: App-specific positioning strategies and settings
- **Validation**: Built-in profile detection and configuration validation