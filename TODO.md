# Mac App Positioner - TODO

This file tracks the development tasks for the Mac App Positioner application.

## ✅ COMPLETED PHASES

### Phase 1: Core Functionality ✅
- [x] Project Setup: Create basic project structure and files
- [x] Configuration Management:
    - [x] Define JSON structure for layout profiles (see config.json)
    - [x] Create config.json with sample profiles (home, office configurations)
    - [x] Implement ConfigManager.swift to parse configuration files
    - [x] Support for profile detection and matching
- [x] Window Management:
    - [x] Implement getWindowFrame using Accessibility API (WindowManager.swift)
    - [x] Implement setWindowPosition using Accessibility API
    - [x] Implement setWindowSize and setWindowFrame methods
    - [x] Add comprehensive error handling and accessibility error descriptions
    - [x] Test window positioning with real applications
- [x] Profile Application:
    - [x] Create ProfileManager.applyProfile function
    - [x] Reads config, identifies running apps by bundle ID, positions windows
    - [x] Coordinate system conversion (CoordinateManager.swift)
    - [x] Quadrant-based positioning on primary monitor

### Phase 4: Advanced Features (Partially Complete) ✅
- [x] Multi-Display Support:
    - [x] Implement screen detection via NSScreen.screens
    - [x] Support for multiple monitor configurations  
    - [x] Dynamic monitor arrangement detection
    - [x] Primary/secondary monitor designation
    - [x] Built-in display detection and handling
- [x] Configuration Management:
    - [x] Multiple profile support with monitor definitions
    - [x] Profile auto-detection based on current setup
    - [x] Profile updating with current monitor configuration
    - [x] Configuration generation for current setup
- [x] Error Handling and Documentation:
    - [x] Comprehensive error handling throughout codebase
    - [x] Complete documentation suite (Architecture, Usage, Development, Troubleshooting)
    - [x] Accessibility permission guidance in documentation
    - [x] Inline code documentation for all Swift files

---

## ✅ RECENTLY COMPLETED: Native Cocoa Coordinate System & GUI Implementation

### Major Architecture Transformation ✅
- [x] **Native Cocoa Coordinate System Implementation**
    - [x] Updated DEVELOPMENT_RULES.md to mandate Apple's native Cocoa coordinate system as official standard
    - [x] Added Apple documentation reference: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CocoaDrawingGuide/Transforms/Transforms.html
    - [x] Completely eliminated all custom coordinate conversions (removed Canonical* files)
    - [x] Refactored to use direct NSScreen.frame usage throughout
    - [x] Implemented proper Accessibility API coordinate conversion at system boundary only
    
- [x] **Terminology Standardization**
    - [x] Replaced all "primary" references with "workspace" to avoid NSScreen.main confusion
    - [x] Updated config.json with workspace/builtin monitor distinction
    - [x] Added proper CodingKeys enum to Layout struct for JSON mapping
    
- [x] **Critical Bug Fixes**
    - [x] Fixed workspace monitor detection bug (was using first profile instead of specified profile)
    - [x] Resolved Chrome positioning on wrong monitor issue
    - [x] Implemented exact corner positioning with no padding using actual window dimensions
    - [x] Fixed Accessibility API coordinate conversion for workspace monitor (negative Y coordinates)
    - [x] Documented all coordinate system issues and fixes in COORDINATE_SYSTEM_ISSUES.md

### Complete Project Structure Overhaul ✅
- [x] **Swift Project Standards Implementation**
    - [x] Reorganized to Scripts/ folder for build scripts (build.sh, build-gui.sh)
    - [x] Created Tests/ folder for all test files
    - [x] Added dist/ folder for compiled binaries
    - [x] Cleaned up root directory following Swift Package Manager conventions
    
- [x] **Obsolete Code Removal**
    - [x] Removed all Canonical* coordinate system files
    - [x] Cleaned up test_ files and moved remaining to Tests/ folder
    - [x] Removed CanonicalMain.swift and updated CLI to CocoaMain.swift
    - [x] Updated all documentation to remove Canonical references

### Phase 2: Complete SwiftUI GUI Implementation ✅
- [x] **SwiftUI App Target Complete**
    - [x] Created full SwiftUI application with App.swift and ContentView.swift
    - [x] Implemented all core GUI components (MonitorVisualizationView, ProfileManagerView, SettingsView)
    - [x] Fixed GUI compilation errors after coordinate system changes
    - [x] Verified GUI uses native Cocoa coordinate system throughout
    
