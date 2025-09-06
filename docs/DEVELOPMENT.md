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
./build.sh

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