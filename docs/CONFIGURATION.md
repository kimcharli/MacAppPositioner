# Configuration Guide

This is the single reference for the `config.json` format used by Mac App Positioner.

## Getting Started

A ready-to-edit template ships with the repository as [`config.example.json`](../config.example.json):

```bash
mkdir -p ~/.config/mac-app-positioner
cp config.example.json ~/.config/mac-app-positioner/config.json
```

Then replace the resolutions under `profiles` with your own — run `./dist/MacAppPositioner generate-config` to see what the app detects.

## Config File Locations

`ConfigManager` searches these paths in order and uses the first one found:

1. `~/.config/mac-app-positioner/config.json` (recommended)
2. `~/Library/Application Support/MacAppPositioner/config.json`
3. `./config.json` (current directory, useful for CLI)
4. `~/.mac-app-positioner/config.json` (legacy)

## Top-Level Structure

```json
{
  "log_directory": "~/Library/Logs/mac-app-positioner",
  "profiles": { ... },
  "layout": { ... },
  "applications": { ... }
}
```

| Field | Required | Purpose |
| ----- | -------- | ------- |
| `log_directory` | No | Directory for log files (default: `~/Library/Logs/mac-app-positioner`) |
| `profiles` | Yes | Monitor configurations for different environments |
| `layout` | Yes | Application-to-position assignments |
| `applications` | No | App-specific overrides (only `sizing` today) |

## Profiles

Each profile defines a monitor setup identified by resolutions.

```json
"profiles": {
  "office": {
    "monitors": [
      { "resolution": "3440x1440", "position": "workspace" },
      { "resolution": "2560x1440", "position": "left" },
      { "resolution": "macbook", "position": "builtin" }
    ]
  },
  "home": {
    "monitors": [
      { "resolution": "3840x2160", "position": "workspace" },
      { "resolution": "macbook", "position": "builtin" }
    ]
  }
}
```

### Monitor Position Types

| Position | Meaning |
| -------- | ------- |
| `workspace` | Target monitor for quadrant-based app positioning |
| `builtin` | MacBook's built-in display |
| `left`, `right` | Physical position descriptors for additional monitors |
| `secondary` | Additional monitor without specific role |

### Resolution Format

- External monitors: `"3440x1440"`, `"3840x2160"`, etc.
- Built-in display: `"macbook"` (shorthand) or exact dimensions like `"2056x1329"`

Use `./dist/MacAppPositioner detect` or `generate-config` to see your actual resolutions.

## Layout

Defines where applications are positioned. Layout has two sections: `workspace` (external monitor quadrants) and `builtin` (MacBook screen).

```json
"layout": {
  "workspace": {
    "com.google.Chrome": { "position": "top_left" },
    "com.microsoft.Outlook": { "position": "bottom_left" },
    "com.microsoft.teams2": { "position": "top_right" },
    "com.kakao.KakaoTalkMac": { "position": "bottom_right" }
  },
  "builtin": {
    "md.obsidian": { "position": "keep" }
  }
}
```

### Position Values

`position` uses the same set of values in **both** the `workspace` and `builtin`
sections — there is one position type, not two.

| Position | Description |
| -------- | ----------- |
| `top_left` | Top-left quadrant of the target monitor |
| `top_right` | Top-right quadrant |
| `bottom_left` | Bottom-left quadrant |
| `bottom_right` | Bottom-right quadrant |
| `center` | Centred on the target monitor (also the default when `position` is omitted) |
| `keep` | Do not reposition |

In practice `center` is the usual choice for the `builtin` section and the
quadrants for `workspace`, but nothing prevents the other combinations.

A `center` window that is **already on its target monitor** is left where it is
rather than snapped to the exact centre, so re-applying a profile does not
disturb a window you positioned by hand.

### Workspace Quadrant Diagram

```text
+-------------------+-------------------+
|    top_left       |    top_right      |
|                   |                   |
+-------------------+-------------------+
|   bottom_left     |   bottom_right    |
|                   |                   |
+-------------------+-------------------+
```

### Optional Properties

Each app entry supports:

- `position` (required): Where to place the window
- `sizing`: `"keep"` (default) preserves current window size

### What Happens to an Invalid Position

The two config forms behave **differently**, which is worth knowing when a layout
isn't doing what you expect:

| Written as | Result |
| ---------- | ------ |
| `{ "position": "top-left" }` (object form, typo) | The **entire config fails to load** |
| `"top-left"` (legacy string form, typo) | Silently treated as `center`, no warning |
| `{ "sizing": "keep" }` (`position` omitted) | Defaults to `center` |

In the object form a bad value is reported precisely:

