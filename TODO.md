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

## 🏛️ Architectural Improvements & Refactoring

This section lists tasks focused on improving the codebase's architecture, adhering to best practices, and refactoring for long-term maintainability.

### High Priority - Code Cleanup & Bug Prevention
- [x] **Remove Obsolete Files:**
    - [x] Delete `MacAppPositioner/CLI/main.swift` to eliminate the redundant CLI entry point. The project has standardized on `CocoaMain.swift`.
    - [x] Delete `MacAppPositioner/Shared/CoordinateManager.swift`. This file contains legacy coordinate conversion logic that is explicitly forbidden by the project's architectural rules. Its presence is a major risk for re-introducing coordinate system bugs.
- [x] **Refactor Hardcoded Values:**
    - [x] Remove the hardcoded `1329` value in `CocoaCoordinateManager.swift`. This value is used to determine the vertical position of the workspace monitor. This should be replaced with a dynamic calculation based on the actual main screen's frame height to make the application more robust and adaptable to different monitor configurations.

### Medium Priority - Feature Implementation & Refactoring
- [x] **Implement Missing Functionality:**
    - [x] Complete the implementation of the `update` command in the CLI.
    - [ ] Implement the profile editing and creation features in the GUI's `ProfileManagerView.swift`.
- [x] **Improve GUI State Management:**
    - [x] Refactor the SwiftUI views to use `ObservableObject` view models instead of simple `@State` variables. This will improve state management, especially as the GUI becomes more complex.
- [x] **Enhance Error Handling:**
    - [x] Provide more specific and user-friendly error messages in both the CLI and GUI. For example, when `config.json` is invalid, the error message should indicate the specific parsing error and line number if possible.

### Low Priority - Nice-to-have & Future Enhancements
- [x] **Add More Code Comments:**
    - [x] Add comments to the code to explain complex logic and design decisions, especially in `CocoaProfileManager.swift` and `CocoaCoordinateManager.swift`.

---

## � CODE REVIEW FINDINGS & FIX PLAN

> Code review performed 2026-02-27. Items are ordered by severity: bugs first, then deduplication, then modularity, then best practices.

### 🔴 Bugs (Data Loss / Incorrect Behaviour)

- [ ] **[BUG] Profile rename silently deletes the profile** (`ProfileManagerView.swift` — `EditProfileView.updateProfileName()`)
    - `config.profiles.removeValue(forKey: originalProfileName)` is called but the new key is never inserted before `saveConfig()`.
    - Fix: add `config.profiles[trimmedName] = profile` before saving.

- [ ] **[BUG] `saveConfig()` always writes to `./config.json`** (`ConfigManager.swift`)
    - `loadConfig()` searches 4 locations and loads whichever exists; `saveConfig()` always writes to the current working directory regardless.
    - Fix: store the URL used during a successful load in `private var loadedConfigURL: URL?` and write back to it in `saveConfig()`.

### 🟡 Duplication (DRY Violations)

- [ ] **[DEDUP] Monitor → position label mapping copy-pasted in 3 files**
    - Same `builtin` / `workspace` / `secondary` string mapping appears in:
        1. `CocoaProfileManager.updateProfile()`
        2. `CocoaProfileManager.generateConfigForCurrentSetup()` (slightly different: uses index instead of `isWorkspace`)
        3. `ProfileManagerView.CreateProfileView.createProfile()`
    - Fix: extract a single `positionLabel(for monitor: CocoaMonitorInfo) -> String` free function or static method on `CocoaCoordinateManager`.

- [ ] **[DEDUP] `DashboardViewModel.detectCurrentMonitors()` creates a redundant `CocoaProfileManager` instance**
    - `let profileManager = CocoaProfileManager()` is declared inside a private method while `self.profileManager` already exists on the class.
    - Fix: replace the local instance with `self.profileManager`.

