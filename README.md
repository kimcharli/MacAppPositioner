> **Note for AI Agents:** Before performing any actions, please read and adhere to the guidelines in the **[AI Agent Guide](docs/AGENTS.md)**. This document contains critical instructions for interacting with this codebase and should be kept updated.

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

1.  **Build the application** from source:
    ```bash
    git clone <repository-url>
    cd MacAppPositioner
    ./Scripts/build-all.sh
    ```
2.  **Configure your layouts** by creating a `config.json` file.
3.  **Grant Accessibility Permissions** when prompted or in System Settings.

For detailed steps, see the **[Installation Guide](docs/INSTALLATION.md)** and the **[Configuration Guide](docs/CONFIGURATION.md)**.

## Documentation

This project has comprehensive documentation for both users and developers.

-   📖 **[Installation Guide](docs/INSTALLATION.md)** - Step-by-step instructions to get up and running.
-   ⚙️ **[Configuration Guide](docs/CONFIGURATION.md)** - Detailed explanation of the `config.json` file.
-   🚀 **[Usage Guide](docs/USAGE.md)** - Comprehensive user guide with examples and workflows.
-   🔧 **[Troubleshooting Guide](docs/TROUBLESHOOTING.md)** - Solutions for common issues.

## For Developers

Developers should start with the main development guide and pay special attention to the architectural documents to prevent common, critical bugs.

🚨 **[Development Guide](docs/DEVELOPMENT.md)** - **START HERE.** Covers setup, building, testing, and contribution guidelines.

### ⚠️ Critical Architecture Documents
These documents exist because positioning and coordinate system issues have occurred multiple times. Following these guidelines prevents them from recurring.

1.  **[COORDINATE_SYSTEM_GUIDE.md](docs/COORDINATE_SYSTEM_GUIDE.md)** - Explains the native Cocoa coordinate system. **Reading this is mandatory to prevent positioning failures.**
2.  **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - A deep dive into the system architecture and component design.
3.  **[TERMINOLOGY.md](docs/TERMINOLOGY.md)** - A reference for key terms like "Primary Monitor" vs. "Main Display" to avoid confusion.
4.  **[AI_AGENT_GUIDE.md](docs/AGENTS.md)** - Guidelines for AI-assisted development.

## Roadmap

✅ **Completed:** Native Cocoa Coordinate System & Dual Interface (CLI + GUI)
🚧 **Current Phase:** Advanced Features & Polish (Profile Management, Layout Snapshots)
📋 **Next:** Menu Bar App Integration
🎯 **Future:** Intelligence & Automation, Polish & Distribution

See [TODO.md](TODO.md) for the detailed development roadmap.

## Contributing

We welcome contributions! Please start by reading the **[Development Guide](docs/DEVELOPMENT.md)** to learn about:
- Setting up the development environment
- Code style guidelines
- Testing procedures
- The pull request process

## License

MIT License - see the `LICENSE` file for details.