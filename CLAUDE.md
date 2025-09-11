# MacAppPositioner - Claude Code Reference

## Quick Reference for Claude Code

### Project Structure
- **Binaries**: `./dist/MacAppPositioner`, `./dist/MacAppPositionerGUI`  
- **Scripts**: `./Scripts/build.sh`, `./Scripts/build-gui.sh`, `./Scripts/test_all.sh`
- **Config**: `~/.config/mac-app-positioner/config.json`
- **Sources**: `MacAppPositioner/` (Swift files)

### Common Commands

#### Build Commands
```bash
./Scripts/build.sh          # Build CLI only
./Scripts/build-gui.sh       # Build GUI only  
./Scripts/build-all.sh       # Build both CLI and GUI
./Scripts/test_all.sh        # Run all tests
```

#### CLI Usage
```bash
./dist/MacAppPositioner detect                    # Detect current setup
./dist/MacAppPositioner apply                     # Auto-detect and apply
./dist/MacAppPositioner apply office              # Apply specific profile
./dist/MacAppPositioner test-coordinates          # Test coordinate system
```

#### GUI Usage
```bash
./dist/MacAppPositionerGUI                        # Launch GUI app (development)
open ./dist/MacAppPositionerGUI                   # Launch GUI app (development)
open /Applications/MacAppPositionerGUI.app        # Launch GUI app (installed)
```

### ⚠️ **GUI Deployment Quick Checklist**

**After GUI changes - ALWAYS follow this sequence:**
```bash
1. ./Scripts/build-gui.sh                    # Build first
2. open ./dist/MacAppPositionerGUI           # Test from dist/ 
3. Manually copy to /Applications/ if needed # Drag & drop recommended
4. Verify About menu shows current timestamp # Confirm it's updated
```

**⚠️ Common Mistakes I Make:**
- ❌ Testing `/Applications/` version without copying updated build
- ❌ Forgetting to rebuild after code changes  
- ❌ Using `cp` command (permission issues) instead of drag & drop
- ❌ Not checking build timestamp in About menu

📋 **Full deployment process:** See `docs/DEVELOPMENT.md`

### 🤖 **Auto-Documentation System**

**Auto-Activation Triggers** - When you mention these phrases, I'll automatically review and update deployment docs:

```yaml
Primary Triggers:
  - "deployment docs need updating"
  - "documentation maintenance needed"  
  - "add this to troubleshooting guide"
  - "deployment process broken"
  - "GUI deployment issue"
  - "docs are outdated"

Technical Triggers:
  - "NSScreen.main issue"
  - "wrong build date in About"
  - "permission denied Applications"
  - "cached version problem"
  - "positioning still broken"
```

**Manual Documentation Maintenance:**
```bash
# Invoke comprehensive docs review and sync
/task "Review and update deployment documentation consistency" --agent document-reviewer

# Quick fix for specific issue  
/task "Add [specific issue] to deployment troubleshooting" --agent document-reviewer

# Sync CLAUDE.md ↔ DEVELOPMENT.md
/task "Synchronize deployment docs between CLAUDE.md and DEVELOPMENT.md" --agent document-reviewer
```

### Development Notes

#### Key Components
- **CocoaCoordinateManager**: Screen detection and positioning logic
- **CocoaProfileManager**: Profile management and application positioning
- **ConfigManager**: Configuration file handling
- **MenuBarManager**: GUI menu bar interface

#### Recent Fixes
- **NSScreen.main Issue**: Replaced unreliable `NSScreen.main` fallbacks with `getBuiltinScreen()` function
- **Builtin Screen Detection**: Multi-method detection (name, origin, size) for reliable builtin screen identification

#### Testing
- Always test both CLI and GUI after changes
- Use `test-coordinates` to verify screen detection
- Check positioning with actual applications after builds