- [ ] **[DEDUP] `CocoaProfileManager.generatePlan()` accesses `ConfigManager.shared` directly**
    - All other methods in the class use `self.configManager`; `generatePlan()` bypasses it with `ConfigManager.shared.loadConfig()`.
    - Fix: replace with `configManager.loadConfig()`.

- [ ] **[DEDUP] `BuiltinApp` and `WorkspaceApp` are near-identical structs**
    - Both have `position`, `sizing`, an identical legacy-string decode branch, and identical `CodingKeys`.
    - Fix: consolidate into a single `AppLayoutEntry` struct (making `position` optional with a default) or extract a shared `AppLayoutCodable` protocol with a default `init(from:)`.

### 🟠 Modularity

- [ ] **[MODULAR] Dual monitor model: `CocoaMonitorInfo` (Shared) vs `MonitorInfo` (GUI)**
    - `DashboardViewModel.detectCurrentMonitors()` manually copies every field from `CocoaMonitorInfo` into `MonitorInfo`. `MonitorInfo` provides no additional semantics — it is a flattened mirror.
    - Fix: make `CocoaMonitorInfo` conform to `Identifiable` and use it directly in `MonitorVisualizationView`, deleting `MonitorInfo` and the conversion loop.

- [ ] **[MODULAR] `ConfigManager` injected into sub-views without a protocol**
    - `CreateProfileView` and `EditProfileView` receive `configManager: ConfigManager` but since `ConfigManager` is a concrete singleton, injection adds parameter noise without testability.
    - Fix: introduce a `ConfigManaging` protocol (with `loadConfig()` / `saveConfig(_:)`) that `ConfigManager` conforms to, and use the protocol type for injection — or remove the injection and access `.shared` directly in those small views.

- [ ] **[MODULAR] `ConfigManager` cache cannot be invalidated externally**
    - There is no public `invalidateCache()` / `reload()` method. External file changes (or future sync features) cannot force a reload.
    - Fix: add `func invalidateCache()` that sets `cachedConfig = nil`.

### 🔵 Best Practices

- [ ] **[PRACTICE] `CocoaMonitorInfo.init` uses `NSScreen.main`** (`CocoaCoordinateManager.swift`)
    - `self.isMain = nsScreen == NSScreen.main` violates the rule in `AGENTS.md`: "Avoid `NSScreen.main`".
    - `isMain` is never consumed anywhere in the codebase.
    - Fix: remove the `isMain` property entirely, or replace with `isBuiltIn`-based logic.

- [ ] **[PRACTICE] `accessibilityErrorDescription(_:)` is dead code** (`CocoaCoordinateManager.swift`)
    - The `private` method is never called.
    - Fix: either wire it into `setWindowPosition()` for better error logging, or delete it.

- [ ] **[PRACTICE] Position and monitor-role values are untyped raw strings**
    - `"top_left"`, `"top_right"`, `"center"`, `"keep"`, `"builtin"`, `"workspace"` appear as string literals in conditionals, decoders, and generated config templates across multiple files.
    - Fix: introduce a `WindowPosition` enum and a `MonitorRole` enum; make the `switch` in `calculateQuadrantPosition()` exhaustive.

- [ ] **[PRACTICE] `SettingsView.defaultProfile` picker is not persisted**
    - The picker updates an `@State` variable but nothing writes it to `UserDefaults` or config; the selected value is discarded on next launch.
    - Fix: persist the selection via `@AppStorage("defaultProfile")` or write it to `Config`.

- [ ] **[PRACTICE] Magic numbers not centralised as named constants**
    - `defaultWindowSize = CGSize(width: 1200, height: 800)` lives in `CocoaProfileManager`.
    - Placement tolerance `1.0` appears independently in both `setWindowPosition()` and `createAppAction()`.
    - Fix: move shared constants to a `Constants.swift` or a dedicated `enum Constants` namespace in `AppUtils.swift`.

---

## �📋 UPCOMING PHASES

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