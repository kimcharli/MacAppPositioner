# Troubleshooting Guide

This guide helps resolve common issues when using Mac App Positioner.

## Quick Diagnostics

### Check System Requirements
```bash
# Verify macOS version (requires 10.15+)
sw_vers -productVersion

# Check accessibility permissions
sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db \
  "SELECT * FROM access WHERE service='kTCCServiceAccessibility';"
```

### Basic Functionality Test
```bash
# Test configuration loading
./MacAppPositioner generate-config

# Test monitor detection
./MacAppPositioner detect

# Test with minimal profile
./MacAppPositioner apply <profile_name>
```

## Common Issues and Solutions

### 1. GUI and CLI Position Windows Differently (CRITICAL)

#### Problem: Different Behavior Between CLI and GUI
**Symptoms:**
- CLI positions windows correctly to corners
- GUI positions windows to wrong locations on external monitors
- Same shared code produces different results

**Root Cause:**
`NSScreen.main` returns different monitors depending on app type:
- **CLI apps**: Always returns the builtin monitor (at origin 0,0)
- **GUI apps**: Returns whichever monitor has mouse focus when launched

This causes incorrect coordinate conversion for external monitors in GUI apps.

**Solution:**
This has been fixed in the latest version. The code now explicitly finds the builtin monitor instead of relying on `NSScreen.main`:

```swift
// Find builtin monitor explicitly
let builtinScreen = NSScreen.screens.first { screen in
    screen.localizedName.contains("Built-in") || 
    screen.localizedName.contains("Liquid") ||
    screen.frame.origin == CGPoint(x: 0, y: 0)
} ?? NSScreen.main
```

**Verification:**
```bash
# Test CLI positioning
./dist/MacAppPositioner apply home

# Test GUI positioning (should now match CLI)
./dist/MacAppPositionerGUI
# Click "Apply Auto" in menu bar
```

**Prevention:**
Never rely on `NSScreen.main` being consistent across app types. Always explicitly find the specific monitor you need.

### 2. Accessibility Permissions Issues

#### Problem: Applications Don't Move
**Symptoms:**
- Command runs without errors but windows don't move
- Silent failures during positioning
- "Failed to move" messages in output

**Diagnosis:**
```bash
# Check if accessibility is enabled for Terminal
tccutil reset Accessibility com.apple.Terminal
```

**Solutions:**

**Option A: Enable for Terminal**
1. System Preferences → Security & Privacy → Privacy → Accessibility
2. Add Terminal.app or iTerm.app
3. Ensure checkbox is checked

**Option B: Enable for MacAppPositioner Executable**
1. Build the application
2. Add the MacAppPositioner executable to Accessibility list
3. Grant permissions

**Option C: Reset and Re-enable**
```bash
# Reset accessibility permissions
tccutil reset Accessibility

# Re-enable in System Preferences
```

#### Problem: Permission Denied Errors
**Error Message:** `Operation not permitted` or `Accessibility API error`

**Solution:**
1. **Quit System Preferences** if open
2. **Restart Terminal** application  
3. **Re-run command** with fresh permissions
4. If persistent, restart macOS

### 2. Profile Detection Issues

#### Problem: "No matching profile detected"
**Symptoms:**
- `detect` command returns no match
- Current setup should match configured profile
- Monitor configuration appears correct

**Diagnosis Steps:**

**Step 1: Check Current Monitor Setup**
```bash
# See what monitors are actually detected
./MacAppPositioner generate-config
```

**Step 2: Compare with Configuration**
```bash
# View current config.json
cat config.json | grep -A 10 "monitors"
```

**Step 3: Check Resolution Format**
Common mismatches:
- Config has `"3440x1440"` but system reports `"3440.0x1440.0"`
- Config has `"builtin"` but should be `"macbook"`
- Missing decimal points or extra precision

**Solutions:**

**Solution A: Update Profile Resolutions**
```bash
# Update existing profile with current setup
./MacAppPositioner update <profile_name>
```

**Solution B: Match Exact Format**
1. Run `generate-config` to see exact format
2. Copy exact resolution strings to your profile
3. Test with `detect` command

