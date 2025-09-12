# Development Guide

This guide is for developers who want to contribute to Mac App Positioner or understand its architecture.

## 1. Architecture Overview

Mac App Positioner uses a modular architecture with shared components between the CLI and GUI.

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

## 2. Core Components

-   **`CocoaCoordinateManager`**: Handles screen detection, coordinate system logic, and window positioning calculations.
-   **`CocoaProfileManager`**: Manages profile detection, application logic, and configuration generation.
-   **`WindowManager`**: Provides low-level window manipulation functions using the Accessibility API.
-   **`ConfigManager`**: Handles loading, parsing, and searching for the `config.json` file.
-   **`AppUtils`**: Contains shared utility functions used across the application.

## 3. Development Setup

### Prerequisites
-   **macOS**: 10.15 Catalina or later
-   **Xcode**: 12.0 or later (or just Command Line Tools)
-   **Swift**: 5.0 or later

### Installation
1.  Install Xcode Command Line Tools:
    ```bash
    xcode-select --install
    ```
2.  Clone the repository:
    ```bash
    git clone <repository-url>
    cd MacAppPositioner
    ```
3.  Grant Accessibility permissions for your terminal or IDE in `System Preferences` → `Security & Privacy` → `Privacy` → `Accessibility`.

## 4. Building the Application

Using the provided build scripts is the recommended method. They are maintained to include all necessary files and flags.

```bash
# Build everything (CLI + GUI with app bundle)
./Scripts/build-all.sh

# Or build individually
./Scripts/build.sh       # CLI tool only
./Scripts/build-gui.sh   # GUI app only

# Run all tests
./Scripts/test_all.sh
```

## 5. GUI Application Deployment

This section covers the complete workflow for developing, testing, and deploying the GUI application to prevent common deployment mistakes.

### Step 1: Build After Changes
After modifying any GUI-related code, always run the build script:
```bash
./Scripts/build-gui.sh
```

### Step 2: Test the Development Build
Before deploying, test the version in the `dist/` directory:
```bash
open ./dist/MacAppPositionerGUI
```
**Verification:**
-   Check that your changes work correctly.
-   Verify the "About" menu shows the **current build date/time**.
-   Test all critical functionality (e.g., applying profiles).

### Step 3: Deploy to /Applications/
For permanent installation or to test the "production" version:

**Method A: Manual Drag-and-Drop (Recommended)**
1.  Quit any running instances of the GUI app.
2.  Delete the old version by dragging `/Applications/MacAppPositionerGUI.app` to the Trash.
3.  Copy the new version by dragging `./dist/MacAppPositionerGUI.app` to your `/Applications` folder.
4.  Launch the updated app.

**Method B: Command Line**
```bash
# This may require you to handle permissions manually
rm -rf /Applications/MacAppPositionerGUI.app
cp -r ./dist/MacAppPositionerGUI.app /Applications/
open /Applications/MacAppPositionerGUI.app
```

## 6. Testing

The test suite covers monitor detection, coordinate system validation, and positioning logic.

```bash
# Run all tests
./Scripts/test_all.sh

# Run specific tests manually
swift Tests/test_monitor_detection.swift
swift Tests/test_positioning_logic.swift
```

### Common Test Scenarios
-   Single monitor setup (built-in display only).
-   Dual or triple monitor setups with mixed resolutions.
-   Switching between different profiles.

## 7. Debugging and Common Issues

### Debugging
View system logs for the application to debug issues:
```bash
# Stream logs for the GUI app
log stream --predicate 'process == "MacAppPositionerGUI"'

# Show recent logs
log show --predicate 'process == "MacAppPositionerGUI"' --last 15m
```

### Common Issue #1: GUI Changes Not Reflected
-   **Symptom**: Code changes don't appear in the running application. The "About" menu shows an old build date.
-   **Cause**: You are running an old version from `/Applications/` instead of the newly built version in `dist/`.
-   **Solution**: Always test the `./dist/MacAppPositionerGUI` executable first after building. Then, manually copy the `.app` bundle to `/Applications/` to update the installed version.

### Common Issue #2: `NSScreen.main` Unreliability (CRITICAL)
-   **Problem**: `NSScreen.main` returns different screens for CLI vs. GUI apps, leading to incorrect coordinates.
    -   **CLI**: Reliably returns the main built-in monitor (origin 0,0).
    -   **GUI**: Returns whichever monitor the mouse was on when the app launched.
-   **Solution**: The codebase avoids `NSScreen.main` and instead uses a custom `getBuiltinScreen()` function to explicitly find the primary, built-in display based on its properties. **Never use `NSScreen.main` for coordinate calculations.**

### Common Issue #3: Permission Errors
-   **Symptom**: Window positioning fails silently or `cp` commands fail.
-   **Cause**: The app lacks Accessibility permissions, or you have insufficient permissions for the `/Applications` directory.
-   **Solution**: Grant Accessibility permissions in System Preferences. Use the drag-and-drop method to install the GUI app.

## 8. Key Architectural Concepts

### Coordinate System
The application exclusively uses the native **Cocoa coordinate system**, where the origin `(0,0)` is at the **bottom-left** of the main screen, and the Y-axis value increases upward. No coordinate system translation is required when using the Accessibility API.

### Configuration System
The `ConfigManager` searches for `config.json` in the following order:
1.  `~/.config/mac-app-positioner/config.json`
2.  `~/Library/Application Support/MacAppPositioner/config.json`
3.  `./config.json` (current directory)
4.  `~/.mac-app-positioner/config.json` (legacy)

## 9. Contributing

### Code Style
-   Use Swift naming conventions and follow Apple's API Design Guidelines.
-   Add comments for complex logic.
-   Keep functions focused and testable.

### Pull Request Process
1.  Fork the repository and create a feature branch.
2.  Add tests for new functionality.
3.  Ensure all tests pass (`./Scripts/test_all.sh`).
4.  Update documentation if needed.
5.  Submit a pull request with a clear description of changes.

### Commit Messages
Use [Conventional Commits](https://www.conventionalcommits.org/):
-   `feat:` A new feature
-   `fix:` A bug fix
-   `docs:` Documentation only changes
-   `refactor:` A code change that neither fixes a bug nor adds a feature
-   `test:` Adding missing tests or correcting existing tests

## 10. Resources

-   [Apple Accessibility API](https://developer.apple.com/documentation/applicationservices/accessibility)
-   [NSScreen Documentation](https://developer.apple.com/documentation/appkit/nsscreen)
-   [Cocoa Coordinate System](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CocoaDrawingGuide/Transforms/Transforms.html)

## 11. License

MIT License. See the `LICENSE` file for details.
