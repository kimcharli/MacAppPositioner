# Development Rules - Mac App Positioner

## 🚨 MANDATORY RULES FOR ALL DEVELOPERS

**These rules exist because coordinate system issues have caused positioning failures multiple times.**

**Following these rules is NOT optional.**

## 📐 COORDINATE SYSTEM STANDARD

**OFFICIAL APPLE REFERENCE**: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CocoaDrawingGuide/Transforms/Transforms.html

**MANDATORY**: All coordinate handling MUST use **Cocoa Contiguous Mode** as the native macOS coordinate system.

**Key Requirements**:
- **Bottom-left origin**: (0,0) at bottom-left of primary screen
- **Y-axis increases upward**: Consistent with macOS native behavior
- **Contiguous coordinate space**: Unified across all monitors
- **NSScreen.frame coordinates**: Use directly without conversion

## 🏗️ Architecture Rules

### Rule 1: Native Cocoa Coordinate System ONLY
```swift
// ✅ ALWAYS: Use native Cocoa coordinates (bottom-left origin, Y increases upward)
class MyNewFeature {
    func doSomething() {
        // Use NSScreen.frame directly - it's already in native Cocoa coordinates
        let screens = NSScreen.screens
        let primaryFrame = screens[0].frame  // Native Cocoa coordinates
        let position = calculatePosition(primaryFrame)  // Pure Cocoa calculation
        setWindowPosition(pid: pid, position: position)  // Native Cocoa output
    }
}

// ❌ NEVER: Convert native coordinates or use custom coordinate systems
private let coordinateManager = CocoaCoordinateManager.shared  // REQUIRED - native coordinates
private let customCoords = convertToTopLeft(screen.frame)     // FORBIDDEN - fights native system
```

### Rule 2: Direct NSScreen Usage is ENCOURAGED
```swift
// ✅ ENCOURAGED: Use NSScreen directly throughout application
func collectScreenData() -> [MonitorInfo] {
    return NSScreen.screens.map { screen in
        // Use native Cocoa coordinates directly - no conversion needed
        return MonitorInfo(
            frame: screen.frame,        // Native Cocoa coordinates
            visibleFrame: screen.visibleFrame  // Native Cocoa coordinates
        )
    }
}

// ✅ ENCOURAGED: NSScreen in calculations and business logic
func calculatePosition() {
    let screen = NSScreen.main        // ENCOURAGED - native system
    let frame = screen.frame          // ENCOURAGED - native coordinates
    // All calculations in native Cocoa coordinates
    return CGPoint(x: frame.minX + 100, y: frame.minY + 100)
}
```

### Rule 3: Native Cocoa Coordinate Documentation
```swift
// ✅ REQUIRED: Document all coordinates as native Cocoa system
func positionWindow(
    cocoaPosition: CGPoint,    // Native Cocoa coordinates (bottom-left origin, Y up)
    windowSize: CGSize,        // Size (coordinate-system independent)
    cocoaFrame: CGRect         // Native Cocoa coordinates (bottom-left origin, Y up)
) -> Bool {
    // All parameters use native macOS coordinate system
}

// ✅ ACCEPTABLE: Coordinates are implicitly Cocoa when not specified
func positionWindow(position: CGPoint, size: CGSize, frame: CGRect) {
    // Implicit: All coordinates are native Cocoa - this is acceptable
}
```

## 🛠️ Implementation Rules  

### Rule 4: Consistent Native Screen References
```swift
// ✅ REQUIRED: Use same native screen throughout entire operation
func applyLayout() {
    let primaryScreen = findConfigPrimaryScreen()  // Single screen source
    let nativeFrame = primaryScreen.frame          // Native Cocoa coordinates
    let position = calculatePosition(nativeFrame)  // Native coordinate calculation
    setWindowPosition(position, pid: pid)          // Consistent native coordinates
}

// ❌ FORBIDDEN: Coordinate conversions or mixed systems
func applyLayout() {
    let primaryScreen = findConfigPrimaryScreen()         // Native screen
    let convertedFrame = flipCoordinates(primaryScreen.frame)  // FORBIDDEN conversion
    let position = calculatePosition(convertedFrame)           // FORBIDDEN mixed system
}
```

