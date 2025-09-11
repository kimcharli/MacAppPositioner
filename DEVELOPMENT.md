# Development Guide

This guide is for developers who want to contribute to Mac App Positioner or understand its architecture.

## Architecture Overview

Mac App Positioner uses a modular architecture with shared components between CLI and GUI:

```
MacAppPositioner/
├── CLI/
│   └── CocoaMain.swift          # CLI entry point
├── GUI/
│   ├── App.swift                # SwiftUI app definition
│   ├── MenuBarManager.swift     # Menu bar functionality
│   ├── ContentView.swift        # Main GUI window
│   └── DashboardViewModel.swift # View model for GUI
└── Shared/
    ├── CocoaCoordinateManager.swift  # Coordinate system handling
    ├── CocoaProfileManager.swift     # Profile management
    ├── ConfigManager.swift           # Configuration loading
    ├── WindowManager.swift           # Window manipulation
    └── AppUtils.swift               # Utility functions
```

## Core Components

### CocoaCoordinateManager

Handles the native macOS Cocoa coordinate system:
- **Origin**: Bottom-left of the main screen
- **Y-axis**: Increases upward
- **Multi-monitor**: Contiguous coordinate space

Key methods:
- `getAllMonitors()` - Detects all connected monitors
- `setWindowPosition()` - Positions windows using Accessibility API
- `calculateQuadrantPosition()` - Calculates quadrant positions

### CocoaProfileManager

Manages profile detection and application:
- `detectProfile()` - Matches current monitors to configured profiles
- `applyProfile()` - Applies window positions for a profile
- `generateConfigForCurrentSetup()` - Creates config from current state

### WindowManager

Low-level window manipulation using Accessibility API:
- `getWindowFrame()` - Gets current window position
- `setWindowPosition()` - Sets window position
- `setWindowSize()` - Sets window size

### ConfigManager

Handles configuration file management:
- Searches multiple standard locations
- Supports backwards compatibility
- JSON encoding/decoding

## Development Setup

### Prerequisites

1. **Xcode Command Line Tools:**
   ```bash
   xcode-select --install
   ```

2. **Swift 5.0+:**
   ```bash
   swift --version
   ```

### Building

```bash
# Build everything (CLI + GUI with app bundle)
./Scripts/build-all.sh

# Or build individually
./Scripts/build.sh       # CLI tool only
./Scripts/build-gui.sh   # GUI app only

# Or use make
make all

# Run tests
./Scripts/test_all.sh
```

### Testing

The test suite includes:
- Monitor detection tests
- Coordinate system validation
- Positioning logic tests
- Real positioning tests

Run specific tests:
```bash
swift Tests/test_monitor_detection.swift
swift Tests/test_positioning_logic.swift
```

## Coordinate System

### Native Cocoa Coordinates

Mac App Positioner uses the native Cocoa coordinate system exclusively:

```swift
// Cocoa coordinates (bottom-left origin, Y increases upward)
// WARNING: Don't use NSScreen.main directly - see Common Issues #2
let builtinScreen = // ... find builtin screen explicitly
let frame = builtinScreen.frame  // e.g., (0, 0, 2560, 1440)
```

### Accessibility API

The Accessibility API uses screen coordinates directly:

```swift
func setWindowPosition(pid: pid_t, position: CGPoint) {
    let app = AXUIElementCreateApplication(pid)
    // Position is in screen coordinates
    AXUIElementSetAttributeValue(window, kAXPositionAttribute, position)
}
```

### Quadrant Positioning

Windows are positioned in quadrants relative to monitor visible frames:

```swift
func calculateQuadrantPosition(quadrant: String, windowSize: CGSize, visibleFrame: CGRect) -> CGPoint {
    switch quadrant {
    case "top_left":
        return CGPoint(x: visibleFrame.minX, 
                      y: visibleFrame.maxY - windowSize.height)
    case "top_right":
        return CGPoint(x: visibleFrame.maxX - windowSize.width,
                      y: visibleFrame.maxY - windowSize.height)
    // ...
    }
}
```

## Configuration System

### Config File Structure

```json
{
  "version": "1.0",
  "profiles": {
    "profile_name": {
      "monitors": [
        {
          "resolution": "widthxheight",
          "position": "workspace|builtin"
        }
      ]
    }
  },
  "applications": {
    "bundle.id": {
      "workspace": "position",
      "builtin": "position"
    }
  },
  "layout": {
    "workspace": {
      "bundle.id": {
        "position": "quadrant|center|keep"
      }
    }
  }
}
```

### Config Search Locations

