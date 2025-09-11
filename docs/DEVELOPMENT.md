# Development Guide

This guide covers setting up the development environment, building, testing, and contributing to Mac App Positioner.

## Prerequisites

### System Requirements
- **macOS**: 10.15 Catalina or later
- **Xcode**: 12.0 or later
- **Swift**: 5.0 or later
- **Accessibility**: System Preferences → Security & Privacy → Privacy → Accessibility

### Development Tools
- **Xcode**: Primary IDE for Swift development
- **Command Line Tools**: `xcode-select --install`
- **Git**: For version control

## Project Setup

### 1. Clone Repository
```bash
git clone <repository-url>
cd MacAppPositioner
```

### 2. Open in Xcode
```bash
# Option 1: Open from command line
open MacAppPositioner.xcodeproj

# Option 2: Open from Xcode File menu
# File → Open → Select MacAppPositioner.xcodeproj
```

### 3. Configure Project Settings
- **Target**: macOS Command Line Tool
- **Minimum Deployment Target**: macOS 10.15
- **Swift Language Version**: 5.0
- **Frameworks**: AppKit, Foundation

## Building the Application

### From Xcode
1. Select the MacAppPositioner scheme
2. Choose Product → Build (⌘+B)
3. Executable will be built to `DerivedData` folder

### From Command Line

#### Option 1: Using build.sh (Recommended)
```bash
# Simple one-command build
./Scripts/build.sh

# Output:
# 🏗️  Building Mac App Positioner...
# ✅ Build successful!
#    Run with: ./MacAppPositioner/MacAppPositioner <command>
```

The `build.sh` script provides:
- **Error checking** - Validates Swift compiler availability
- **User feedback** - Clear success/failure messages with next steps
- **Dependency documentation** - Shows required frameworks and source files
- **CI/CD friendly** - Proper exit codes for automation

#### Option 2: Using xcodebuild
```bash
# Build debug version
xcodebuild -project MacAppPositioner.xcodeproj -scheme MacAppPositioner -configuration Debug

# Build release version
xcodebuild -project MacAppPositioner.xcodeproj -scheme MacAppPositioner -configuration Release

# Build to specific location
xcodebuild -project MacAppPositioner.xcodeproj -scheme MacAppPositioner -configuration Release SYMROOT=./build
```

#### Option 3: Direct Swift Compilation
```bash
# Manual compilation (same as build.sh internally)
swiftc -o MacAppPositioner/MacAppPositioner \
    MacAppPositioner/Source/main.swift \
    MacAppPositioner/Source/WindowManager.swift \
    MacAppPositioner/Source/ConfigManager.swift \
    MacAppPositioner/Source/ProfileManager.swift \
    MacAppPositioner/Source/CoordinateManager.swift \
    -framework AppKit
```

## Development Workflow

### Code Organization
```
MacAppPositioner/Source/
├── main.swift              # CLI entry point and argument parsing
├── ProfileManager.swift    # Profile detection and application
├── WindowManager.swift     # Window positioning via Accessibility API  
├── CoordinateManager.swift # Coordinate system conversions
└── ConfigManager.swift     # JSON configuration loading
```

