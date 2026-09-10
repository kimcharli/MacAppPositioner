# Installation Guide

## Prerequisites

- macOS 11.0 (Big Sur) or later
- Administrator access (for Accessibility permissions)

## Build from Source

```bash
# Install Xcode Command Line Tools (if not already installed)
xcode-select --install

# Clone and build
git clone https://github.com/kimcharli/MacAppPositioner.git
cd MacAppPositioner
./Scripts/build-all.sh
```

This creates binaries in `dist/`:

- `dist/MacAppPositioner` - CLI tool
- `dist/MacAppPositionerGUI.app` - GUI app bundle

## Install the CLI Tool

```bash
# Option 1: Add to PATH (recommended)
echo 'export PATH="$PATH:/path/to/MacAppPositioner/dist"' >> ~/.zshrc
source ~/.zshrc

# Option 2: Copy to system path
sudo cp dist/MacAppPositioner /usr/local/bin/
```

## Install the GUI App

Drag `dist/MacAppPositionerGUI.app` to your `/Applications` folder.

On first launch, a monitor icon will appear in the menu bar and macOS will prompt for Accessibility permissions.

## Grant Accessibility Permissions

Mac App Positioner needs Accessibility access to move windows.

### For the GUI App

1. When prompted on first launch, click **"Open System Settings"**
2. Or manually: **System Settings > Privacy & Security > Accessibility**
3. Find **Mac App Positioner** and enable the toggle

### For the CLI Tool

Grant permissions to your terminal app:

1. **System Settings > Privacy & Security > Accessibility**
2. Add Terminal.app (or iTerm2, etc.)
3. Enable the toggle

## Configure

The quickest start is the template that ships with the repository:

```bash
mkdir -p ~/.config/mac-app-positioner
cp config.example.json ~/.config/mac-app-positioner/config.json
```

Then edit it to match your monitors and desired layout. See the [Configuration Guide](CONFIGURATION.md) for the full format reference.

### Alternative: derive a config from your current hardware

`generate-config` inspects your attached displays and prints a config whose
`profiles` section matches them. Only the JSON goes to stdout, so it can be
redirected straight to a file:

```bash
./dist/MacAppPositioner generate-config > ~/.config/mac-app-positioner/config.json
```

**It does not look at your running apps.** The `layout` section it writes is a
fixed five-app starter template — Chrome, Teams, Outlook, Slack and Obsidian —
not a survey of what you have open. Any other app you want positioned has to be
added to `layout` by hand; see
[Adding an application](CONFIGURATION.md#adding-an-application).

Progress messages go to stderr, so they stay on your terminal. Add `2>/dev/null`
to silence them.

Verify it parses before relying on it:

```bash
python3 -m json.tool ~/.config/mac-app-positioner/config.json > /dev/null && echo OK
```

## Verify

```bash
# CLI: detect your current setup
./dist/MacAppPositioner detect

# GUI: click the menu bar icon > Detect Current Setup
```

## Uninstall

```bash
# Remove GUI app
rm -rf /Applications/MacAppPositionerGUI.app

# Remove CLI (if copied to /usr/local/bin)
sudo rm /usr/local/bin/MacAppPositioner

# Remove configuration
rm -rf ~/.config/mac-app-positioner
```
