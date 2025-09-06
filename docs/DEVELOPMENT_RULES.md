# Development Rules - Mac App Positioner

## 🚨 MANDATORY RULES FOR ALL DEVELOPERS

**These rules exist because coordinate system issues have caused positioning failures multiple times.**

**Following these rules is NOT optional.**

## 🏗️ Architecture Rules

### Rule 1: Canonical Coordinate System ONLY
```swift
// ✅ ALWAYS: Use canonical coordinate system
class MyNewFeature {
    private let coordinateManager = CanonicalCoordinateManager.shared
    
    func doSomething() {
        let monitors = coordinateManager.getAllMonitors()  // Already canonical
        let position = calculatePosition(monitors[0].frame)  // Pure canonical calculation
        coordinateManager.setWindowPosition(pid: pid, position: position)  // Canonical output
    }
}

// ❌ NEVER: Use legacy coordinate classes
private let coordinateManager = CoordinateManager()  // FORBIDDEN
private let profileManager = ProfileManager()        // FORBIDDEN
private let windowManager = WindowManager()          // FORBIDDEN
```

### Rule 2: No Direct NSScreen Usage in Business Logic
```swift
// ✅ ALLOWED: At API boundaries for data collection
func collectScreenData() -> [CanonicalMonitorInfo] {
    return NSScreen.screens.map { screen in
        // Immediate conversion at boundary
        return CanonicalMonitorInfo(from: screen, referenceScreenHeight: globalHeight)
    }
}

// ❌ FORBIDDEN: NSScreen in calculations or business logic
func calculatePosition() {
    let screen = NSScreen.main  // FORBIDDEN
    let frame = screen.frame    // FORBIDDEN
    // ... calculations using NSScreen data
}
```

### Rule 3: Explicit Coordinate System Documentation
```swift
// ✅ REQUIRED: Document coordinate system for all geometry parameters
func positionWindow(
    canonicalPosition: CGPoint,    // Canonical Quartz coordinates
    canonicalSize: CGSize,         // Size (coordinate-system independent)
    canonicalFrame: CGRect         // Canonical Quartz coordinates
) -> Bool {
    // All parameters explicitly documented
}

// ❌ FORBIDDEN: Ambiguous coordinate parameters
func positionWindow(position: CGPoint, size: CGSize, frame: CGRect) {
    // Which coordinate system? UNCLEAR - FORBIDDEN
}
```

## 🛠️ Implementation Rules  

### Rule 4: Single Screen Reference Per Operation
```swift
// ✅ REQUIRED: Use same screen throughout entire operation
func applyLayout() {
    let primaryScreen = findConfigPrimaryScreen()  // Single screen source
    let canonicalMonitor = CanonicalMonitorInfo(from: primaryScreen, referenceHeight: globalHeight)
    let position = calculatePosition(canonicalMonitor.frame)  // Same screen data
    setWindowPosition(position, pid: pid)  // Consistent throughout
}

// ❌ FORBIDDEN: Mixed screen references
func applyLayout() {
    let primaryScreen = findConfigPrimaryScreen()     // Config screen
    let position = calculatePosition(primaryScreen.frame)
    let converted = convertUsingMainScreen(position)  // DIFFERENT screen - FORBIDDEN
}
```

### Rule 5: API Boundary Pattern Compliance
```swift
// ✅ REQUIRED: Follow boundary pattern strictly
func handleExternalAPI() {
    // 1. INPUT BOUNDARY: Convert immediately
    let cocoaData = externalAPI.getData()  // External API returns Cocoa
    let canonicalData = toCanonical(cocoaData, from: .cocoa, referenceHeight: height)
    
    // 2. BUSINESS LOGIC: Pure canonical
    let result = processData(canonicalData)  // Only canonical coordinates
    
    // 3. OUTPUT BOUNDARY: Convert only if needed
    externalAPI.sendResult(result)  // If API expects canonical (Quartz), no conversion
}

// ❌ FORBIDDEN: Conversion inside business logic
func handleExternalAPI() {
    let cocoaData = externalAPI.getData()
    let result = processDataWithConversion(cocoaData)  // Conversion inside logic - FORBIDDEN
}
```

