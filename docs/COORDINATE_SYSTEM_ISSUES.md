# Coordinate System Issues and Solutions

This document records critical issues encountered during the coordinate system implementation to prevent future mistakes.

## Issue 1: Chrome Positioned on Wrong Monitor

### Problem
Chrome was consistently positioned on the builtin monitor instead of the workspace monitor, despite calculations claiming success.

### Root Cause
**Workspace Monitor Detection Bug**: The `getAllMonitors()` function was using the first profile in the config instead of the specified profile for workspace monitor detection.

```swift
// BROKEN CODE - used first profile
if let profile = config?.profiles.first?.value {
    workspaceMonitorResolution = profile.monitors.first(where: { $0.position == "workspace" })?.resolution
}

// FIXED CODE - uses specified profile
if let profileName = profileName,
   let profile = config?.profiles[profileName] {
    workspaceMonitorResolution = profile.monitors.first(where: { $0.position == "workspace" })?.resolution
}
```

### Solution
Modified `getAllMonitors(for profileName: String? = nil)` to accept and use the correct profile parameter for workspace monitor detection.

### Key Learning
**Always verify which profile is being used for monitor detection.** The system can have multiple profiles, and using the wrong one leads to incorrect monitor identification.

## Issue 2: Chrome Wrong Y Coordinate (Top-Left vs Bottom-Left Confusion)

### Problem
Chrome was positioned at Y=1288 (builtin monitor) instead of the workspace monitor's top-left corner.

### Root Cause
**Coordinate System Mismatch**: The Accessibility API uses a different coordinate system than NSScreen:

- **NSScreen (Cocoa)**: Bottom-left origin, Y increases upward
  - Workspace: Y=1329 (bottom) to Y=3489 (top)
  - Builtin: Y=0 (bottom) to Y=1329 (top)

- **Accessibility API**: Top-left origin, Y increases downward
  - Workspace: Y=-2160 (top) to Y=0 (bottom) 
  - Builtin: Y=0 (top) to Y=1329 (bottom)

### Solution
Implemented proper coordinate conversion formula:

```swift
// Convert from Cocoa coordinates to Accessibility API coordinates
if position.y >= 1329 { // If on workspace monitor (Cocoa Y >= 1329)
    // Workspace monitor: Y=-2160 (top) to Y=0 (bottom) in Accessibility API
    // Cocoa workspace: Y=1329 (bottom) to Y=3489 (top)
    // Convert: AccessibilityY = -(CocoaY - 1329)
    accessibilityPosition = CGPoint(
        x: position.x,
        y: -(position.y - 1329)
    )
} else { // If on builtin monitor
    accessibilityPosition = position
}
```

### Key Learning
**Never assume coordinate systems match.** Always verify the actual coordinate ranges used by different APIs and implement proper conversion.

## Issue 3: Outlook Wrong Bottom-Left Positioning

### Problem
Outlook was positioned at (100, -1180) instead of exact bottom-left corner (0, -1143).

### Root Causes

#### 3A: Using Default Window Size Instead of Actual Size
```swift
// BROKEN CODE - used hardcoded default
let targetPosition = coordinateManager.calculateQuadrantPosition(
    quadrant: quadrant,
    windowSize: CGSize(width: 1200, height: 800), // Default size
    visibleFrame: workspaceMonitor.visibleFrame
)

// FIXED CODE - uses actual window size
var actualWindowSize = CGSize(width: 1200, height: 800) // Default fallback
if let currentPosition = getCurrentWindowPosition(pid: pid) {
    actualWindowSize = currentPosition.size
}
let targetPosition = coordinateManager.calculateQuadrantPosition(
    quadrant: quadrant,
    windowSize: actualWindowSize, // Actual size
    visibleFrame: workspaceMonitor.visibleFrame
)
```

#### 3B: Incorrect Bottom Positioning Logic
For bottom-left corner, the window's **top edge** must be calculated so the **bottom edge** aligns with the monitor's bottom edge.

```swift
case "bottom_left":
    baseX = visibleFrame.minX  // Exact left edge (X=0)
    baseY = visibleFrame.minY + windowSize.height  // Bottom edge plus window height
```

This ensures:
- Bottom edge of window = visibleFrame.minY (Y=0 in Accessibility API)
- Top edge of window = visibleFrame.minY + windowSize.height

### Solution
1. Get actual window dimensions from `getCurrentWindowPosition()`
2. Use actual window size in quadrant calculations
3. For bottom positioning: `baseY = bottomEdge + windowHeight`

### Key Learning
**Always use actual window dimensions for positioning calculations.** Default sizes lead to incorrect positioning, especially for bottom and right edge alignment.

## Issue 4: Coordinate Conversion Verification

### Problem
Assuming coordinate conversion was working without visual verification.

### Root Cause
**Lack of Systematic Testing**: Making claims about positioning success without checking actual visual placement.

### Solution
Always verify positioning with both:
1. **Debug output**: Log calculated and final positions
2. **AppleScript verification**: `osascript -e 'tell application "App" to get bounds of front window'`
3. **Visual confirmation**: Actually look at where the window is positioned

### Key Learning
**Never trust calculations without verification.** Always confirm actual window placement visually and programmatically.

## Coordinate System Reference

### Monitor Layout (Physical Setup)
```
┌─────────────────────┐ ← Workspace Monitor (4K, above)
│     3840 x 2160     │   Accessibility: Y=-2160 to Y=0
│                     │   Cocoa: Y=1329 to Y=3489
└─────────────────────┘
┌───────────────┐       ← Builtin Monitor (below)
│  2056 x 1329  │         Accessibility: Y=0 to Y=1329
│               │         Cocoa: Y=0 to Y=1329
└───────────────┘
```

### Coordinate Conversion Formula
```swift
// From Cocoa to Accessibility API
if position.y >= 1329 { // Workspace monitor
    accessibilityY = -(position.y - 1329)
} else { // Builtin monitor
    accessibilityY = position.y
}
```

### Corner Positioning Formulas
```swift
case "top_left":
    baseX = visibleFrame.minX  // X=0
    baseY = visibleFrame.maxY  // Highest Y in Cocoa

case "top_right":
    baseX = visibleFrame.maxX - windowSize.width  // Right edge minus width
    baseY = visibleFrame.maxY  // Highest Y in Cocoa

case "bottom_left":
    baseX = visibleFrame.minX  // X=0
    baseY = visibleFrame.minY + windowSize.height  // Bottom plus height

case "bottom_right":
    baseX = visibleFrame.maxX - windowSize.width  // Right edge minus width
    baseY = visibleFrame.minY + windowSize.height  // Bottom plus height
```

## Best Practices for Future Development

1. **Always verify profile usage** - Ensure correct profile is being used for monitor detection
2. **Test coordinate conversion systematically** - Use known test coordinates to verify conversion formulas
3. **Use actual window dimensions** - Never rely on default/hardcoded window sizes
4. **Verify positioning visually** - Don't trust debug output alone
5. **Document coordinate system assumptions** - Be explicit about which coordinate system is being used
6. **Test edge cases** - Verify exact corner positioning works correctly
7. **Use descriptive variable names** - Make coordinate system usage clear in code

## Testing Checklist

When implementing positioning changes:

- [ ] Test with actual profile names (not default/first profile)
- [ ] Verify coordinate conversion with manual AppleScript positioning
- [ ] Check all four corners of workspace monitor
- [ ] Test with windows of different sizes
- [ ] Confirm visual placement matches calculated coordinates
- [ ] Test both workspace and builtin monitor positioning
- [ ] Verify bottom/right edge alignment uses window dimensions correctly