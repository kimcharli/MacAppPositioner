# Mac App Positioner

A native macOS application that automatically positions application windows according to predefined layouts across multiple monitors. Perfect for developers, designers, and power users who work with multiple applications and displays.

**Available as both Command Line Interface (CLI) and Menu Bar GUI application.**

![macOS](https://img.shields.io/badge/macOS-11.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0+-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

✅ **Dual Interface** - Available as both CLI and GUI applications  
✅ **Multi-Monitor Support** - Works seamlessly across multiple displays with different resolutions  
✅ **Native Cocoa Coordinate System** - Uses Apple's official coordinate system for precise positioning  
✅ **Exact Corner Positioning** - Zero padding, pixel-perfect window placement  
✅ **Quadrant Positioning** - Divide your workspace monitor into four zones for systematic app organization  
✅ **Profile System** - Create different layouts for home, office, or travel setups  
✅ **Dynamic Detection** - Automatically detects your current monitor configuration  
✅ **Application-Specific Rules** - Handle apps that resist positioning (like Chrome)  
✅ **Native Swift Implementation** - Fast, efficient, and follows macOS conventions

## Quick Start

### 1. Prerequisites
- **macOS 10.15+** (Catalina or later)
- **Accessibility Permissions** - Required for window manipulation

### 2. Setup Accessibility Permissions
1. Open **System Preferences** → **Security & Privacy** → **Privacy** → **Accessibility**
2. Click the lock and enter your password
3. Add **Terminal.app** (or your terminal application)
4. Ensure the checkbox is enabled

### 3. Basic Usage

#### Command Line Interface (CLI)
```bash
# Detect your current monitor setup
./dist/MacAppPositioner detect

# Apply a layout profile
./dist/MacAppPositioner apply office

# Update a profile with current monitor configuration  
./dist/MacAppPositioner update home

# Generate configuration template
./dist/MacAppPositioner generate-config
```

#### Graphical User Interface (GUI)
```bash
# Launch the GUI application
./dist/MacAppPositionerGUI

# Or build and run
./Scripts/build-gui.sh && ./dist/MacAppPositionerGUI
```

## Example Configuration

Configure your layouts in `config.json`:

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
        }
      ]
    }
  },
  "layout": {
    "workspace": {
      "top_left": "com.google.Chrome",
      "top_right": "com.microsoft.teams2",
      "bottom_left": "com.microsoft.Outlook", 
      "bottom_right": "com.slack.Slack"
    }
  }
}
```

### Resolution Format

Monitor resolutions use a user-friendly format: `"widthxheight"` (e.g., `"3440x1440"`, `"2560x1440"`). The application automatically normalizes both this format and system-generated formats with decimal points for consistent matching.

## How It Works

1. **Monitor Detection** - Uses `NSScreen` API to detect your current display setup
2. **Profile Matching** - Compares detected monitors with configured profiles
3. **Native Cocoa Coordinates** - Uses Apple's official coordinate system (bottom-left origin, Y increases upward)
4. **Application Positioning** - Uses Accessibility API to move running applications with precise coordinate conversion
5. **Exact Positioning** - Achieves pixel-perfect corner placement with zero padding

## Monitor Layout Example

Your workspace monitor is divided into quadrants:

```
┌─────────────────┬─────────────────┐
│   top_left      │   top_right     │
│   (Chrome)      │   (Teams)       │
├─────────────────┼─────────────────┤
│  bottom_left    │  bottom_right   │
│  (Outlook)      │   (Slack)       │
└─────────────────┴─────────────────┘
```

## Installation & Development

### Build from Source
```bash
# Clone the repository
git clone <repository-url>
cd MacAppPositioner

# Option 1: Build everything (recommended)
./Scripts/build-all.sh

# Option 2: Build CLI only
./Scripts/build.sh

# Option 3: Build GUI only
./Scripts/build-gui.sh