### Configuration Files
- **config.json**: Application configuration (profiles, layouts, settings)
- **MacAppPositioner.xcodeproj**: Xcode project configuration
- **docs/**: Documentation files

### Key Development Principles
1. **Dynamic over Static**: Always detect monitor setup dynamically
2. **Error Handling**: Comprehensive error checking for all API calls
3. **Coordinate Awareness**: Properly handle macOS coordinate system differences
4. **Modular Design**: Keep concerns separated in distinct classes

## GUI Application Deployment

This section covers the complete workflow for developing, testing, and deploying the GUI application to prevent common deployment mistakes.

### Development Workflow

#### 1. After Making GUI Changes

Always follow this exact sequence after modifying any GUI-related code:

```bash
# Step 1: Build the application
./Scripts/build-gui.sh

# Step 2: Test the development version
open ./dist/MacAppPositionerGUI

# Step 3: Verify functionality
# - Check that your changes work correctly
# - Verify About menu shows current build date/time
# - Test all critical functionality
```

#### 2. Deployment to /Applications/ (Optional)

For permanent installation or testing the "production" version:

**Method A: Manual (Recommended)**
1. Quit any running GUI instances (menu bar → Quit)
2. Delete old app: Drag `/Applications/MacAppPositionerGUI.app` to Trash
3. Copy new app: Drag `./dist/MacAppPositionerGUI.app` to Applications folder
4. Launch updated app: Double-click or `open /Applications/MacAppPositionerGUI.app`

**Method B: Command Line (May Require Permissions)**
```bash
# Remove old version (may require permission)
rm -rf /Applications/MacAppPositionerGUI.app

# Copy new version  
cp -r ./dist/MacAppPositionerGUI.app /Applications/

# Launch updated app
open /Applications/MacAppPositionerGUI.app
```

#### 3. Verification Steps

After deployment, always verify:

1. **Build Timestamp**: Menu bar → About → Build Date should show **current compile time**
2. **Copyright Year**: Should show **© 2025** (not 2024)
3. **Functionality**: Test key features (apply profile, detect profile, etc.)
4. **Log Output**: Check console logs show expected behavior

### Common Deployment Issues

#### Issue 1: Wrong Build Date in About Menu
**Symptom**: About menu shows old date (e.g., Sep 8 instead of current date)
**Cause**: Testing old cached version or didn't rebuild
**Solution**: 
```bash
rm -rf ./dist/MacAppPositionerGUI.app    # Clean build
./Scripts/build-gui.sh                   # Fresh build
open ./dist/MacAppPositionerGUI          # Test fresh version
```

#### Issue 2: Changes Not Reflected in GUI  
**Symptom**: Code changes don't appear in running application
**Cause**: Testing `/Applications/` version without updating it
**Solution**:
- Always test `./dist/` version first after building
- Manually copy to `/Applications/` if needed
- Verify About menu timestamp matches build time

#### Issue 3: Permission Denied on /Applications/
**Symptom**: `cp` command fails with permission errors
**Cause**: macOS protecting Applications folder
**Solution**: Use manual drag-and-drop method instead of command line

#### Issue 4: GUI Positioning Still Broken
**Symptom**: Apply function still has NSScreen.main issues
**Cause**: Using old cached version
**Solution**:
- Verify About menu shows recent build date
- Check logs for "getBuiltinScreen: Found builtin by name" message
- Force quit all GUI instances and relaunch

### Build Artifacts and Locations

**Development Builds**: `./dist/MacAppPositionerGUI` (CLI-style executable)
**App Bundle**: `./dist/MacAppPositionerGUI.app` (for /Applications/)
**Production Install**: `/Applications/MacAppPositionerGUI.app`

### Debugging Build Issues

#### Check Executable Timestamp
```bash
ls -la ./dist/MacAppPositionerGUI.app/Contents/MacOS/MacAppPositionerGUI
```

#### Force Clean Build
```bash
rm -rf ./dist/MacAppPositionerGUI.app
./Scripts/build-gui.sh
```

#### Monitor GUI Logs
```bash
./dist/MacAppPositionerGUI > gui_output.log 2>&1 &
tail -f gui_output.log
```

### Cross-Reference
📋 **Quick deployment checklist**: See `CLAUDE.md` in project root

### Documentation Maintenance System

This project uses an automated documentation maintenance system to keep deployment guides current and prevent recurring issues.

#### Auto-Triggered Documentation Updates

The documentation system automatically activates when certain patterns are detected:

**Primary Triggers:**
- "deployment docs need updating"
- "documentation maintenance needed"
- "add this to troubleshooting guide"  
- "deployment process broken"
- "GUI deployment issue"

**Technical Issue Triggers:**
- "NSScreen.main issue" 
- "wrong build date in About"
- "permission denied Applications"
- "cached version problem"
- "positioning still broken"

#### Manual Documentation Commands

Use these commands to manually trigger documentation maintenance:

```bash
# Comprehensive review and sync between CLAUDE.md ↔ DEVELOPMENT.md
/task "Review and update deployment documentation consistency" --agent document-reviewer

# Add specific new issue to troubleshooting
/task "Add [specific issue description] to deployment troubleshooting guide" --agent document-reviewer  

# Validate cross-references and consistency
/task "Synchronize deployment docs between CLAUDE.md and DEVELOPMENT.md" --agent document-reviewer

# Update after major GUI changes
/task "Update deployment workflow documentation after GUI architecture changes" --agent document-reviewer
```

#### Documentation Update Process

When triggered, the system:

1. **Analyzes Current Issue** - Identifies the type of deployment problem
2. **Determines Update Scope** - Quick fix (CLAUDE.md) vs comprehensive (DEVELOPMENT.md)
3. **Updates Appropriate Sections** - Troubleshooting, workflows, or reference materials
4. **Maintains Consistency** - Ensures cross-references remain accurate
5. **Validates Solutions** - Confirms updated docs would prevent the issue

#### Adding New Issues to Documentation

When you encounter a new deployment issue:

1. **Document the Problem** - Describe symptoms, cause, and solution
2. **Use Trigger Phrases** - "add this to troubleshooting guide"  
3. **Provide Context** - Include error messages, steps that failed
4. **Verify the Fix** - Test that the documented solution works

Example:
```
"I encountered a new issue where the GUI app shows a blank menu bar after copying to Applications. This happens when macOS quarantines the app. Add this to troubleshooting guide: 

Issue: Blank menu bar in GUI app
Cause: macOS quarantine on copied app
Solution: Run 'xattr -dr com.apple.quarantine /Applications/MacAppPositionerGUI.app' 
```

## Testing

### Manual Testing

#### Test Profile Detection
```bash
# Build and test profile detection
./MacAppPositioner detect

# Expected output: Detected profile name or "No matching profile detected"
```

#### Test Configuration Generation
```bash
# Generate monitor configuration
./MacAppPositioner generate-config

# Expected output: JSON monitor configuration for current setup
```

#### Test Profile Application
```bash
# Apply a specific profile
./MacAppPositioner apply office

# Expected: Applications move to configured positions
# Check console output for success/failure messages
```

### Automated Testing Strategy

#### Unit Tests (Recommended)
```swift
// Example test structure
import XCTest
@testable import MacAppPositioner

class CoordinateManagerTests: XCTestCase {
    func testCoordinateTranslation() {
        // Test coordinate system conversion
    }
    
    func testBoundaryConditions() {
        // Test edge cases and error conditions
    }
}
```

#### Integration Tests
- Test with multiple monitor configurations
- Test with different application states
- Validate accessibility permissions

### Common Test Scenarios
1. **Single monitor setup**: Built-in display only
2. **Dual monitor setup**: Built-in + external
3. **Triple monitor setup**: Multiple external displays
4. **Mixed resolutions**: Different sized monitors
5. **Profile switching**: Changing between configurations

## Debugging

### Enable Debug Output
```swift
// Add debug prints in key locations
print("Debug: Current screen count: \(NSScreen.screens.count)")
print("Debug: Profile detection result: \(profileName)")
```

### Common Issues

#### Accessibility Permissions
- **Problem**: Window positioning fails silently
- **Solution**: Enable in System Preferences → Security & Privacy → Privacy → Accessibility
- **Check**: Use `tccutil` to verify permissions

#### Coordinate System Problems
- **Problem**: Windows positioned incorrectly
- **Debug**: Log both Cocoa and Quartz coordinates
- **Solution**: Verify `CoordinateManager.translateRectFromCocoaToQuartz` logic

#### Profile Detection Failures
- **Problem**: No matching profile found
- **Debug**: Compare detected resolutions vs configured resolutions
- **Solution**: Use `generate-config` to see current monitor setup

### Debugging Tools
```bash
# View system display configuration
system_profiler SPDisplaysDataType

# Check running applications
ps aux | grep -i "application_name"

# Monitor system logs
log stream --predicate 'process == "MacAppPositioner"'
```

## Code Style and Conventions

### Swift Style Guidelines
- Use Swift naming conventions (camelCase for functions/variables)
- Include comprehensive error handling with meaningful messages
- Add inline documentation for complex logic
- Follow Apple's Swift API Design Guidelines

### Documentation Standards
- Document all public methods and classes
- Include parameter descriptions and return values
- Provide usage examples for complex functionality
- Keep documentation up-to-date with code changes

## Contributing

### Development Process
1. **Fork** the repository
2. **Create** feature branch: `git checkout -b feature/new-feature`
3. **Develop** with proper testing
4. **Commit** with clear messages: `git commit -m "Add monitor detection improvement"`
5. **Push** to fork: `git push origin feature/new-feature`
6. **Submit** pull request with description

### Pull Request Guidelines
- Include clear description of changes
- Reference any related issues
- Include test results and screenshots if applicable
- Follow existing code style and conventions
- Update documentation for user-facing changes

### Code Review Checklist
- [ ] Follows dynamic detection principles
- [ ] Handles coordinate systems correctly
- [ ] Includes proper error handling
- [ ] Maintains backward compatibility
- [ ] Updates relevant documentation
- [ ] Tested on multiple monitor configurations

## Advanced Development

### Extending Functionality

#### Adding New Commands
1. Update `main.swift` switch statement
2. Add new method to appropriate manager class
3. Update help documentation
4. Add test cases for new functionality

#### Supporting New Positioning Strategies
1. Extend `AppSettings` struct in `ConfigManager.swift`
2. Add strategy handling in `ProfileManager.swift`
3. Update configuration documentation
4. Test with target applications

#### Multi-Monitor Layout Support
1. Extend layout configuration structure
2. Update coordinate calculation logic
3. Add monitor-specific positioning methods
4. Test across different monitor arrangements

### Performance Considerations
- Minimize API calls during position detection
- Cache screen information when possible
- Handle large numbers of applications efficiently
- Optimize coordinate calculations

### Future Enhancements
- GUI application with menu bar integration
- Real-time monitor change detection
- Window size adjustment in addition to positioning
- Application-specific window rules
- Keyboard shortcuts for layout switching