## 🧪 Testing Rules

### Rule 6: Mandatory Coordinate System Tests
```swift
// ✅ REQUIRED: Round-trip conversion tests for all coordinate handling
func testMyFeature() {
    // Test coordinate system integrity
    let originalCocoa = CGRect(x: 100, y: 200, width: 800, height: 600)
    let canonical = coordinateManager.toCanonical(originalCocoa, from: .cocoa, referenceHeight: height)
    let roundTrip = coordinateManager.fromCanonical(canonical, to: .cocoa, referenceHeight: height)
    XCTAssertEqual(originalCocoa, roundTrip, accuracy: 0.01)  // MUST pass
    
    // Test business logic with canonical coordinates
    let canonicalFrame = CGRect(x: 0, y: 0, width: 3840, height: 2160)  // Explicit canonical
    let position = myFeature.calculatePosition(canonicalFrame)
    // All assertions in canonical coordinates
}

// ❌ FORBIDDEN: Tests without coordinate system validation
func testMyFeature() {
    let position = myFeature.calculatePosition(someFrame)  // Which coordinate system?
    XCTAssertEqual(position, expectedPosition)  // Undefined coordinate system
}
```

### Rule 7: Integration Testing Requirements
```swift
// ✅ REQUIRED: Test with actual multi-monitor setup
func testRealWorldScenario() {
    // Must test with actual monitor configuration
    let monitors = CanonicalCoordinateManager.shared.getAllMonitors()
    XCTAssertGreaterThan(monitors.count, 1, "Integration tests require multi-monitor setup")
    
    // Test primary monitor identification
    let primary = monitors.first { monitor in
        // Use actual config to find primary
        return monitor.resolution == configPrimaryResolution
    }
    XCTAssertNotNil(primary, "Must find config-defined primary monitor")
}
```

## 📋 Code Review Rules

### Rule 8: Mandatory Architecture Review
**All coordinate-related code must be reviewed for**:
- [ ] Uses canonical coordinate system architecture
- [ ] No direct NSScreen usage in business logic  
- [ ] Explicit coordinate system documentation
- [ ] Consistent screen references throughout operation
- [ ] Proper API boundary pattern implementation
- [ ] Coordinate system test coverage

### Rule 9: Red Flag Patterns
**Immediate rejection for**:
- Any usage of deprecated coordinate classes (`CoordinateManager`, `ProfileManager`, `WindowManager`)
- NSScreen coordinates used directly in calculations
- Coordinate conversion inside business logic functions
- Ambiguous coordinate system parameters
- Mixed screen references within single operation
- Missing coordinate system tests

### Rule 10: Documentation Requirements
**All coordinate-related features must include**:
- Coordinate system architecture compliance explanation
- API boundary pattern documentation  
- Test cases covering coordinate system integrity
- Debug output showing coordinate system usage
- Integration with canonical coordinate system components

## 🚫 Forbidden Patterns

### ❌ Legacy Coordinate Classes
```swift
// These classes are DEPRECATED and must not be used
import ProfileManager        // FORBIDDEN
import CoordinateManager     // FORBIDDEN  
import WindowManager         // FORBIDDEN

// Use canonical classes only
import CanonicalProfileManager     // REQUIRED
import CanonicalCoordinateManager  // REQUIRED
```

### ❌ Direct NSScreen Business Logic
```swift
// FORBIDDEN: NSScreen in business logic
func calculatePosition() {
    let mainScreen = NSScreen.main          // FORBIDDEN
    let screenFrame = mainScreen.frame      // FORBIDDEN
    return CGPoint(x: screenFrame.minX + 100, y: screenFrame.minY + 100)
}

// Use canonical coordinate system
func calculatePosition(canonicalFrame: CGRect) -> CGPoint {
    return CGPoint(x: canonicalFrame.minX + 100, y: canonicalFrame.minY + 100)
}
```

