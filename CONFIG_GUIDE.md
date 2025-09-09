# Configuration Guide

## Configuration Structure

The `config.json` file has a clear and consistent structure:

### 1. Profiles Section
Defines monitor configurations for different environments (home, office, etc.)

### 2. Layout Section
**Defines application positions and positioning behavior:**

#### Workspace Layout
Each app in workspace has:
- `position`: Where the app should be placed (`"top_left"`, `"top_right"`, `"bottom_left"`, `"bottom_right"`)
- `positioning`: Optional override (`"keep"` to prevent repositioning)
- `sizing`: Optional override (`"keep"` is default - preserves window size)

#### Builtin Layout
Each app in builtin has:
- `positioning`: Optional (`"keep"` to prevent repositioning, default is to move to builtin screen)
- `sizing`: Optional (`"keep"` is default - preserves window size)

### 3. Applications Section
**Defines special behaviors only:**
- `positioning_strategy`: Special positioning logic (e.g., `"chrome"` for Chrome-specific handling)
- Other app-specific settings that don't fit in the layout

## How It Works

1. Apps in `layout.workspace` are positioned according to their `position` value
2. Apps in `layout.builtin` are moved to the built-in display
3. Both can have `position: "keep"` to prevent repositioning
4. The `applications` section is only for special behaviors

## Position Values

### Workspace Apps
- `"top_left"`, `"top_right"`, `"bottom_left"`, `"bottom_right"` - Quadrant positions
- `"keep"` - Don't reposition (stays in current location)

### Builtin Apps
- `"center"` - Center on builtin display (default)
- `"keep"` - Don't reposition (stays in current location)

## Example

```json
{
  "layout": {
    "workspace": {
      "com.google.Chrome": {
        "position": "top_left"
      },
      "com.microsoft.Outlook": {
        "position": "bottom_left"
      }
    },
    "builtin": {
      "md.obsidian": {
        "position": "keep"  // Stays where it is
      }
    }
  },
  "applications": {
    "com.google.Chrome": {
      "positioning_strategy": "chrome"  // Special Chrome window handling
    }
  }
}
```

In this example:
- Chrome: Positioned at top_left with special Chrome handling
- Outlook: Positioned at bottom_left on workspace monitor
- Obsidian: Listed for builtin but won't move due to "keep"

## Usage Commands

The MacAppPositioner supports intelligent profile application:

### Auto-Detection Mode
```bash
MacAppPositioner apply
```
- Automatically detects current monitor configuration
- Applies the matching profile
- No need to specify profile name

### Force Mode
```bash
MacAppPositioner apply office
MacAppPositioner apply home
```
- Forces application of specific profile
- Bypasses auto-detection
- Useful for testing or manual override