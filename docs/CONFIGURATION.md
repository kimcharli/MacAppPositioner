# Configuration Guide

This is the single reference for the `config.json` format used by Mac App Positioner.

## Config File Locations

`ConfigManager` searches these paths in order and uses the first one found:

1. `~/.config/mac-app-positioner/config.json` (recommended)
2. `~/Library/Application Support/MacAppPositioner/config.json`
3. `./config.json` (current directory, useful for CLI)
4. `~/.mac-app-positioner/config.json` (legacy)

## Top-Level Structure

```json
{
  "profiles": { ... },
  "layout": { ... },
  "applications": { ... }
}
```

| Section | Required | Purpose |
| ------- | -------- | ------- |
| `profiles` | Yes | Monitor configurations for different environments |
| `layout` | Yes | Application-to-position assignments |
| `applications` | No | App-specific behaviors (e.g., Chrome workaround) |

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

### Workspace Position Values

| Position | Description |
| -------- | ----------- |
| `top_left` | Top-left quadrant of workspace monitor |
| `top_right` | Top-right quadrant |
| `bottom_left` | Bottom-left quadrant |
| `bottom_right` | Bottom-right quadrant |
| `keep` | Do not reposition |

### Builtin Position Values

| Position | Description |
| -------- | ----------- |
| `center` | Center on built-in display (default) |
| `keep` | Do not reposition |

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

## Applications

Defines special behaviors. Only needed for apps that require workarounds.

```json
"applications": {
  "com.google.Chrome": {
    "positioning_strategy": "chrome"
  }
}
```

| Property | Values | Purpose |
| -------- | ------ | ------- |
| `positioning_strategy` | `"chrome"`, `"default"` | Special window handling logic |
| `positioning` | `"keep"` | Override to prevent repositioning |
| `sizing` | `"keep"` | Override to prevent resizing |

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
  },
  "applications": {
    "com.google.Chrome": {
      "positioning_strategy": "chrome"
    }
  }
}
```

In this example:

- Chrome goes to top-left of the 3440x1440 workspace monitor with special Chrome handling
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

## Finding Monitor Resolutions

```bash
# Auto-detect current monitor setup
./dist/MacAppPositioner detect

# Generate a config template from current setup
./dist/MacAppPositioner generate-config
```
