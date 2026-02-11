# Troubleshooting Guide

## Quick Diagnostics

```bash
# Verify macOS version (requires 11.0+)
sw_vers -productVersion

# Test config loading and monitor detection
./dist/MacAppPositioner detect

# Generate config from current setup (useful for debugging)
./dist/MacAppPositioner generate-config

# Preview what would happen without moving anything
./dist/MacAppPositioner plan
```

## Common Issues

### 1. Windows Don't Move (Accessibility Permissions)

**Symptoms**: Command runs but windows stay in place, or "Failed to move" messages appear.

**Solution**: Grant Accessibility permissions.

- **CLI**: System Settings > Privacy & Security > Accessibility > add your terminal app
- **GUI**: System Settings > Privacy & Security > Accessibility > add Mac App Positioner

If permissions were recently changed, restart the terminal or app.

```bash
# Nuclear option: reset and re-grant
tccutil reset Accessibility
```

### 2. GUI Menu Bar Apply Positions Windows Wrong (or Does Nothing)

**Symptoms**: Clicking "Apply Auto" from the menu bar either does nothing visible, or moves windows to wrong positions. The CLI works correctly with the same profile.

**Root Cause**: `NSScreen.main` returns different screens depending on app type:

- **CLI**: Returns the menu bar screen (Cocoa origin 0,0)
- **GUI**: Returns whichever monitor has mouse focus

The coordinate conversion in `getAllMonitors()` used `NSScreen.main?.frame.height` to compute the Cocoa→internal Y flip. With the wrong screen height, all monitor coordinates shift, causing windows to land on the wrong position or wrong monitor entirely.

**Fix**: `getAllMonitors()` now uses `NSScreen.screens.first?.frame.height`. Per Apple docs, `NSScreen.screens.first` always returns the menu bar screen regardless of app type. This was fixed in `CocoaCoordinateManager.swift`.

If you see this behavior on an older build, rebuild:

```bash
./Scripts/build-all.sh
```

### 3. "No Matching Profile Detected"

**Symptoms**: `detect` returns no match even though monitors are connected.

**Diagnosis**:

```bash
# See what resolutions are actually detected
./dist/MacAppPositioner generate-config
```

**Common causes**:

- Resolution format mismatch: config says `"3440x1440"` but system reports `"3440.0x1440.0"`
- Built-in display not identified: try using `"macbook"` instead of exact dimensions
- Profile has monitors that don't match the current physical setup

**Fix**: Update profile resolutions to match exactly what `generate-config` reports, or run:

```bash
./dist/MacAppPositioner update <profile_name>
```

### 4. Wrong Profile Detected

**Symptoms**: `detect` finds a profile, but the wrong one.

**Cause**: Multiple profiles have identical or overlapping monitor resolution sets.

**Fix**: Make profiles more specific — ensure each has a unique combination of monitor resolutions.

### 5. Windows Positioned on Wrong Monitor

**Symptoms**: Apps move, but to the wrong screen.

**Common causes**:

- Config has no `"workspace"` monitor defined in the profile
- Multiple monitors have similar resolutions

**Diagnosis**:

```bash
./dist/MacAppPositioner plan
```

Check the plan output to see which monitor is identified as workspace.

### 6. Config File Not Found

**Error**: `Config not found in any standard location`

**Solution**: Verify the config exists in one of these locations:

1. `~/.config/mac-app-positioner/config.json`
2. `~/Library/Application Support/MacAppPositioner/config.json`
3. `./config.json` (current working directory)
4. `~/.mac-app-positioner/config.json`

```bash
ls -la ~/.config/mac-app-positioner/config.json
```

### 7. JSON Parsing Errors

**Error**: `Error decoding config.json`

**Diagnosis**:

```bash
python3 -m json.tool ~/.config/mac-app-positioner/config.json
```

Common JSON mistakes: missing commas, trailing commas, unmatched brackets, comments (JSON doesn't support comments).

### 8. GUI Changes Not Reflected

**Symptoms**: Code changes don't appear after rebuilding.

**Cause**: Running the old version from `/Applications/` instead of the newly built `dist/` version.

**Fix**:

1. Build: `./Scripts/build-gui.sh`
2. Test from dist: `open ./dist/MacAppPositionerGUI`
3. Check the About menu for the build timestamp
4. Drag the new `.app` from `dist/` to `/Applications/` to update the installed version

### 9. Some Apps Don't Move

**Possible causes**:

- App is in full-screen mode (exit full-screen first)
- App is minimized (restore it first)
- App uses non-standard window management (Electron apps, sandboxed apps)
- Bundle ID in config doesn't match the running app

**For Chrome specifically**, add to your config:

```json
"applications": {
  "com.google.Chrome": {
    "positioning_strategy": "chrome"
  }
}
```

## Debug Logging

```bash
# Stream GUI app logs in real time
log stream --predicate 'process == "MacAppPositionerGUI"'

# Show recent CLI logs
log show --predicate 'process == "MacAppPositioner"' --last 15m

# Check display configuration
system_profiler SPDisplaysDataType
```

## Known Limitations

- **Accessibility API required**: Windows cannot be moved without permission
- **Full-screen apps**: Cannot be repositioned while in full-screen mode
- **Minimized windows**: Cannot be positioned while minimized
- **Multi-window apps**: Only the main window is positioned
- **Resolution changes**: Profile detection may fail if a monitor changes resolution (e.g., scaling changes)
