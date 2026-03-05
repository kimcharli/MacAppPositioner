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

**Symptoms**: Command runs but windows stay in place. Log shows `⚠️ Accessibility permission: NOT granted` or `❌ No moveable window found` for every app.

**Root Cause**: Without Accessibility permission, all AXUIElement queries silently return empty results. `hasMovableWindow` returns false for every PID, so no windows are found or moved.

**Solution — CLI**: Grant Accessibility permission to your terminal app (Terminal.app, iTerm2, VS Code, etc.) in **System Settings > Privacy & Security > Accessibility**.

**Solution — GUI**:

1. Open **System Settings > Privacy & Security > Accessibility**
2. If `MacAppPositionerGUI` is already listed, **remove it** first (select, click `−`)
3. Click `+` and add `/Applications/MacAppPositionerGUI.app`
4. Ensure the toggle is **ON**
5. Quit and relaunch MacAppPositionerGUI

**Why remove and re-add?** macOS TCC (Transparency, Consent, and Control) tracks apps by code signature. When you rebuild and replace the binary, the signature changes and the old permission entry becomes stale — the toggle appears ON but the OS no longer trusts the binary. Removing and re-adding forces TCC to register the new signature.

The build script (`build-all.sh`) now ad-hoc signs the app bundle with `codesign -s -` to give it a stable identity. This reduces (but doesn't eliminate) TCC invalidation on rebuilds.

**Verification**: Check the log file (`~/Documents/logs/gui-*.log` or `cli-*.log`). The first lines after the header show the permission status:

```
✅ Accessibility permission: granted        ← working
⚠️  Accessibility permission: NOT granted   ← broken, follow steps above
```

The GUI will also show an alert dialog with fix instructions and an "Open System Settings" button when permission is not granted.

```bash
# Nuclear option: reset ALL Accessibility permissions and re-grant
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

**Multi-window apps (e.g., Outlook, Teams)**:
If an app has multiple windows (like Outlook's "Reminders" window), MacAppPositioner might target the wrong one. We've improved the detection logic to prioritize the "Main Window," but if it still fails:
- Ensure the main window is active/focused when applying.
- Check if there are persistent secondary windows that might be confusing the Accessibility API.

**For apps with multiple processes (e.g. Chrome)**: Some apps run multiple processes with the same bundle ID (e.g. a regular Chrome window and a headless/debugging instance). `getAppPID` now selects the process that has accessible AX windows. If an app stopped working after you launched a secondary instance, this is likely the cause — see section 10 below.

### 10. App Not Moved — Multiple Instances of Same App Running

**Symptoms**: `❌ No moveable window found for <bundleID> across N process(es)` even though the app is visibly open.

**Root Cause**: Some applications (notably Google Chrome) can have multiple OS processes sharing the same bundle ID. For example:
- A regular Chrome browser window (the one you want to move)
- A headless or debugging instance (e.g. launched by Gemini CLI, VS Code, or similar tools with `--remote-debugging-port`)

`NSWorkspace.shared.runningApplications.first(where:)` returns the **first** matching process, which may be the headless instance with no visible windows — causing `getBestWindow` to return nil.

**Fix in code**: `getAppPIDs` in `CocoaProfileManager.swift` returns all matching PIDs sorted by recency. Callers use `hasMovableWindow(pid:)` to probe each PID via the AX API without activating the app, selecting the first one that actually owns a visible window.

**If you add new apps**: Do not use `NSWorkspace.shared.runningApplications.first(where:)` directly. Always use `getAppPIDs(bundleID:)` which handles this multi-instance case.

**Important**: If `hasMovableWindow` returns false for ALL processes, it usually means **Accessibility permission is not granted** (see section 1), not that the windows are actually missing.

**Diagnosis**:
```bash
# Check for multiple instances of the same app
ps aux | grep -i "[G]oogle Chrome" | grep -v Helper
# Multiple lines = multiple Chrome processes

# Check the log file for details
tail -30 ~/Documents/logs/gui-*.log
```

## Debug Logging

Both CLI and GUI write timestamped log files to the directory configured by `log_directory` in `config.json` (default: `~/Documents/logs`).

```bash
# List recent log files
ls -lt ~/Documents/logs/{cli,gui}-*.log | head -10

# Read the latest GUI log
cat "$(ls -t ~/Documents/logs/gui-*.log | head -1)"

# Read the latest CLI log
cat "$(ls -t ~/Documents/logs/cli-*.log | head -1)"
```

Log files capture all `print()` output (via global override) including:
- Accessibility permission status
- Config loading
- Profile detection and matching
- Per-app positioning details (current position, calculated target, result)
- Menu action clicks (Apply Auto, Detect, specific profile applies)
- Quit event

### System Logs (supplementary)

```bash
# Stream GUI app system logs in real time
log stream --predicate 'process == "MacAppPositionerGUI"'

# Show recent CLI system logs
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
