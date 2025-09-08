# Usage Guide

This guide explains how to use Mac App Positioner to manage window layouts across multiple monitors.

## Quick Start

### 1. Enable Accessibility Permissions
Before using Mac App Positioner, you must grant accessibility permissions:

1. Open **System Preferences** → **Security & Privacy** → **Privacy** → **Accessibility**
2. Click the lock icon and enter your password
3. Add the MacAppPositioner executable or Terminal.app
4. Ensure the checkbox is enabled

### 2. Configure Your Setup
Create or edit `config.json` in the project directory with your monitor configuration and desired layout.

### 3. Basic Commands
```bash
# Detect current monitor setup and find matching profile
./MacAppPositioner detect

# Apply a specific profile layout
./MacAppPositioner apply office

# Update profile with current monitor configuration
./MacAppPositioner update office

# Generate configuration template for current setup
./MacAppPositioner generate-config
```

## Command Reference

### `detect` - Profile Detection
Automatically detects your current monitor configuration and finds a matching profile.

```bash
./MacAppPositioner detect
```

**Output Examples:**
```
Detected profile: office
# Profile found matching current monitor setup

No matching profile detected.
# No profile matches current configuration
```

**Use Cases:**
- Verify your current setup matches a configured profile
- Troubleshoot configuration issues
- Confirm monitor detection is working properly

### `apply` - Apply Layout
Positions running applications according to a profile's layout configuration.

```bash
./MacAppPositioner apply <profile_name>
```

**Examples:**
```bash
# Apply the "office" profile layout
./MacAppPositioner apply office

# Apply the "home" profile layout  
./MacAppPositioner apply home
```

**Output Examples:**
```
Initial position of com.google.Chrome: (100, 200)
Moving com.google.Chrome to (0, 0)
  ✅ Successfully moved com.google.Chrome
  Final position of com.google.Chrome: (0, 0)

  ❌ Failed to move com.microsoft.Outlook
```

**Requirements:**
- Target applications must be running
- Applications must be identifiable by bundle identifier
- Accessibility permissions must be enabled

### `update` - Update Profile Configuration
Updates an existing profile with the current monitor configuration.

```bash
./MacAppPositioner update <profile_name>
```

**Example:**
```bash
# Update the "office" profile with current monitor setup
./MacAppPositioner update office
```

**Use Cases:**
- Monitor arrangement changed in System Preferences
- Added or removed monitors
- Want to save current physical setup to existing profile

### `generate-config` - Configuration Template
Generates JSON configuration template based on current monitor setup.

```bash
./MacAppPositioner generate-config
```

**Output Example:**
```json
"monitors": [
  {
    "resolution": "macbook",
    "position": "secondary"
  },
  {
    "resolution": "3440x1440", 
    "position": "left"
  }
]
```

**Use Cases:**
- Creating new profile configurations
- Understanding current monitor detection
- Troubleshooting monitor resolution matching

## Configuration Guide

### Understanding config.json Structure

```json
{
  "profiles": {
    "office": {
      "monitors": [
        {
          "resolution": "3440x1440",
          "position": "workspace"
        },
        {
          "resolution": "2560x1440", 
          "position": "left"
        },
        {
          "resolution": "macbook",
          "position": "builtin"
        }
      ]
    }
  },
  "layout": {
    "workspace": {
      "top_left": "com.google.Chrome",
      "top_right": "com.microsoft.teams2", 
      "bottom_left": "com.microsoft.Outlook",
      "bottom_right": "com.kakao.KakaoTalkMac"
    },
    "builtin": [
      "md.obsidian"
    ]
  },
  "applications": {
    "com.google.Chrome": {
      "positioning_strategy": "chrome"
    }
  }
}
```

### Profile Configuration

#### Monitor Definitions
Each monitor is defined by:
- **resolution**: Screen dimensions (e.g., "3440x1440") or "macbook" for built-in display
- **position**: Role in layout - "workspace", "left", "right", "secondary", "builtin"

#### Monitor Position Types
- **workspace**: Target monitor for quadrant layout (where apps will be positioned)
- **left/right**: Physical position relative to main display
- **secondary**: Additional monitor without specific positioning
- **builtin**: MacBook's built-in display

#### Finding Monitor Resolutions
Use the `generate-config` command to see detected resolutions:
```bash
./MacAppPositioner generate-config
```

### Layout Configuration

#### Primary Monitor Layout (Quadrant System)
The workspace monitor is divided into four equal quadrants:

```
┌─────────────────┬─────────────────┐
│   top_left      │   top_right     │
│                 │                 │
├─────────────────┼─────────────────┤
│  bottom_left    │  bottom_right   │
│                 │                 │
└─────────────────┴─────────────────┘
```

