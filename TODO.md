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

## 🚧 CURRENT PHASE: User Interface Development

### Phase 2: SwiftUI Interface
- [ ] **UI Architecture Planning**
    - [ ] Design SwiftUI app structure (separate from CLI tool)
    - [ ] Plan data flow between UI and core logic
    - [ ] Design user experience for profile management
- [ ] **Core UI Components**
    - [ ] Profile list view with current/available profiles
    - [ ] Profile application controls with status feedback
    - [ ] Monitor setup visualization/detection display
    - [ ] Settings/preferences interface
- [ ] **Profile Management UI**
    - [ ] Create new profile interface
    - [ ] Edit existing profiles (rename, modify layout)
    - [ ] Delete profiles with confirmation
    - [ ] Import/export profile configurations
- [ ] **Real-time Features**
    - [ ] Live monitor detection and display
    - [ ] Application status indicators (running/not running)
    - [ ] Window positioning preview/validation
- [ ] **Integration**
    - [ ] Connect SwiftUI interface with existing core logic
    - [ ] Maintain backward compatibility with CLI tool
    - [ ] Share configuration files between UI and CLI versions

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

### Phase 4: Advanced Features (Remaining)
- [ ] **Layout Snapshots**
    - [ ] Capture current window positions across all monitors  
    - [ ] Save captured layout as new profile
    - [ ] Smart application detection and bundle ID resolution
    - [ ] Handle applications with multiple windows
- [ ] **Dynamic Profile Management**
    - [ ] Auto-create profiles when new monitor setups detected
    - [ ] Smart profile suggestions based on usage patterns
    - [ ] Profile templates for common setups (laptop only, dual monitor, etc.)
- [ ] **Advanced Positioning**
    - [ ] Custom positioning beyond quadrants (percentage-based, absolute coordinates)
    - [ ] Window sizing in addition to positioning  
    - [ ] Support for multiple windows per application
    - [ ] Application-specific positioning strategies and rules

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

**Current State:** Fully functional command-line application
- ✅ Core window positioning engine complete
- ✅ Multi-monitor support working
- ✅ Configuration system robust and flexible
- ✅ Documentation comprehensive
- ✅ Ready for GUI development

**Next Priority:** SwiftUI interface development to make the application accessible to non-technical users

**Architecture Decision:** Keep CLI tool available while adding GUI - both interfaces can share the same core logic classes.