- [x] **Basic Profile Interface Complete**
    - [x] Display list of available profiles with current/active profile indication
    - [x] Functional "Apply Profile" buttons with real-time status feedback
    - [x] Monitor setup visualization showing current configuration
    
- [x] **GUI-CLI Integration Verified**
    - [x] Confirmed GUI uses same ProfileManager, CoordinateManager core logic
    - [x] Tested both CLI and GUI work simultaneously without conflicts
    - [x] Validated shared config.json usage between interfaces

**Result**: Both CLI and GUI applications fully functional with native Cocoa coordinate system

---

## 🚧 CURRENT PHASE: Advanced Features & Polish

### Next Priority Features
- [ ] **Enhanced Profile Management**
    - [ ] Create new profile interface in GUI
    - [ ] Edit existing profiles (rename, modify layout)
    - [ ] Delete profiles with confirmation
    - [ ] Import/export profile configurations
    
- [ ] **Layout Snapshots**
    - [ ] Capture current window positions across all monitors  
    - [ ] Save captured layout as new profile
    - [ ] Smart application detection and bundle ID resolution
    - [ ] Handle applications with multiple windows
    
- [ ] **Advanced Positioning Options**
    - [ ] Custom positioning beyond quadrants (percentage-based, absolute coordinates)
    - [ ] Window sizing in addition to positioning  
    - [ ] Support for multiple windows per application
    - [ ] Application-specific positioning strategies and rules

---

## 📋 UPCOMING PHASES

### Phase 3: Menu Bar App
- [ ] **Menu Bar Integration**
    - [ ] Convert SwiftUI app to menu bar application
    - [ ] Create menu bar icon and menu structure
    - [ ] Quick profile switching from menu bar
    - [ ] Status indicators in menu bar
- [ ] **Background Operation**
    - [ ] Run silently in background
    - [ ] Minimize memory footprint
    - [ ] Handle system sleep/wake events
- [ ] **Keyboard Shortcuts**
    - [ ] Global hotkeys for profile switching
    - [ ] Customizable keyboard shortcuts
    - [ ] Conflict detection with system shortcuts

### Phase 4: Intelligence & Automation
- [ ] **Dynamic Profile Management**
    - [ ] Auto-create profiles when new monitor setups detected
    - [ ] Smart profile suggestions based on usage patterns
    - [ ] Profile templates for common setups (laptop only, dual monitor, etc.)
    - [ ] Machine learning-based layout optimization
- [ ] **Real-time Features**
    - [ ] Live monitor detection and display
    - [ ] Application status indicators (running/not running)
    - [ ] Window positioning preview/validation
    - [ ] Automatic profile switching based on connected monitors

### Phase 5: Polish and Distribution
- [ ] **User Experience Improvements**
    - [ ] Onboarding flow for new users
    - [ ] Better accessibility permission handling
    - [ ] Visual feedback for window positioning actions
    - [ ] Undo/redo functionality for layout changes
- [ ] **Testing and Quality**
    - [ ] Unit tests for core functionality
    - [ ] UI tests for SwiftUI components
    - [ ] Performance testing with many applications
    - [ ] Compatibility testing across macOS versions
- [ ] **Distribution Preparation**
    - [ ] Code signing and notarization
    - [ ] App Store preparation (if desired)
    - [ ] Installation package creation
    - [ ] User documentation and help system

---

## 📊 PROGRESS SUMMARY

**Current State:** Complete dual-interface application with native Cocoa coordinate system

- ✅ **Native Cocoa coordinate system** implemented following Apple's official standards
- ✅ **Both CLI and GUI applications** fully functional and battle-tested
- ✅ **Exact window positioning** with zero padding and proper coordinate conversion
- ✅ **Multi-monitor support** with workspace/builtin monitor distinction
- ✅ **Project structure** organized following Swift Package Manager conventions
- ✅ **Comprehensive documentation** including coordinate system issue reference
- ✅ **Clean codebase** with all obsolete coordinate conversion code removed

**Next Priority:** Enhanced profile management and layout snapshots

**Architecture Achievement:** Native Cocoa coordinate system provides precise, reliable positioning while CLI and GUI share identical core logic (CocoaProfileManager, CocoaCoordinateManager, ConfigManager) ensuring consistent behavior across interfaces.

**Key Technical Success:** Resolved all coordinate system confusion by implementing Apple's native Cocoa standard, eliminating custom conversions, and achieving exact corner positioning through proper Accessibility API boundary conversion.