```text
Error decoding config at /Users/you/.config/mac-app-positioner/config.json:
  Data was corrupted. Path: layout.workspace.`com.google.Chrome`.position.
  Cannot initialize WindowPosition from invalid String value top-left
```

Note that this message is followed by `Config not found in any standard location`
and the list of search paths. That second message is misleading — your file *was*
found, it just could not be decoded. Fix the path named in the first message.

The legacy string form has no such safety net: a typo there centres the window
instead of failing, so prefer the object form.

### Legacy Shorthand

An older format, where the value is the position string directly, still loads:

```json
"workspace": {
  "com.google.Chrome": "top_left"
}
```

This is equivalent to `{ "position": "top_left", "sizing": "keep" }`. New configs
should use the object form: it is the only one that can carry `sizing`, and it
reports typos instead of silently centring the window.

## Applications

Optional per-application overrides. Most configs don't need this section.

```json
"applications": {
  "com.google.Chrome": {
    "sizing": "keep"
  }
}
```

| Property | Values | Purpose |
| -------- | ------ | ------- |
| `sizing` | `"keep"` | Prevent resizing this app, regardless of its layout entry |

To stop an app being **moved**, set its layout position to `"keep"` instead — see
[Position Values](#position-values).

> **Chrome and other multi-process apps** need no configuration. Applications that
> run several processes under one bundle ID (a visible window plus a headless or
> debugging instance) are handled automatically: the app probes each process and
> picks the one that actually owns a moveable window. See
> [Troubleshooting section 10](TROUBLESHOOTING.md).

## Complete Example

```json
{
  "profiles": {
    "office": {
      "monitors": [
        { "resolution": "3440x1440", "position": "workspace" },
        { "resolution": "macbook", "position": "builtin" }
      ]
    }
  },
  "layout": {
    "workspace": {
      "com.google.Chrome": { "position": "top_left" },
      "com.microsoft.Outlook": { "position": "bottom_left" },
      "com.microsoft.teams2": { "position": "top_right" },
      "com.kakao.KakaoTalkMac": { "position": "bottom_right" }
    },
    "builtin": {
      "md.obsidian": { "position": "keep" }
    }
  }
}
```

In this example:

- Chrome goes to top-left of the 3440x1440 workspace monitor
- Outlook goes to bottom-left, Teams top-right, KakaoTalk bottom-right
- Obsidian stays wherever it is on the built-in display

## Finding Bundle IDs

```bash
# Detect a specific app's bundle ID
osascript -e 'id of app "Chrome"'
# Output: com.google.Chrome

# List all running foreground apps
osascript -e 'tell application "System Events" to get bundle identifier of every process whose background only is false'
```

### Common Bundle IDs

**Browsers**: `com.google.Chrome`, `com.apple.Safari`, `org.mozilla.firefox`

**Communication**: `com.tinyspeck.slackmacgap` (Slack), `com.microsoft.teams2`, `com.hnc.Discord`, `us.zoom.xos`

**Development**: `com.microsoft.VSCode`, `com.apple.dt.Xcode`, `com.apple.Terminal`, `com.googlecode.iterm2`

**Productivity**: `com.microsoft.Outlook`, `notion.id`, `md.obsidian`

## Logging

Both CLI and GUI automatically write a timestamped log file for every session.

### Configuration

```json
{
  "log_directory": "~/Library/Logs/mac-app-positioner"
}
```

| Field | Default | Description |
| ----- | ------- | ----------- |
| `log_directory` | `~/Library/Logs/mac-app-positioner` | Directory where log files are written. Supports `~` for home directory. |

When omitted, logs are written to `~/Library/Logs/mac-app-positioner`.

### Log File Naming

Files are named `<mode>-<timestamp>.log`:

- CLI: `cli-20260304-183136.log`
- GUI: `gui-20260304-190000.log`

### How It Works

`AppLogger` overrides the global `print()` function so all output is automatically teed to both stdout and the log file. No changes to existing code are needed — any `print()` call is captured.

The logger reads `log_directory` directly from config.json via a lightweight pre-parse (independent of `ConfigManager`) to avoid circular dependencies during startup.

### Log File Location

```bash
ls ~/Library/Logs/mac-app-positioner/
# cli-20260304-183136.log  gui-20260304-190000.log  ...
```

## Finding Monitor Resolutions

```bash
# Auto-detect current monitor setup
./dist/MacAppPositioner detect

# Generate a config template from current setup
./dist/MacAppPositioner generate-config
```

`generate-config` prints only the JSON payload on stdout — diagnostics go to
stderr — so it can be redirected straight to a file.
