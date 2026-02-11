# Usage Guide

How to use Mac App Positioner to manage window layouts across multiple monitors.

## Prerequisites

1. **Accessibility permissions** must be granted (see [Installation Guide](INSTALLATION.md))
2. **config.json** must be set up (see [Configuration Guide](CONFIGURATION.md))
3. **Applications** you want to position must be running

## CLI Commands

All commands use the binary in `dist/`:

```bash
./dist/MacAppPositioner <command> [arguments]
```

### `detect` - Profile Detection

Detects your current monitor configuration and finds a matching profile.

```bash
./dist/MacAppPositioner detect
```

Output:

```text
Detected profile: office
```

### `plan` - Preview Execution Plan

Shows what would happen without actually moving windows.

```bash
./dist/MacAppPositioner plan
./dist/MacAppPositioner plan office    # Specific profile
```

Output:

```text
Execution Plan for Profile: office

Monitors:
  - 3440x1440 (Workspace: true, Built-in: false)
  - 1440x900 (Workspace: false, Built-in: true)

App Actions:
  - Google Chrome:
    Action: MOVE
    Current: (100.0, 200.0, 1200.0, 800.0)
    Target: (0.0, 0.0, 1200.0, 800.0)
  - Slack:
    Action: KEEP
```

### `apply` - Apply Layout

Positions running applications according to a profile's layout.

```bash
./dist/MacAppPositioner apply          # Auto-detect profile
./dist/MacAppPositioner apply office   # Force specific profile
```

### `update` - Update Profile

Updates an existing profile with your current monitor configuration.

```bash
./dist/MacAppPositioner update office
```

### `generate-config` - Generate Config Template

Outputs a JSON configuration template based on your current monitors.

```bash
./dist/MacAppPositioner generate-config
```

## GUI Usage

### Menu Bar

The GUI runs as a menu bar app. Click the monitor icon in the menu bar for:

- **Detect Current Setup** - Identify which profile matches
- **Apply Auto** - Auto-detect and apply the matching profile
- **Open Dashboard** - Open the full management window

### Dashboard

The dashboard provides:

- **Profile Detection**: Shows the currently detected profile. Refresh at any time.
- **Available Profiles**: Lists all profiles from your config.
- **Apply Layout**: Click to position apps per that profile.
- **Plan Layout**: Preview the execution plan before applying (shows current vs target positions).

## Common Workflows

### Daily Usage

1. Connect your monitors
2. Launch your apps
3. Run `./dist/MacAppPositioner apply` (or click Apply Auto in menu bar)

### Setting Up a New Profile

1. Arrange monitors in System Settings > Displays
2. Run `./dist/MacAppPositioner generate-config` to see detected resolutions
3. Add the profile to your `config.json` (see [Configuration Guide](CONFIGURATION.md))
4. Test: `./dist/MacAppPositioner detect`
5. Apply: `./dist/MacAppPositioner apply`

### Switching Between Setups

```bash
# Arrived at office - disconnect home monitor, connect office monitors
./dist/MacAppPositioner detect         # Should show "office"
./dist/MacAppPositioner apply office
```

### Shell Aliases

Add to `~/.zshrc`:

```bash
alias layout-office='~/path/to/dist/MacAppPositioner apply office'
alias layout-home='~/path/to/dist/MacAppPositioner apply home'
alias layout-detect='~/path/to/dist/MacAppPositioner detect'
```

## Tips

- **Launch apps first**: Windows must exist before they can be positioned
- **Use `plan` to debug**: Preview before applying to see what will change
- **Test one app first**: When setting up a new profile, test with a single app before configuring many
- **Monitor arrangement matters**: Profile detection matches by resolution set, not physical arrangement