**Solution C: Handle Built-in Display**
```json
// Correct format for MacBook built-in display
{
  "resolution": "macbook",
  "position": "builtin"
}

// Alternative: use exact dimensions
{
  "resolution": "2056.0x1329.0",
  "position": "builtin"  
}
```

#### Problem: Wrong Profile Detected
**Symptoms:**
- `detect` finds a profile but wrong one
- Multiple profiles match current setup
- Profile switching doesn't work as expected

**Diagnosis:**
```bash
# Check all profiles and their monitor configs
cat config.json | jq '.profiles'
```

**Solutions:**
1. **Make profiles more specific** - ensure each has unique monitor combinations
2. **Use more distinctive monitor positions** - avoid generic "secondary"
3. **Order profiles by specificity** - more specific profiles first

### 3. Window Positioning Problems

#### Problem: Windows Position Incorrectly
**Symptoms:**
- Applications move but to wrong locations
- Windows appear off-screen or overlapping
- Coordinate calculations seem wrong

**Diagnosis:**
```bash
# Enable debug output by modifying source temporarily
# Look for coordinate conversion in output
```

**Common Causes:**

**Cause A: Coordinate System Confusion**
- Mixing Cocoa (bottom-left) and Quartz (top-left) coordinates
- Incorrect primary screen height calculation
- Multi-monitor coordinate space issues

**Solution:** Verify `CoordinateManager.translateRectFromCocoaToQuartz` logic

**Cause B: Wrong Primary Monitor**
- Configuration specifies wrong monitor as primary
- Multiple monitors marked as primary
- Primary monitor not detected correctly

**Solution:** 
```json
// Ensure only one monitor is marked as primary
"monitors": [
  {
    "resolution": "3440x1440",
    "position": "primary"  // Only one monitor should have this
  },
  {
    "resolution": "2560x1440",
    "position": "left"     // Others should have specific positions
  }
]
```

**Cause C: Visible Frame vs Full Frame**
- Using wrong screen bounds for calculations
- Menu bar and dock affecting positioning
- Different screen coordinate spaces

**Solution:** Check that code uses `visibleFrame` not `frame`

#### Problem: Some Applications Don't Move
**Symptoms:**
- Some apps position correctly, others don't
- Specific applications consistently fail
- Error messages about positioning failure

**Application-Specific Issues:**

**Chrome Positioning Problems**
```json
// Add special handling for Chrome
"applications": {
  "com.google.Chrome": {
    "positioning_strategy": "chrome"
  }
}
```

**Electron App Issues**
- Some Electron apps have non-standard window handling
- Try different bundle identifiers
- May require application-specific strategies

**Full-Screen Applications**
- Apps in full-screen mode can't be positioned
- Exit full-screen mode before applying layout
- Add detection for full-screen state

### 4. Configuration File Problems

#### Problem: Config File Not Loading
**Error Messages:**
- `Error decoding config.json`
- `Failed to load config`
- JSON parsing errors

**Diagnosis:**
```bash
# Validate JSON syntax
python -m json.tool config.json

# Check file permissions
ls -la config.json

# Verify file location
pwd && ls config.json
```

**Solutions:**

**Solution A: Fix JSON Syntax**
```bash
# Common JSON errors:
# - Missing commas between objects
# - Trailing commas after last element  
# - Unmatched quotes or brackets
# - Invalid escape characters
```

**Solution B: Check File Location**
- Ensure `config.json` is in same directory as executable
- Use absolute path if necessary
- Verify read permissions

**Solution C: Validate Schema**
Required structure:
```json
{
  "profiles": { /* required */ },
  "layout": { /* required */ },
  "applications": { /* optional */ }
}
```

#### Problem: Profile Not Found
**Error Message:** `Profile 'office' not found`

**Diagnosis:**
```bash
# List all configured profiles
cat config.json | jq '.profiles | keys'

# Check exact profile name spelling
grep -n "office" config.json
```

**Solutions:**
1. **Check spelling** - profile names are case-sensitive
2. **Verify structure** - ensure profile is under `profiles` key
3. **Add missing profile** using `generate-config` as template

### 5. Build and Development Issues

#### Problem: Build Failures in Xcode
**Common Build Errors:**

