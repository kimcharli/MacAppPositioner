> **Note for AI Agents:** Before performing any actions, please read the **[AI Agent Guide](docs/AGENTS.md)**.

# Mac App Positioner

A native macOS application that automatically positions application windows according to predefined layouts across multiple monitors. Perfect for developers, designers, and power users who work with multiple applications and displays.

**Available as both Command Line Interface (CLI) and Menu Bar GUI application.**

![macOS](https://img.shields.io/badge/macOS-11.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0+-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Dual Interface** - CLI and GUI applications sharing the same core logic
- **Multi-Monitor Support** - Works across multiple displays with different resolutions
- **Quadrant Positioning** - Divide workspace monitor into four zones for systematic app organization
- **Profile System** - Different layouts for home, office, or travel setups
- **Dynamic Detection** - Automatically detects current monitor configuration
- **Plan Preview** - See what will change before applying a layout
- **Application-Specific Rules** - Handle apps that resist positioning (like Chrome)
- **Native Swift** - Fast, efficient, follows macOS conventions

## Quick Start

1. **Build**:

    ```bash
    git clone https://github.com/kimcharli/MacAppPositioner.git
    cd MacAppPositioner
    ./Scripts/build-all.sh
    ```

2. **Configure** your layouts in `config.json` (see [Configuration Guide](docs/CONFIGURATION.md))
3. **Grant Accessibility Permissions** when prompted
4. **Apply**:

    ```bash
    ./dist/MacAppPositioner apply
    ```

## Documentation

### For Users

- [Installation Guide](docs/INSTALLATION.md) - Build, install, and set up permissions
- [Configuration Guide](docs/CONFIGURATION.md) - Config file format, profiles, layouts, bundle IDs
- [Usage Guide](docs/USAGE.md) - CLI commands, GUI usage, workflows
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions

### For Developers

- [Development Guide](docs/DEVELOPMENT.md) - Setup, building, testing, coordinate system rules, terminology
- [Architecture](docs/ARCHITECTURE.md) - System design, components, data flow
- [AI Agent Guide](docs/AGENTS.md) - Quick reference for AI-assisted development

## Roadmap

See [TODO.md](TODO.md) for the detailed development roadmap.

**Current state**: Dual-interface app (CLI + GUI) with native coordinate system, multi-monitor support, and profile-based layouts.

**Next**: Enhanced profile management, layout snapshots, menu bar integration improvements.

## Contributing

See the [Development Guide](docs/DEVELOPMENT.md) for setup, code style, testing, and PR process.

## License

MIT License - see the `LICENSE` file for details.
