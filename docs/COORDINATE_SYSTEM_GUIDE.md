# Coordinate System Guide - The Complete Reference

## 🚨 CRITICAL NOTICE

**This coordinate system architecture prevents positioning bugs that have occurred multiple times.**

**All coordinate-related development MUST follow this guide.**

---

## Table of Contents

1. [Why This Architecture Exists](#why-this-architecture-exists)
2. [The Canonical Coordinate System](#the-canonical-coordinate-system)
3. [Mandatory Rules for Developers](#mandatory-rules-for-developers)
4. [Implementation Patterns](#implementation-patterns)
5. [Testing Requirements](#testing-requirements)
6. [Debugging & Troubleshooting](#debugging--troubleshooting)
7. [Development Checklist](#development-checklist)

---

## Why This Architecture Exists

### The Problem History
**Mac App Positioner has experienced positioning failures multiple times** due to coordinate system issues:

1. **Coordinate System Mixing**: Calculations mixed Cocoa (bottom-left origin) and Quartz (top-left origin) coordinates
2. **Late Conversion**: Coordinate conversion happened after calculations instead of at API boundaries
3. **Screen Reference Mismatch**: Using NSScreen.main for conversion when calculations used config-defined primary screen
4. **No Single Source of Truth**: Different parts of code assumed different coordinate systems

### The Root Cause
```swift
// THE PROBLEM: Mixing coordinate systems
let cocoaFrame = screen.frame                    // Cocoa coordinates (bottom-left origin)
let quartzPosition = getWindowPosition()         // Quartz coordinates (top-left origin)
let result = CGPoint(
    x: cocoaFrame.minX + quartzPosition.x,      // MIXING SYSTEMS - CAUSES BUGS
    y: cocoaFrame.minY + quartzPosition.y
)
```

### The Solution
**Single canonical coordinate system with API boundary translation.**

---

## The Canonical Coordinate System

### Core Principle
**Choose ONE coordinate system as canonical and translate ALL inputs immediately at API boundaries.**

### Design Decision: Global Multi-Monitor Canonical Space
- **Global coordinate space** containing ALL monitors in their actual spatial arrangement
- **Main display at (0,0)** as reference point (system main, typically built-in)  
- **Adjacent displays** positioned relative to main display based on System Preferences arrangement
- **Consistent Quartz orientation**: Top-left origin, +X right, +Y down
- **Preserves spatial relationships** between monitors for accurate multi-monitor positioning

### Architecture Layers
```
┌─────────────────────────────────────────────────────┐
│                 Application Logic                   │
│     (All calculations in Global Canonical space)    │
├─────────────────────────────────────────────────────┤
│              Translation Boundary                   │
│   (Convert NSScreen Cocoa → Global Canonical)       │
├─────────────────────────────────────────────────────┤
│                 macOS APIs                         │
│  NSScreen (Cocoa) | Accessibility (Quartz)         │
└─────────────────────────────────────────────────────┘
```

### Canonical Coordinate Space Definition
**Global Multi-Monitor Space:**
- **Reference Point**: Main display (system main) at (0, 0)
- **Coordinate System**: Quartz (top-left origin, +X right, +Y down)
- **Scope**: All monitors positioned relative to main display
- **Spatial Accuracy**: Preserves actual physical monitor arrangement

**Example Multi-Monitor Setup:**
```
Built-in (Main): (0, 0, 2056, 1329)           [Reference at 0,0]
External Left:   (-2560, -360, 2560, 1440)    [Left of main, centered]  
External Below:  (0, 1329, 3840, 2160)        [Below main, aligned left]
```

### Implementation Components

#### CanonicalCoordinateManager
- **Single manager** for all coordinate operations
- **Global canonical system**: Multi-monitor Quartz space with main display at (0,0)
- **Translation methods**: Convert NSScreen Cocoa → Global Canonical at API boundaries
- **Spatial preservation**: Maintains actual monitor arrangement and relationships

#### CanonicalMonitorInfo
- **Purpose**: Store monitor data in global canonical coordinates
- **Spatial accuracy**: Each monitor positioned relative to main display (0,0)
- **No coordinate mixing**: All stored coordinates are global canonical Quartz

#### CanonicalProfileManager
- **Purpose**: Profile management using global canonical coordinates
- **Multi-monitor aware**: Calculations account for actual monitor positions
- **Spatial positioning**: Windows positioned in correct monitor using global coordinates

---

## Mandatory Rules for Developers

### ✅ Rule 1: Single Global Canonical Coordinate System
```swift
// REQUIRED: Use global canonical coordinate system
class MyNewFeature {
    private let coordinateManager = CanonicalCoordinateManager.shared
    
    func doSomething() {
        let monitors = coordinateManager.getAllMonitors()  // All monitors in global canonical space
        let primaryMonitor = monitors.first { $0.isPrimary }  // Find primary in global space
        let position = calculatePosition(primaryMonitor.frame)  // Calculate in global canonical
        coordinateManager.setWindowPosition(pid: pid, position: position)  // Position in global space
    }
}

// FORBIDDEN: Use legacy coordinate classes
private let coordinateManager = CoordinateManager()  // FORBIDDEN
private let profileManager = ProfileManager()        // FORBIDDEN
```

### ✅ Rule 2: API Boundary Translation ONLY
```swift
// REQUIRED: Convert inputs immediately at API boundaries
func getAllMonitors() -> [CanonicalMonitorInfo] {
    let mainScreen = NSScreen.main!  // System main display as reference (0,0)
    
    return NSScreen.screens.map { screen in
        let cocoaFrame = screen.frame                    // Input: Cocoa coordinates
        let canonicalFrame = convertCocoaToGlobalCanonical(  // IMMEDIATE conversion
            cocoaFrame: cocoaFrame, 
            mainScreen: mainScreen
        )
        return CanonicalMonitorInfo(frame: canonicalFrame)  // Store: Global Canonical ONLY
    }
}

// FORBIDDEN: Late conversion after calculations
// FORBIDDEN: Conversion inside calculation functions
// FORBIDDEN: Per-monitor coordinate systems
```

### ✅ Rule 3: Pure Global Canonical Calculations
```swift
// REQUIRED: ALL calculation functions use global canonical coordinates
func calculateQuadrantPosition(quadrant: String, windowSize: CGSize, monitorFrame: CGRect) -> CGPoint? {
    // ALL parameters are global canonical coordinates (relative to main display at 0,0)
    // monitorFrame could be (0, 1329, 3840, 2160) for a 4K display below main display
    // NO coordinate conversion anywhere in this function
    let position = CGPoint(x: monitorFrame.minX + offsetX, y: monitorFrame.minY + offsetY)
    return position  // Output: Global Canonical coordinates
}

// FORBIDDEN: Any coordinate conversion inside calculation functions
// FORBIDDEN: Mixing coordinate systems within calculations
// FORBIDDEN: Assuming any monitor is at (0,0) except main display
```

### ✅ Rule 4: Explicit Documentation
```swift
// REQUIRED: Document coordinate system for all geometry parameters
func positionWindow(
    globalCanonicalPosition: CGPoint,    // Global Canonical coordinates (relative to main display 0,0)
    windowSize: CGSize,                  // Size (coordinate-system independent)  
    monitorFrame: CGRect                 // Global Canonical coordinates
) -> Bool {
    // All parameters explicitly documented as global canonical
    // globalCanonicalPosition could be (100, 1400) for 4K display below main
}

// FORBIDDEN: Ambiguous coordinate parameters
// FORBIDDEN: Using "canonical" without "global" specification
```

### ✅ Rule 5: Consistent Screen References
```swift
// REQUIRED: Use the SAME screen for calculation and conversion
let primaryScreen = findConfigPrimaryScreen()  // Single screen source
let canonicalMonitor = CanonicalMonitorInfo(from: primaryScreen, referenceHeight: globalHeight)
let position = calculatePosition(canonicalMonitor.frame)  // Same screen data
setWindowPosition(position, pid: pid)  // Consistent throughout

// FORBIDDEN: Mixed screen references (NSScreen.main vs config-defined primary)
```

---

## Implementation Patterns

### ✅ API Boundary Pattern
```swift
// INPUT BOUNDARY: Convert immediately
func getScreenData(screen: NSScreen) -> CanonicalMonitorInfo {
    let cocoaFrame = screen.frame                    // API input: Cocoa
    let canonicalFrame = coordinateManager.toCanonical(
        rect: cocoaFrame, from: .cocoa, referenceScreenHeight: globalHeight
    )                                                // Immediate conversion
    return CanonicalMonitorInfo(frame: canonicalFrame) // Store: Canonical only
}

// CALCULATION: Pure canonical
func calculateWindowPosition(monitor: CanonicalMonitorInfo, quadrant: String) -> CGPoint {
    // ALL inputs guaranteed canonical Quartz - NO conversion
    return CGPoint(x: canonical_x, y: canonical_y)   // Output: Canonical only
}

// OUTPUT BOUNDARY: Convert only if API requires different system
func setWindowPosition(position: CGPoint, pid: Int32) -> Bool {
    // Accessibility API expects Quartz - canonical IS Quartz, no conversion needed
    return AXUIElementSetAttributeValue(window, kAXPositionAttribute, position)
}
```

### ❌ Prohibited Patterns
```swift
// WRONG: Mixing coordinate systems in calculations
func badCalculation(cocoaFrame: CGRect, quartzPosition: CGPoint) -> CGPoint {
    return CGPoint(x: cocoaFrame.minX + quartzPosition.x, y: cocoaFrame.minY + quartzPosition.y)  // FORBIDDEN
}

// WRONG: Late conversion after calculations
func badPositioning() {
    let cocoaFrame = screen.frame  // Cocoa coordinates
    let position = calculatePosition(cocoaFrame)  // Calculation in Cocoa
    let quartzPosition = convert(position)  // Late conversion - FORBIDDEN
}

// WRONG: Screen reference mismatch
func badScreenHandling() {
    let primaryScreen = findPrimaryScreen()  // Config-defined primary
    let position = calculatePosition(primaryScreen.frame)
    let converted = convertUsingMain(position, NSScreen.main)  // WRONG screen reference
}
```

---

## Testing Requirements

### Mandatory Coordinate System Tests
```swift
// REQUIRED: Round-trip conversion tests
func testCoordinateConversion() {
    let original = CGRect(x: 100, y: 200, width: 800, height: 600)  // Cocoa
    let canonical = coordinateManager.toCanonical(original, from: .cocoa, referenceHeight: height)
    let roundTrip = coordinateManager.fromCanonical(canonical, to: .cocoa, referenceHeight: height)
    XCTAssertEqual(original, roundTrip, accuracy: 0.01)  // MUST pass
}

// REQUIRED: Business logic tests use canonical coordinates
func testQuadrantCalculation() {
    let canonicalFrame = CGRect(x: 0, y: 0, width: 3840, height: 2160)  // Explicit canonical
    let position = calculateQuadrantPosition(.topLeft, windowSize, canonicalFrame)
    // All assertions in canonical coordinates
}

// REQUIRED: Integration tests with real monitor setup
func testRealWorldScenario() {
    let monitors = CanonicalCoordinateManager.shared.getAllMonitors()
    XCTAssertGreaterThan(monitors.count, 1, "Integration tests require multi-monitor setup")
}
```

---

## Debugging & Troubleshooting

### Step 1: Identify Coordinate System Issues
```bash
# Run coordinate system test
swift test_canonical_coordinates.swift

# Red flags:
❌ "Round-trip: FAIL"           # Coordinate conversion broken
❌ "Out of bounds"              # Wrong coordinate system used
❌ "Screen reference mismatch"  # Using wrong screen for conversion
```

### Step 2: Check Architecture Compliance  
```bash
# Verify canonical coordinate system usage
grep -r "NSScreen.main" MacAppPositioner/Shared/
# Should ONLY appear in boundary conversion functions

# Check for coordinate mixing
grep -r "screen.frame" MacAppPositioner/
# Should ONLY appear in API boundary functions
```

### Common Issues & Solutions

#### Issue: "Windows move to wrong screen"
**Cause**: Screen reference mismatch between calculation and conversion
**Fix**: Use canonical coordinate system architecture with consistent screen references

#### Issue: "Minimal window movement"  
**Cause**: Coordinate conversion using wrong screen dimensions
**Fix**: Ensure screen reference consistency throughout operation

#### Issue: "GUI shows wrong primary monitor"
**Cause**: GUI using NSScreen.main instead of config-defined primary
**Fix**: Use config-based primary detection in canonical coordinate system

### Emergency Procedures

#### If Positioning Completely Broken
```bash
# 1. Revert to canonical coordinate system
cp MacAppPositioner/Shared/CanonicalProfileManager.swift MacAppPositioner/Shared/ProfileManager.swift
./build.sh

# 2. Test immediately  
./MacAppPositioner/MacAppPositioner apply home
```

---

## Development Checklist

### ✅ Before Any Code Changes
- [ ] Have I read this coordinate system guide?
- [ ] Do I understand canonical coordinate system architecture?
- [ ] Will this change involve coordinates? (If yes, follow this guide)

### ✅ Implementation Compliance
- [ ] Am I using `CanonicalCoordinateManager.shared` (not legacy classes)?
- [ ] Am I converting coordinates ONLY at API boundaries?
- [ ] Are all calculations using canonical Quartz coordinates?
- [ ] Are screen references consistent throughout?
- [ ] Are coordinate parameters explicitly documented?

### ✅ Testing Requirements
- [ ] Have I written round-trip conversion tests?
- [ ] Have I tested coordinate system integrity?
- [ ] Do all tests pass?
- [ ] Have I tested with actual multi-monitor setup?

### ✅ Pre-Commit Verification
- [ ] Does `swift test_canonical_coordinates.swift` pass all tests?
- [ ] Does `./MacAppPositioner/MacAppPositioner apply home` work correctly?
- [ ] Does GUI show correct primary monitor?
- [ ] Does "Apply Layout" position windows correctly?

---

## Success Criteria

**The coordinate system is working correctly when:**
- All coordinate system tests pass with 100% accuracy
- Windows move to visually correct quadrants on intended monitor
- GUI correctly identifies primary monitor from config (not NSScreen.main)
- Debug output shows consistent screen references throughout operations
- No coordinate system mixing occurs in any calculations

**Following this guide prevents the coordinate system issues that have repeatedly affected Mac App Positioner.**

---

*This consolidated guide replaces multiple overlapping documents and serves as the single source of truth for coordinate system architecture.*