### ❌ Late Coordinate Conversion
```swift
// FORBIDDEN: Conversion after calculations
func positionWindow() {
    let cocoaFrame = screen.frame                    // Cocoa coordinates
    let position = calculateInCocoa(cocoaFrame)      // Calculation in Cocoa
    let quartzPosition = convertToQuartz(position)   // Late conversion - FORBIDDEN
}

// Use boundary conversion pattern
func positionWindow() {
    let cocoaFrame = screen.frame                           // API input
    let canonicalFrame = toCanonical(cocoaFrame, .cocoa)    // Immediate conversion
    let position = calculateInCanonical(canonicalFrame)     // Pure canonical calculation
}
```

### ❌ Screen Reference Inconsistency
```swift
// FORBIDDEN: Different screens for calculation vs conversion  
func positionWindow() {
    let primaryScreen = findConfigPrimary()         // Config primary
    let position = calculate(primaryScreen.frame)   // Calculation screen
    let converted = convert(position, NSScreen.main) // DIFFERENT screen - FORBIDDEN
}

// Use consistent screen reference
func positionWindow() {
    let primaryScreen = findConfigPrimary()                    // Single screen
    let canonicalFrame = toCanonical(primaryScreen.frame)      // Same screen
    let position = calculate(canonicalFrame)                   // Same screen data
    let result = toAPI(position, screen: primaryScreen)        // Same screen reference
}
```

## ✅ Approved Patterns

### ✅ Canonical Architecture Implementation
```swift
class NewFeature {
    private let coordinateManager = CanonicalCoordinateManager.shared
    
    func implementFeature() {
        // 1. Get canonical monitor data
        let monitors = coordinateManager.getAllMonitors()
        
        // 2. Find config primary (not NSScreen.main)
        let primary = monitors.first { $0.resolution == configPrimaryResolution }
        
        // 3. Pure canonical calculations
        let position = calculatePosition(
            quadrant: "top_left",
            windowSize: size,
            visibleFrame: primary.visibleFrame  // All canonical
        )
        
        // 4. Canonical output (no conversion needed for Quartz API)
        coordinateManager.setWindowPosition(pid: pid, position: position)
    }
}
```

### ✅ API Boundary Implementation
```swift
func getMonitorData() -> [CanonicalMonitorInfo] {
    // API BOUNDARY: Convert inputs immediately
    let globalHeight = CanonicalCoordinateManager.shared.getGlobalScreenHeight()
    
    return NSScreen.screens.map { screen in
        // Immediate conversion at boundary
        CanonicalMonitorInfo(from: screen, referenceScreenHeight: globalHeight)
    }
}
```

### ✅ Testing Implementation
```swift
func testCoordinateSystemIntegrity() {
    // Test round-trip conversion
    let original = CGRect(x: 0, y: 1329, width: 3840, height: 2160)
    let canonical = coordinateManager.toCanonical(original, from: .cocoa, referenceHeight: 3489)
    let roundTrip = coordinateManager.fromCanonical(canonical, to: .cocoa, referenceHeight: 3489)
    XCTAssertEqual(original, roundTrip, accuracy: 0.01)
    
    // Test business logic with canonical coordinates
    let canonicalFrame = CGRect(x: 0, y: 0, width: 3840, height: 2160)  // Explicit canonical
    let position = feature.calculatePosition(canonicalFrame)
    XCTAssertEqual(position.x, 360.0, accuracy: 1.0)  // Expected canonical result
}
```

## 🎯 Success Criteria

**Code is compliant when**:
- All coordinate handling uses canonical coordinate system architecture
- No direct NSScreen usage in business logic
- All coordinate parameters explicitly documented  
- Consistent screen references throughout operations
- API boundary pattern properly implemented
- Coordinate system test coverage included
- Integration tests pass with multi-monitor setup

**Following these rules prevents the coordinate system issues that have repeatedly affected this project.**

---

*These rules are based on the lessons learned from multiple coordinate system failures. Compliance is mandatory for all developers working on Mac App Positioner.*