### Rule 5: Native Cocoa Throughout
```swift
// ✅ REQUIRED: Use native Cocoa coordinates throughout
func handleAPI() {
    // 1. INPUT: Native Cocoa from APIs
    let cocoaData = externalAPI.getData()  // External API returns native Cocoa
    
    // 2. BUSINESS LOGIC: Native Cocoa processing
    let result = processData(cocoaData)    // Process in native Cocoa coordinates
    
    // 3. OUTPUT: Native Cocoa to APIs
    externalAPI.sendResult(result)         // Send native Cocoa coordinates
}

// ❌ FORBIDDEN: Any coordinate conversions
func handleAPI() {
    let cocoaData = externalAPI.getData()
    let quartzData = convertToQuartz(cocoaData)  // FORBIDDEN conversion
    let result = processData(quartzData)         // FORBIDDEN non-native system
}
```

## 🧪 Testing Rules

### Rule 6: Native Cocoa Coordinate Tests
```swift
// ✅ REQUIRED: Test native Cocoa coordinate handling
func testMyFeature() {
    // Test with native Cocoa coordinates (no conversion needed)
    let cocoaFrame = CGRect(x: 100, y: 200, width: 800, height: 600)  // Native Cocoa
    let position = myFeature.calculatePosition(cocoaFrame)
    
    // Assert results in native Cocoa coordinates
    XCTAssertEqual(position.x, 150.0, accuracy: 0.01)  // Native Cocoa result
    XCTAssertEqual(position.y, 250.0, accuracy: 0.01)  // Y increases upward (Cocoa)
}

// ❌ FORBIDDEN: Tests with coordinate conversions
func testMyFeature() {
    let cocoaFrame = CGRect(x: 100, y: 200, width: 800, height: 600)
    let quartzFrame = flipCoordinates(cocoaFrame)  // FORBIDDEN conversion
    let position = myFeature.calculatePosition(quartzFrame)  // FORBIDDEN non-native
}
```

### Rule 7: Native Multi-Monitor Testing
```swift
// ✅ REQUIRED: Test with native NSScreen multi-monitor setup
func testRealWorldScenario() {
    // Test with actual native monitor configuration
    let screens = NSScreen.screens  // Native Cocoa coordinate system
    XCTAssertGreaterThan(screens.count, 1, "Integration tests require multi-monitor setup")
    
    // Test primary monitor identification in native coordinates
    let primaryScreen = NSScreen.main  // Native primary screen
    XCTAssertNotNil(primaryScreen, "Must have native primary screen")
    
    // Verify native coordinate space is contiguous
    for screen in screens {
        let frame = screen.frame  // Native Cocoa coordinates
        XCTAssertTrue(frame.width > 0 && frame.height > 0, "Screen must have positive dimensions")
    }
}
```

## 📋 Code Review Rules

### Rule 8: Native Cocoa Architecture Review
**All coordinate-related code must be reviewed for**:
- [ ] Uses native Cocoa coordinate system only
- [ ] Direct NSScreen usage throughout application
- [ ] No coordinate conversions or custom systems
- [ ] Consistent native screen references throughout operation
- [ ] Native Cocoa coordinate test coverage
- [ ] Follows Apple's official coordinate system documentation

### Rule 9: Red Flag Patterns
**Immediate rejection for**:
- Any coordinate conversion functions or classes
- Custom coordinate system implementations
- Top-left origin coordinate calculations
- Quartz/CoreGraphics coordinate mixing with Cocoa
- Y-axis flipping or conversion operations
- Non-native coordinate system documentation

### Rule 10: Native Cocoa Documentation Requirements
**All coordinate-related features must include**:
- Native Cocoa coordinate system usage explanation
- Reference to Apple's official coordinate system documentation
- Test cases covering native coordinate handling
- Debug output showing native Cocoa coordinates
- Integration with NSScreen native APIs

## 🚫 Forbidden Patterns