#### Application Layout Assignment
Map applications to quadrants using bundle identifiers:

```json
"workspace": {
  "top_left": "com.google.Chrome",
  "top_right": "com.microsoft.teams2",
  "bottom_left": "com.microsoft.Outlook", 
  "bottom_right": "com.kakao.KakaoTalkMac"
}
```

#### Finding Bundle Identifiers
**Method 1: Using Terminal**
```bash
# Find bundle ID for running app
osascript -e 'id of app "Chrome"'
# Output: com.google.Chrome

# List all running applications with bundle IDs
osascript -e 'tell application "System Events" to name of every application process whose background only is false'
```

**Method 2: Using System Information**
1. Hold Option key and click Apple menu
2. Select "System Information"
3. Navigate to "Software" → "Applications"
4. Find app and note "Bundle Identifier"

### Application-Specific Settings

Some applications may require special handling:

```json
"applications": {
  "com.google.Chrome": {
    "positioning_strategy": "chrome"
  }
}
```

**Positioning Strategies:**
- **chrome**: Special handling for Chrome's window positioning resistance
- **default**: Standard positioning (default if not specified)

## Common Workflows

### Setting Up a New Profile

1. **Arrange monitors** in System Preferences as desired
2. **Generate configuration** to see current setup:
   ```bash
   ./MacAppPositioner generate-config
   ```
3. **Add profile** to config.json with detected monitor configurations
4. **Configure layout** with desired application positions
5. **Test profile** detection:
   ```bash
   ./MacAppPositioner detect
   ```

### Daily Usage Workflow

1. **Connect external monitors** and arrange in System Preferences
2. **Launch applications** you want to position
3. **Detect profile** to confirm setup:
   ```bash
   ./MacAppPositioner detect
   ```
4. **Apply layout** to position all applications:
   ```bash
   ./MacAppPositioner apply office
   ```

### Switching Between Configurations

**Office to Home:**
```bash
# Disconnect office monitors, connect home setup
./MacAppPositioner detect        # Should show "home"
./MacAppPositioner apply home    # Apply home layout
```

**Updating Configurations:**
```bash
# Changed monitor arrangement in System Preferences
./MacAppPositioner update office  # Update office profile
./MacAppPositioner apply office   # Apply updated layout
```

## Tips and Best Practices

### Monitor Setup
- **Consistent Arrangements**: Keep monitor arrangements consistent for reliable profile detection
- **Workspace vs Main**: Remember that "workspace" (where apps are positioned) is independent from macOS "main" display
- **Resolution Matching**: Profile detection matches by exact resolution strings

### Application Management
- **Launch First**: Start applications before applying layout
- **Bundle Identifiers**: Use exact bundle identifiers in configuration
- **Test Individually**: Test positioning with one app before configuring multiple

### Troubleshooting Commands
```bash
# Check current monitor setup
./MacAppPositioner generate-config

# Verify profile exists
./MacAppPositioner detect

# Test with single application running
# (easier to debug than multiple apps)
```

### Performance Tips
- **Close unnecessary apps** before applying layouts (faster execution)
- **Use specific profiles** rather than always detecting
- **Keep config.json** in the same directory as executable

## Integration and Automation

### Shell Aliases
Add to your shell profile (.bashrc, .zshrc):
```bash
alias layout-office='~/path/to/MacAppPositioner apply office'
alias layout-home='~/path/to/MacAppPositioner apply home'  
alias layout-detect='~/path/to/MacAppPositioner detect'
```

### Automated Execution
**Launch at Login:**
Create a launch daemon or use automation tools to apply layouts automatically.

**Monitor Change Detection:**
Use system events or third-party tools to trigger layout application when monitors change.

### Keyboard Shortcuts
Set up system-wide keyboard shortcuts using:
- **Automator** with shell script actions
- **BetterTouchTool** or similar utilities
- **Custom AppleScript** applications

## Advanced Usage

### Multiple Profiles for Same Setup
```json
"profiles": {
  "office-dev": { /* same monitors, development layout */ },
  "office-meeting": { /* same monitors, meeting layout */ }
}
```

### Conditional Application Positioning
Position different apps based on context:
- Development vs meeting layouts
- Personal vs work application sets
- Time-of-day specific configurations

### Scripted Workflows
```bash
#!/bin/bash
# Smart layout application
PROFILE=$(./MacAppPositioner detect)
if [ "$PROFILE" != "No matching profile detected." ]; then
    echo "Applying layout: $PROFILE"
    ./MacAppPositioner apply "$PROFILE"
else
    echo "No profile found for current setup"
fi
```