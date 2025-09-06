# Mac App Positioner

A native macOS application that automatically positions application windows according to predefined layouts across multiple monitors. Perfect for developers, designers, and power users who work with multiple applications and displays.

![macOS](https://img.shields.io/badge/macOS-10.15+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0+-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

✅ **Multi-Monitor Support** - Works seamlessly across multiple displays with different resolutions  
✅ **Quadrant Positioning** - Divide your primary monitor into four zones for systematic app organization  
✅ **Profile System** - Create different layouts for home, office, or travel setups  
✅ **Dynamic Detection** - Automatically detects your current monitor configuration  
✅ **Application-Specific Rules** - Handle apps that resist positioning (like Chrome)  
✅ **Command Line Interface** - Powerful CLI for automation and scripting  
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

```bash
# Detect your current monitor setup
./MacAppPositioner detect

# Apply a layout profile
./MacAppPositioner apply office

# Update a profile with current monitor configuration  
./MacAppPositioner update home

# Generate configuration template
./MacAppPositioner generate-config
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
          "position": "primary"
        },
        {
          "resolution": "2560x1440", 
          "position": "left"
        }
      ]
    }
  },
  "layout": {
    "primary": {
      "top_left": "com.google.Chrome",
      "top_right": "com.microsoft.teams2",
      "bottom_left": "com.microsoft.Outlook", 
      "bottom_right": "com.slack.Slack"
    }
  }
}
```

## How It Works

1. **Monitor Detection** - Uses `NSScreen` API to detect your current display setup
2. **Profile Matching** - Compares detected monitors with configured profiles
3. **Application Positioning** - Uses Accessibility API to move running applications
4. **Coordinate Translation** - Handles macOS coordinate system differences automatically

## Monitor Layout Example

Your primary monitor is divided into quadrants:

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

# Option 1: Simple build script (recommended)
./build.sh

# Option 2: Open in Xcode
open MacAppPositioner.xcodeproj
# Build with ⌘+B

# Option 3: Command line with xcodebuild
xcodebuild -project MacAppPositioner.xcodeproj -scheme MacAppPositioner
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
./MacAppPositioner detect && ./MacAppPositioner apply office

# Switch to focus mode
./MacAppPositioner apply minimal
```

### Shell Integration
```bash
# Add to your .zshrc or .bashrc
alias layout-office='~/path/to/MacAppPositioner apply office'  
alias layout-home='~/path/to/MacAppPositioner apply home'
```

### Monitor Setup Changes
```bash
# Connected new monitor? Update your profile
./MacAppPositioner update office

# See what monitors are detected
./MacAppPositioner generate-config
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

🚧 **Current Phase:** SwiftUI Interface Development  
📋 **Next:** Menu Bar App Integration  
🎯 **Future:** Layout Snapshots, Advanced Positioning

See [TODO.md](TODO.md) for detailed development roadmap.

## Contributing

We welcome contributions! Please see the [Development Guide](docs/DEVELOPMENT.md) for:
- Setting up the development environment
- Code style guidelines  
- Testing procedures
- Pull request process

## Architecture Principles

- **Dynamic Over Static** - Real-time monitor detection vs hardcoded values
- **Native Integration** - Uses macOS frameworks (AppKit, Accessibility)  
- **Modular Design** - Separated concerns across distinct Swift classes
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