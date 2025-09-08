# Testing Guide - Mac App Positioner

## 🧪 Coordinate System Test Suite

**This test suite prevents coordinate system bugs that have occurred multiple times in the project.**

## Quick Start

### Development Workflow
```bash
# Quick validation during development
./test_quick.sh

# Full test suite before commits
./Scripts/test_all.sh
```

### Build Integration
```bash
# Build with test validation tip
./Scripts/build.sh
./Scripts/build-gui.sh
```

## Test Scripts

### `./test_quick.sh` - Quick Development Test
- **Purpose**: Fast validation during development
- **Runtime**: ~2 seconds
- **Tests**: Core coordinate system functionality
- **Use**: Run before/after code changes

### `./Scripts/test_all.sh` - Comprehensive Test Suite  
- **Purpose**: Full validation before commits/releases
- **Runtime**: ~10 seconds
- **Tests**: All coordinate system validation tests
- **Use**: Run before committing code

### Individual Test Scripts

#### `test_coordinate_system_simple.swift`
**Core coordinate system validation**
- Main screen detection
- 4K monitor detection  
- Coordinate conversion accuracy
- Window position validation

#### `test_positioning_integration.swift`
**Window positioning integration test**
- Simulates real positioning scenarios
- Validates quadrant calculations
- Tests monitor targeting accuracy

#### `test_canonical_coordinate_validation.swift`
**CanonicalCoordinateManager validation**
- Tests actual Swift class implementation
- Validates coordinate conversion methods
- Configuration validation

## Test Categories

### 1. Coordinate System Tests
**Prevents**: Wrong coordinate system usage, coordinate mixing
```bash
✅ Coordinate conversion accuracy
✅ Spatial relationship preservation
✅ Main display identification
✅ Multi-monitor setup validation
```

### 2. Window Positioning Tests  
**Prevents**: Windows appearing on wrong screens
```bash
✅ Quadrant position calculations
✅ Monitor boundary validation
✅ Target screen accuracy
✅ Built-in vs external screen distinction
```

### 3. Monitor Detection Tests
**Prevents**: Incorrect monitor identification
```bash
✅ Main screen detection (NSScreen.main)
✅ 4K display detection
✅ Monitor resolution matching
✅ Multi-monitor arrangement
```

### 4. Configuration Tests
**Prevents**: Config-related positioning failures
```bash
✅ Config.json structure validation
✅ Primary monitor definition
✅ Profile resolution matching
✅ Layout configuration integrity
```

## Test Results Interpretation

### ✅ ALL TESTS PASS
```
Coordinate system is working correctly
Windows will be positioned accurately  
Safe to proceed with development/deployment
```

### ❌ SOME TESTS FAILED
```
⚠️  COORDINATE SYSTEM ISSUES DETECTED!
Review failed tests immediately
Fix coordinate system before proceeding
Run tests again after fixes
```

## Adding New Tests

### When to Add Tests
- **New coordinate features**: Add validation tests
- **Monitor setup changes**: Update expected values
- **Positioning logic changes**: Add integration tests
- **Bug fixes**: Add regression tests

### Test Template
```swift
#!/usr/bin/env swift
import AppKit

print("=== New Test Name ===")

var testPass = true

// Test implementation
// ...

print("Result: \(testPass ? "✅ PASS" : "❌ FAIL")")
exit(testPass ? 0 : 1)
```

## Troubleshooting Test Failures

### Common Issues

#### Test 1: Main Screen Detection FAIL
**Cause**: NSScreen.main not returning built-in display
**Fix**: Check System Preferences > Displays arrangement

#### Test 2: 4K Monitor Detection FAIL  
**Cause**: 4K display not connected or different resolution
**Fix**: Verify monitor connection, update expected resolution

#### Test 3: Coordinate Conversion FAIL
**Cause**: Coordinate conversion logic error
**Fix**: Review CanonicalCoordinateManager implementation

#### Test 4: Window Position Validation FAIL
**Cause**: Position calculations targeting wrong screen
**Fix**: Check quadrant calculation logic

### Debug Commands
```bash
# Check current monitor setup
swift test_main_screen.swift
swift test_monitor_detection.swift

# Test coordinate conversion manually  
swift test_coordinate_conversion.swift

# Validate config structure
cat config.json | jq '.'
```

## Integration with Development

### Pre-Commit Checklist
- [ ] `./test_quick.sh` passes
- [ ] Code changes don't break coordinate system
- [ ] New features have test coverage

### Pre-Release Checklist  
- [ ] `./Scripts/test_all.sh` passes
- [ ] All coordinate system tests pass
- [ ] Manual positioning test successful
- [ ] Multi-monitor setup validated

### CI/CD Integration
```yaml
# Example GitHub Actions integration
- name: Run Coordinate System Tests
  run: |
    ./Scripts/test_all.sh
    
- name: Validate Positioning
  run: |
    ./MacAppPositioner/MacAppPositioner apply home --debug
```

## Test Maintenance

### When Monitor Setup Changes
1. Update expected values in test scripts
2. Run `swift test_monitor_detection.swift` to get current values
3. Update test assertions accordingly
4. Verify all tests pass with new setup

### When Adding Monitors
1. Add new monitor to test cases
2. Update spatial relationship tests
3. Validate coordinate conversion for new setup
4. Test positioning on new monitor

### Performance Considerations
- Tests run in ~10 seconds total
- Individual tests complete in ~2 seconds
- No external dependencies required
- Safe to run frequently during development

## Success Criteria

**Tests are working correctly when:**
- All coordinate system tests pass consistently
- Window positioning tests validate correct screen targeting
- Monitor detection tests identify hardware correctly
- Configuration tests validate setup integrity
- Tests run quickly and reliably

**Following this testing approach prevents the coordinate system bugs that have repeatedly affected Mac App Positioner.**

---

*This testing system ensures coordinate system reliability and prevents positioning failures through early detection and validation.*