# Binaries will be created in dist/ folder:
# - dist/MacAppPositioner (CLI)
# - dist/MacAppPositionerGUI.app (GUI app bundle)
```

### Finding Application Bundle IDs
```bash
# Find bundle ID for any running app
osascript -e 'id of app "Chrome"'
# Output: com.google.Chrome
```

## Documentation

📖 **[Usage Guide](docs/USAGE.md)** - Comprehensive user guide with examples and workflows  
🏗️ **[Architecture Guide](docs/ARCHITECTURE.md)** - Technical implementation details  
🛠️ **[Development Guide](docs/DEVELOPMENT.md)** - Setup, building, testing, and contributing  
🔧 **[Troubleshooting Guide](docs/TROUBLESHOOTING.md)** - Solutions for common issues  
📝 **[Terminology Reference](docs/TERMINOLOGY.md)** - Key terms and concepts  
🤖 **[AI Agent Guide](docs/AGENTS.md)** - Guidelines for AI-assisted development

## Common Use Cases

### Daily Workflow
```bash
# Morning routine - detect and apply layout
./dist/MacAppPositioner detect && ./dist/MacAppPositioner apply office

# Switch to focus mode
./dist/MacAppPositioner apply minimal

# Or use the GUI for visual feedback
./dist/MacAppPositionerGUI
```

### Shell Integration
```bash
# Add to your .zshrc or .bashrc
alias layout-office='~/path/to/dist/MacAppPositioner apply office'  
alias layout-home='~/path/to/dist/MacAppPositioner apply home'
```

### Monitor Setup Changes
```bash
# Connected new monitor? Update your profile
./dist/MacAppPositioner update office

# See what monitors are detected
./dist/MacAppPositioner generate-config
```

## Supported Applications

Works with most macOS applications including:
- Web browsers (Chrome, Safari, Firefox)
- Communication apps (Teams, Slack, Discord) 
- Development tools (Xcode, VS Code, Terminal)
- Productivity apps (Mail, Calendar, Notes)
- Design tools (Figma, Sketch, Photoshop)

Some applications may require special positioning strategies (configured in `config.json`).

## Troubleshooting

### Applications Won't Move
- ✅ Check accessibility permissions are enabled
- ✅ Ensure applications are running (not minimized)
- ✅ Verify bundle identifiers in config are correct
- ✅ Exit full-screen mode for target applications

### Profile Not Detected
- ✅ Run `generate-config` to see current monitor setup
- ✅ Compare with your profile configuration
- ✅ Update profile using `update` command

See the [Troubleshooting Guide](docs/TROUBLESHOOTING.md) for detailed solutions.

## Roadmap

✅ **Completed:** Native Cocoa Coordinate System & Dual Interface (CLI + GUI)  
🚧 **Current Phase:** Advanced Features & Polish (Profile Management, Layout Snapshots)  
📋 **Next:** Menu Bar App Integration  
🎯 **Future:** Intelligence & Automation, Polish & Distribution

See [TODO.md](TODO.md) for detailed development roadmap.

## Contributing

We welcome contributions! Please see the [Development Guide](docs/DEVELOPMENT.md) for:
- Setting up the development environment
- Code style guidelines  
- Testing procedures
- Pull request process

## Architecture Principles

- **Native Cocoa Coordinate System** - Uses Apple's official coordinate system for precision and reliability
- **Dynamic Over Static** - Real-time monitor detection vs hardcoded values
- **Native Integration** - Uses macOS frameworks (AppKit, Accessibility)  
- **Modular Design** - Separated concerns across distinct Swift classes
- **Dual Interface** - CLI and GUI share identical core logic for consistency
- **Error Resilience** - Comprehensive error handling and user feedback

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

Built with native macOS technologies:

- **AppKit** for monitor detection and workspace management
- **Accessibility API** for window manipulation
- **Foundation** for JSON configuration and file I/O

---

**Questions?** Check the [documentation](docs/) or open an issue for support.
