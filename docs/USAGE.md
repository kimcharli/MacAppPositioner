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
✅ Accessibility permission: granted
✅ Matched profile: office
✅ Detected profile: office
```

If no profile's resolution set matches your attached displays, it reports `❌ No matching profile detected.`

### `plan` - Preview Execution Plan

Shows what would happen without moving any windows.

```bash
./dist/MacAppPositioner plan
./dist/MacAppPositioner plan office    # Specific profile
```

Output:

```text
✅ Execution Plan for Profile: office

Monitors:
  - 2056.0x1329.0 (Workspace: false, Built-in: true)
  - 2560.0x1440.0 (Workspace: true, Built-in: false)
  - 3840.0x2160.0 (Workspace: false, Built-in: false)

App Actions:
  - Google Chrome:
    Action: MOVE — will be repositioned
    Current: (0.0, -2130.0, 2056.0, 1200.0) [Accessibility]
    Target: (-2560.0, -1440.0, 2056.0, 1200.0) [Accessibility]
  - com.slack.Slack:
    Action: UNAVAILABLE — not running, or no moveable window
    Current: Not running or window not found
    Target: (-1200.0, -800.0, 1200.0, 800.0) [Accessibility]
  - Obsidian:
    Action: KEEP — already on the target screen
    Current: (0.0, 52.0, 2056.0, 1225.0) [Accessibility]
    Target: unchanged
```

Every action carries the reason it was chosen:

| Action | Meaning |
| ------ | ------- |
| `MOVE — will be repositioned` | The window will be moved to `Target` |
| `KEEP — layout says 'keep'` | Your config asked for `"position": "keep"` |
| `KEEP — already at the target position` | Already there, within a 1pt tolerance |
| `KEEP — already on the target screen` | A `center` window already on its target display, so it is left where you put it |
| `UNAVAILABLE — not running, or no moveable window` | No process for that bundle ID exposes a window that can be moved |

`Target: unchanged` means nothing will be done. Apps whose action is not `MOVE` are never touched.

An app listed as `UNAVAILABLE` still shows where it *would* go, which is why it displays a `Target` — that is a preview, not a pending move.

### `apply` - Apply Layout

Positions running applications according to a profile's layout.

```bash
./dist/MacAppPositioner apply          # Auto-detect profile
./dist/MacAppPositioner apply office   # Force specific profile
```

`apply` executes exactly what `plan` prints — it runs the same plan rather than recomputing positions. Windows already within a point of their target are left alone, so re-running is safe and does not nudge windows.

Focus returns to whichever app was frontmost before the run.

### `list` - List Profiles

Shows every configured profile, its monitors, and which one matches the
displays attached right now. `✓` means that display is present, `✗` means it
is not.

```bash
./dist/MacAppPositioner list
```

```text
Profiles:

  home ← matches current setup
    ✓ builtin: 2056x1329
    ✓ secondary: 2560x1440
    ✓ workspace: 3840x2160

  office
    ✓ builtin: macbook
    ✗ workspace: 3440x1440
```

When nothing matches, it lists what *is* attached, which is usually enough to
spot the mismatch:

```text
❌ Nothing matches the displays attached right now:
    2056x1329
    2560x1440
    3840x2160
```

A profile matches only when its monitor set is **exactly** the attached set —
not a subset. Two monitors at the office and three at home therefore need two
profiles.

### `update` - Create or Update a Profile

Writes your current monitor setup into a profile, creating it if it does not
exist yet. This is how you add a second environment.

```bash
./dist/MacAppPositioner update office
```

It prints the roles it recorded, and says whether it created or overwrote:

```text
✅ Profile 'office' created from the current monitor setup.
   builtin: 2056x1329
   workspace: 2560x1440
   secondary: 3840x2160
```

Updating an existing profile **keeps the workspace monitor you already chose**.
When creating a new one there is nothing to preserve, so the first non-builtin
display is used — which is enumeration order, not a judgement about your desk.
Name the one you want explicitly:

```bash
./dist/MacAppPositioner update office --workspace 3440x1440
```

The resolution is checked against the attached displays, so a typo fails
instead of silently producing a profile that positions nothing:

```text
❌ No attached display matches '9999x9999'.
   Attached:
     2056x1329
     2560x1440
     3840x2160
```

Which screen is `workspace` decides where the whole `layout.workspace` section
lands, so it is worth getting right — check the roles it prints.

### `generate-config` - Generate Config Template

Outputs a JSON configuration template based on your current monitors. The `profiles` section reflects the displays actually attached; the `layout` section is a fixed five-app starter template (Chrome, Teams, Outlook, Slack, Obsidian) and is **not** derived from what you have running. Add any other app to `layout` yourself.

```bash
./dist/MacAppPositioner generate-config
```

Diagnostics go to stderr and the JSON goes to stdout, so the output can be redirected straight to a file:

```bash
./dist/MacAppPositioner generate-config > ~/.config/mac-app-positioner/config.json
```

### `test-coordinates` - Coordinate Diagnostics

Prints each monitor's raw Cocoa frame, visible frame, and built-in/workspace flags, followed by what `NSScreen.main` reports. Useful when windows land on the wrong display and you need to see the geometry the app is working from.

```bash
./dist/MacAppPositioner test-coordinates
```

```text
📺 All Monitors (Native Cocoa Coordinates):
Monitor 1: 2056.0x1329.0
  Frame: (0.0, 0.0, 2056.0, 1329.0) [Native Cocoa]
  Visible Frame: (0.0, 39.0, 2056.0, 1290.0) [Native Cocoa]
  isBuiltIn: true, isWorkspace: false
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
5. Preview: `./dist/MacAppPositioner plan`
6. Apply: `./dist/MacAppPositioner apply`

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
- **Use `plan` to debug**: Preview before applying to see what will change, and read the reason on each action
- **Re-running `apply` is safe**: windows already at their target are skipped
- **Test one app first**: When setting up a new profile, test with a single app before configuring many
- **Monitor arrangement matters**: Profile detection matches by resolution set, not physical arrangement
- **Check the logs**: every run writes to `~/Library/Logs/mac-app-positioner/`; the first lines show whether Accessibility permission was granted