### ❌ Custom Coordinate System Classes
```swift
// These classes violate native Cocoa principles and must not be used
import CocoaProfileManager     // REQUIRED - native coordinate system
import CocoaCoordinateManager  // REQUIRED - native coordinates
import CoordinateManager           // FORBIDDEN - coordinate conversion

// Use native macOS APIs only
import AppKit  // NSScreen provides native Cocoa coordinates
```

### ❌ Coordinate Conversion Functions
```swift
// FORBIDDEN: Any coordinate conversion
func calculatePosition() {
    let cocoaFrame = screen.frame                     // Native Cocoa
    let quartzPosition = convertToQuartz(cocoaFrame)  // FORBIDDEN conversion
    return quartzPosition
}

// Use native Cocoa coordinates directly
func calculatePosition() {
    let cocoaFrame = screen.frame  // Native Cocoa coordinates
    return CGPoint(x: cocoaFrame.minX + 100, y: cocoaFrame.minY + 100)  // Native calculation
}
```

### ❌ Y-Axis Flipping Operations
```swift
// FORBIDDEN: Y-axis coordinate flipping
func positionWindow() {
    let cocoaFrame = screen.frame                    // Native Cocoa (Y up)
    let flippedY = screenHeight - cocoaFrame.maxY    // FORBIDDEN Y-axis flip
    let position = CGPoint(x: cocoaFrame.minX, y: flippedY)
}

// Use native Cocoa coordinates without modification
func positionWindow() {
    let cocoaFrame = screen.frame  // Native Cocoa coordinates
    let position = CGPoint(x: cocoaFrame.minX + 100, y: cocoaFrame.minY + 100)  // Y increases upward
}
```

## ✅ Approved Patterns

### ✅ Native Cocoa Implementation
```swift
class NewFeature {
    func implementFeature() {
        // 1. Get native monitor data directly
        let screens = NSScreen.screens  // Native Cocoa coordinates
        
        // 2. Find primary screen using native API
        let primaryScreen = NSScreen.main  // Native primary identification
        
        // 3. Pure native Cocoa calculations
        let position = calculatePosition(
            quadrant: "top_left",
            windowSize: size,
            visibleFrame: primaryScreen?.visibleFrame ?? .zero  // Native Cocoa frame
        )
        
        // 4. Native output (no conversion needed)
        setWindowPosition(pid: pid, position: position)
    }
}
```

### ✅ Direct NSScreen Usage
```swift
func getMonitorData() -> [MonitorInfo] {
    // Use NSScreen native coordinates directly
    return NSScreen.screens.map { screen in
        // No conversion needed - use native Cocoa coordinates
        MonitorInfo(
            frame: screen.frame,              // Native Cocoa coordinates
            visibleFrame: screen.visibleFrame // Native Cocoa coordinates
        )
    }
}
```

### ✅ Native Cocoa Testing
```swift
func testNativeCoordinateHandling() {
    // Test with native Cocoa coordinates
    let nativeFrame = CGRect(x: 0, y: 1329, width: 3840, height: 2160)  // Native Cocoa
    let position = feature.calculatePosition(nativeFrame)
    
    // Assert native Cocoa results (Y increases upward)
    XCTAssertEqual(position.x, 360.0, accuracy: 1.0)   // X coordinate
    XCTAssertEqual(position.y, 1689.0, accuracy: 1.0)  // Y coordinate (upward)
}
```

## 🎯 Success Criteria

**Code is compliant when**:
- All coordinate handling uses native Cocoa coordinate system only
- Direct NSScreen usage throughout application (no custom wrappers)
- No coordinate conversion functions or classes exist
- All coordinates follow bottom-left origin, Y-increases-upward pattern
- Native Cocoa coordinate test coverage included
- Integration tests use NSScreen APIs directly
- Follows Apple's official coordinate system documentation

**Following these rules aligns with Apple's native macOS coordinate system design.**

---

**REFERENCE**: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CocoaDrawingGuide/Transforms/Transforms.html

*These rules implement Apple's official Cocoa contiguous coordinate system as the mandatory standard for Mac App Positioner.*