**Missing Framework References**
```
Error: Cannot find 'NSScreen' in scope
```
**Solution:** Ensure AppKit is imported
```swift
import AppKit
```

**Deployment Target Issues**
```
Error: 'some View' is only available in macOS 10.15 or newer
```
**Solution:** Set deployment target to macOS 10.15+ in project settings

**Code Signing Issues**
```
Error: Code signing failed
```
**Solution:** 
1. Select "Sign to Run Locally" in project settings
2. Or disable code signing for development builds

#### Problem: Runtime Crashes
**Common Crash Scenarios:**

**Null Pointer Exceptions**
```swift
// Add guards for optional values
guard let primaryScreen = NSScreen.main else {
    print("Could not get main screen")
    return
}
```

**Array Index Out of Bounds**
```swift
// Check array bounds before accessing
guard !NSScreen.screens.isEmpty else {
    print("No screens detected")
    return
}
```

**API Call Failures**
```swift
// Handle Accessibility API failures gracefully
let result = AXUIElementCopyAttributeValue(window, kAXPositionAttribute, &position)
if result != .success {
    print("Failed to get window position: \(result)")
    return nil
}
```

## Advanced Troubleshooting

### Debug Output Enhancement
Add temporary debug output to identify issues:

```swift
// In ProfileManager.detectProfile()
print("Debug: Detected \(currentScreens.count) screens")
for screen in currentScreens {
    print("Debug: Screen \(screen.frame.width)x\(screen.frame.height) at \(screen.frame.origin)")
}

// In WindowManager.setWindowPosition()  
print("Debug: Setting position \(position) for PID \(pid)")
```

### System Information Gathering
```bash
# Display configuration
system_profiler SPDisplaysDataType

# Running applications  
ps aux | grep -i "Chrome"

# System logs
log stream --predicate 'process == "MacAppPositioner"' --info
```

### Configuration Validation Script
Create a validation script:
```bash
#!/bin/bash
echo "=== Mac App Positioner Diagnostics ==="

echo "1. System Version:"
sw_vers

echo "2. Monitor Configuration:"
./MacAppPositioner generate-config

echo "3. Profile Detection:"
./MacAppPositioner detect

echo "4. Config File Validation:"
python -m json.tool config.json > /dev/null && echo "✅ Valid JSON" || echo "❌ Invalid JSON"

echo "5. Accessibility Status:"
# Check if Terminal has accessibility permissions
echo "Check System Preferences → Security & Privacy → Privacy → Accessibility"
```

## Getting Additional Help

### Information to Include When Seeking Help
1. **macOS version** (`sw_vers`)
2. **Complete error messages** (copy-paste, don't paraphrase)
3. **Current config.json** (sanitized of personal info)
4. **Output of `generate-config`**
5. **List of applications you're trying to position**
6. **Monitor setup description** (sizes, arrangement)

### Useful Log Commands
```bash
# Application-specific logs
log show --predicate 'process == "MacAppPositioner"' --last 1h

# System accessibility logs  
log show --predicate 'subsystem == "com.apple.accessibility"' --last 10m

# Display-related system logs
log show --predicate 'category == "Display"' --last 5m
```

### Reset to Clean State
If all else fails, start fresh:
```bash
# 1. Reset accessibility permissions
tccutil reset Accessibility

# 2. Backup and remove config
mv config.json config.json.backup

# 3. Generate new config
./MacAppPositioner generate-config > config.json.new

# 4. Manually configure profiles based on new template
# 5. Test with single application first
```

## Known Limitations

### System Limitations
- **Accessibility API required**: Cannot position windows without permission
- **Application cooperation**: Some apps resist positioning attempts  
- **Full-screen mode**: Cannot position full-screen applications
- **System integrity**: Some system applications cannot be positioned

### Application-Specific Limitations
- **Electron apps**: May have inconsistent window management
- **Sandboxed apps**: May have restricted positioning capabilities
- **Multi-window apps**: Only positions main window
- **Minimized windows**: Cannot position minimized applications

### Monitor Configuration Limitations  
- **Resolution changes**: Profile detection may fail if monitors change resolution
- **Dynamic arrangements**: Requires profile updates when physical setup changes
- **Mixed scaling**: May have issues with different monitor scaling factors