The ConfigManager searches in order:
1. `~/.config/mac-app-positioner/config.json`
2. `~/Library/Application Support/MacAppPositioner/config.json`
3. `./config.json` (current directory)
4. `~/.mac-app-positioner/config.json`

## GUI Development

### Menu Bar App

The GUI is a menu bar application using SwiftUI:

```swift
@main
struct MacAppPositionerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            // Empty scene for menu bar app
        }
    }
}
```

### Menu Bar Manager

Handles all menu bar interactions:

```swift
class MenuBarManager: NSObject {
    private var statusItem: NSStatusItem?
    private let profileManager = CocoaProfileManager()
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        // Setup menu items...
    }
    
    @objc func detectCurrentSetup() {
        if let detectedProfile = profileManager.detectProfile() {
            showNotification(title: "Profile Detected", 
                           message: "Current setup matches: \(detectedProfile)")
        }
    }
    
    @objc func autoApplyProfile() {
        if let detectedProfile = profileManager.detectProfile() {
            profileManager.applyProfile(detectedProfile)
            showNotification(title: "Profile Applied", 
                           message: "Applied profile: \(detectedProfile)")
        }
    }
}
```

## Permissions

### Accessibility Permissions

Required for window manipulation:

```swift
// Check if we have accessibility permissions
let trusted = AXIsProcessTrusted()
if !trusted {
    // Prompt user to grant permissions
}
```

### App Bundle Structure

GUI app requires proper bundle structure:

```
MacAppPositionerGUI.app/
├── Contents/
│   ├── Info.plist
│   └── MacOS/
│       └── MacAppPositionerGUI
```

Key Info.plist entries:
- `LSUIElement`: `true` (for menu bar app)
- `NSAppleEventsUsageDescription`: Permission description

## Common Development Tasks

### Adding a New Position Type

1. Update `calculateQuadrantPosition()` in CocoaCoordinateManager
2. Add to position validation in ProfileManager
3. Update documentation

### Supporting New Monitor Layouts

1. Extend monitor detection in CocoaCoordinateManager
2. Update profile matching logic
3. Add test cases

### Adding Application-Specific Handling

Some apps need special handling:

```swift
// Example: Chrome needs activation before positioning
if bundleID == "com.google.Chrome" {
    NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        .first?.activate(options: .activateIgnoringOtherApps)
}
```

## Debugging

### Enable Debug Output

Add debug prints to key methods:

```swift
NSLog("Debug: Monitor detected: \(monitor.resolution)")
print("Debug: Position calculated: \(position)")
```

### Console Logs

View system logs:
```bash
# View logs for GUI app
log show --predicate 'process == "MacAppPositionerGUI"' --last 5m

# Stream logs
log stream --predicate 'process == "MacAppPositionerGUI"'
```

### Common Issues

1. **Coordinate System Issues:**
   - Always use Cocoa coordinates (bottom-left origin)
   - No coordinate conversion needed for Accessibility API

2. **NSScreen.main Behavior Difference (CRITICAL):**
   - **Problem**: `NSScreen.main` returns different screens for CLI vs GUI apps
   - **CLI**: Always returns the actual builtin monitor (at origin 0,0)
   - **GUI**: Returns whichever monitor has mouse focus when app launches
   - **Impact**: Causes incorrect coordinate conversion for external monitors
   - **Solution**: Explicitly find builtin monitor instead of using NSScreen.main:
   ```swift
   // DON'T DO THIS - unreliable in GUI apps
   let mainScreen = NSScreen.main
   
   // DO THIS - explicitly find builtin monitor
   let builtinScreen = NSScreen.screens.first { screen in
       screen.localizedName.contains("Built-in") || 
       screen.localizedName.contains("Liquid") ||
       screen.frame.origin == CGPoint(x: 0, y: 0)
   } ?? NSScreen.main
   ```
   - **Lesson**: Never assume NSScreen.main is consistent across app types

3. **Permission Issues:**
   - GUI app must be in app bundle format
   - Must be granted Accessibility permissions

4. **Window Positioning Failures:**
   - Some apps resist positioning
   - May need activation or delay

## Contributing

### Code Style

- Use Swift naming conventions
- Add comments for complex logic
- Keep functions focused and testable

### Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Update documentation
6. Submit pull request

### Commit Messages

Use conventional commits:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `refactor:` Code refactoring
- `test:` Test updates

## Resources

- [Apple Accessibility API](https://developer.apple.com/documentation/applicationservices/accessibility)
- [NSScreen Documentation](https://developer.apple.com/documentation/appkit/nsscreen)
- [Cocoa Coordinate System](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CocoaDrawingGuide/Transforms/Transforms.html)

## License

MIT License - See LICENSE file for details.