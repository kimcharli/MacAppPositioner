# Installation Guide

This guide walks you through installing Mac App Positioner on your system.

## Prerequisites

- macOS 11.0 (Big Sur) or later
- Administrator access (for granting Accessibility permissions)

## Installation Methods

### Method 1: Pre-built Release (Recommended)

1. **Download the latest release** from the [Releases page](https://github.com/kimcharli/MacAppPositioner/releases)
2. Extract the downloaded archive
3. Follow the setup instructions below

### Method 2: Build from Source

#### Requirements
- Xcode Command Line Tools
- Swift 5.0 or later

#### Build Steps

```bash
# Clone the repository
git clone https://github.com/kimcharli/MacAppPositioner.git
cd MacAppPositioner

# Build everything (CLI and GUI with app bundle)
./Scripts/build-all.sh

# Or build individually:
# ./Scripts/build.sh       # CLI only
# ./Scripts/build-gui.sh   # GUI only
```

## Setting Up the Configuration

1. **Create the configuration directory:**
   ```bash
   mkdir -p ~/.config/mac-app-positioner
   ```

2. **Create your configuration file:**
   ```bash
   # Copy the example configuration
   cp config.example.json ~/.config/mac-app-positioner/config.json
   
   # Or create your own
   nano ~/.config/mac-app-positioner/config.json
   ```

3. **Edit the configuration** to match your monitor setup and preferences (see [Configuration Guide](#configuration-guide))

## Installing the CLI Tool

The CLI tool can run from anywhere, but for convenience:

```bash
# Option 1: Add to PATH (recommended)
echo 'export PATH="$PATH:/path/to/MacAppPositioner/dist"' >> ~/.zshrc
source ~/.zshrc

# Option 2: Create alias
echo 'alias macpos="/path/to/MacAppPositioner/dist/MacAppPositioner"' >> ~/.zshrc
source ~/.zshrc

# Option 3: Copy to /usr/local/bin
sudo cp dist/MacAppPositioner /usr/local/bin/
```

## Installing the Menu Bar App

After running the `./Scripts/build-all.sh` script, the `MacAppPositionerGUI.app` bundle will be created in the `dist` directory.

1. **Install to Applications:**
   - Drag `dist/MacAppPositionerGUI.app` to your `/Applications` folder.
   - Or use the command line:
     ```bash
     cp -r dist/MacAppPositionerGUI.app /Applications/
     ```

2. **First Launch:**
   - Open Mac App Positioner from your Applications folder.
   - You'll see a monitor icon (🖥️) appear in your menu bar.
   - macOS will prompt for Accessibility permissions. Click "Open System Settings" and grant the permissions.

## Granting Accessibility Permissions

Mac App Positioner needs Accessibility permissions to control window positions:

### For the GUI App

1. When prompted, click **"Open System Settings"**
2. Or manually navigate to: **System Settings** → **Privacy & Security** → **Accessibility**
3. Click the lock icon to make changes
4. Find **Mac App Positioner** in the list
5. Enable the checkbox next to it

### For the CLI Tool

If using the CLI tool, you may need to grant Terminal or iTerm2 accessibility permissions:

1. Open **System Settings** → **Privacy & Security** → **Accessibility**
2. Add your terminal application if not already present
3. Enable the checkbox

## Configuration Guide

### Basic Configuration Structure

```json
{
  "version": "1.0",
  "profiles": {
    "profile_name": {
      "monitors": [
        {
          "resolution": "widthxheight",
          "position": "workspace|builtin|left|right"
        }
      ]
    }
  },
  "applications": {
    "bundle.id": {
      "workspace": "position",
      "builtin": "position"
    }
  },
  "layout": {
    "workspace": {
      "bundle.id": {
        "position": "top_left|top_right|bottom_left|bottom_right|center|keep"
      }
    },
    "builtin": {
      "bundle.id": {
        "position": "keep|center"
      }
    }
  }
}
```

### Finding Your Monitor Resolution

```bash
# Use the CLI tool to detect your current setup
./dist/MacAppPositioner detect

# Or use the generate-config command
./dist/MacAppPositioner generate-config
```

### Finding Application Bundle IDs

```bash
# List all running applications
osascript -e 'tell application "System Events" to get bundle identifier of every process whose background only is false'

# Get a specific app's bundle ID
osascript -e 'id of app "Chrome"'  # Returns: com.google.Chrome
```

### Common Bundle IDs

- **Browsers:**
  - Chrome: `com.google.Chrome`
  - Safari: `com.apple.Safari`
  - Firefox: `org.mozilla.firefox`
  
- **Communication:**
  - Slack: `com.tinyspeck.slackmacgap`
  - Teams: `com.microsoft.teams2`
  - Discord: `com.hnc.Discord`
  - Zoom: `us.zoom.xos`
  
- **Development:**
  - VS Code: `com.microsoft.VSCode`
  - Xcode: `com.apple.dt.Xcode`
  - Terminal: `com.apple.Terminal`
  - iTerm2: `com.googlecode.iterm2`
  
- **Productivity:**
  - Outlook: `com.microsoft.Outlook`
  - Notion: `notion.id`
  - Obsidian: `md.obsidian`

## Verification

### CLI Verification

```bash
# Test detection
./dist/MacAppPositioner detect

# Should output something like:
# ✅ Detected profile: office
```

### GUI Verification

1. Click the monitor icon in your menu bar
2. Select **"Detect Current Setup"**
3. You should see a notification with the detected profile

## Troubleshooting

### "Operation not permitted" Error

- Ensure Accessibility permissions are granted
- For CLI: Grant permissions to your terminal app
- For GUI: Grant permissions to Mac App Positioner

### "Config not found" Error

- Verify config exists: `ls -la ~/.config/mac-app-positioner/config.json`
- Check file permissions: `chmod 644 ~/.config/mac-app-positioner/config.json`

### GUI App Not Appearing

- Check if it's running: `ps aux | grep MacAppPositionerGUI`
- Look for the monitor icon (🖥️) in your menu bar
- Try launching from Terminal: `open /Applications/MacAppPositionerGUI.app`

### Windows Not Moving

1. Verify Accessibility permissions are enabled
2. Check that the application is running
3. Ensure your config.json is valid JSON
4. Try the CLI tool first to debug

## Uninstallation

### Remove the GUI App

```bash
# Remove from Applications
rm -rf /Applications/MacAppPositionerGUI.app

# Remove configuration
rm -rf ~/.config/mac-app-positioner

# Reset Accessibility permissions
tccutil reset Accessibility com.kimcharli.MacAppPositionerGUI
```

### Remove the CLI Tool

```bash
# If installed in /usr/local/bin
sudo rm /usr/local/bin/MacAppPositioner

# Remove from PATH or alias in ~/.zshrc
```

## Next Steps

- Read the [Usage Guide](USAGE.md) to learn how to use the tools
- Check [Configuration Examples](docs/CONFIG_EXAMPLES.md) for more complex setups
- See [Troubleshooting](docs/TROUBLESHOOTING.md) for common issues
