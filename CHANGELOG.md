# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Remediation, Phases 0–2 (2026-09-10)

A structural audit found `plan` and `apply` computing target geometry twice by
different rules, a test suite that had never run, and a `generate-config` command
that emitted invalid JSON. Plan in `docs/REMEDIATION-PLAN-2026-09-10.md`.

#### Changed — behaviour

- **`apply` now skips windows already at their target** (within a 1pt tolerance)
  instead of re-setting every position. Re-running a profile no longer nudges
  windows you have already arranged. A `center` window that is already on its
  target display is likewise left where it is.
- **`plan` no longer invents targets it will not use.** Apps configured as `keep`,
  and apps that are not running, previously displayed a top-left target as though
  the window were about to move there. They now report `KEEP` or `UNAVAILABLE`
  with the reason, and `Target: unchanged` where nothing will happen.
- **`apply` is now defined as "execute what `plan` printed"** rather than a second
  implementation of the same rules. The preview and the run cannot disagree.
- Plan actions are **sorted by bundle ID**, so repeated runs list apps in a stable
  order. Previously the order came from dictionary iteration and varied run to run.

#### Fixed

- **[BUG]** `generate-config` emitted **invalid JSON** — a trailing comma made the
  output unparseable. It is now encoded from the config model rather than
  assembled by string concatenation.
- **[BUG]** `generate-config` produced **no workspace monitor at all** whenever the
  built-in display sorted first, so the generated config could not position
  anything. It also labelled monitors `left`, a role `update` never emits.
- **[BUG]** Profiles naming the built-in display as their workspace monitor
  (`"resolution": "builtin"` or `"macbook"`) were **detected but applied nothing**.
  The alias was resolved during detection but not when locating the monitor.
- **[BUG]** `plan` and `apply` disagreed for `center` and `keep`: plan routed both
  through the quadrant calculation, which collapsed them to the monitor's
  top-left corner.
- **[BUG]** `updateProfile` wrote through `ConfigManager.shared` instead of its
  injected config manager.
- **[BUG]** `getBuiltinScreen()` force-unwrapped its result and could trap when no
  screen matched. It now returns an optional.
- **[BUG]** Monitor detection loaded `ConfigManager.shared` internally, so a caller
  using an injected config had its monitor list — including the workspace flag —
  built from a different config file.
- **[TEST]** The test suite **had never run**: all five scripts named in
  `test_all.sh` were absent, and the runner contained a line of Python syntax.
  The suite now runs 9 tests and passes.

#### Added

- **`LayoutEngine`** — the single owner of target window geometry. Pure
  (Foundation + CoreGraphics only), so placement rules are testable directly.
  Replaces `positionApp`, `calculateQuadrantPosition` and `resolveWindowSize`.
- **`ScreenProviding`** and **`WindowControlling`** seams, letting screens, running
  processes and window frames be substituted with fixtures. Profile detection,
  plan generation and apply can now be tested without the author's hardware.
- **`config.example.json`**, a ready-to-copy template. `README.md` had instructed
  users to configure the app without shipping anything to configure it from.
- Fixture-based tests covering coordinate conversion, profile detection including
  the built-in alias, per-monitor targeting, the multi-process Chrome case, and
  apply-matches-plan.

#### Removed

- `Tests/test_chrome_simple.swift` and `Tests/test_positioning_success.swift`,
  which moved real windows and asserted against one specific machine's displays.
  Superseded by the fixture tests.

#### Documentation

- `INSTALLATION.md` no longer tells users to create their config with a command
  that produces an unparseable file.
- `AGENTS.md` and `TROUBLESHOOTING.md` no longer mandate a function that was
  deleted.
- `DEVELOPMENT.md` source tree, class table, coordinate rules and test template
  corrected against the code.
- `USAGE.md` samples recaptured from real command output.

### Code Review (2026-02-27)

**Findings documented in `TODO.md` under "Code Review Findings & Fix Plan".** Summary:

- 🔴 **2 bugs identified**: profile rename silently deletes the profile data; `saveConfig()` always writes to `./config.json` regardless of the path `loadConfig()` used.
- 🟡 **4 duplication issues**: monitor→position label mapping copy-pasted in 3 places; redundant `CocoaProfileManager` instance in `DashboardViewModel`; `generatePlan()` bypasses `self.configManager`; `BuiltinApp`/`WorkspaceApp` are near-identical structs.
- 🟠 **3 modularity issues**: redundant `MonitorInfo` mirror of `CocoaMonitorInfo`; `ConfigManager` injection without a protocol; no public cache-invalidation API on `ConfigManager`.
- 🔵 **5 best-practice issues**: `NSScreen.main` use in `CocoaMonitorInfo.init` (forbidden per AGENTS.md); dead `accessibilityErrorDescription` method; raw string literals for positions/roles instead of enums; unpersisted settings picker; magic numbers not centralised.

### Fixed

- **[BUG]** Profile rename now correctly inserts the profile under the new key before saving; previously the old key was removed without inserting the new one, silently deleting the profile.
- **[BUG]** `ConfigManager.saveConfig()` now writes back to the URL used by the last successful `loadConfig()` call instead of always writing to `./config.json`.
- **[DEDUP]** Replaced duplicate `BuiltinApp` / `WorkspaceApp` structs with a single unified `AppLayoutEntry`. Both types had identical `sizing` fields, identical legacy-string decode logic, and identical `CodingKeys`.
- **[DEDUP]** Extracted `CocoaCoordinateManager.positionLabel(for:) -> MonitorRole` to replace three copy-pasted if/else chains that mapped `CocoaMonitorInfo` flags to role strings.
- **[DEDUP]** `DashboardViewModel.detectCurrentMonitors()` now uses `self.profileManager` instead of allocating a throwaway `CocoaProfileManager()` instance.
- **[DEDUP]** `CocoaProfileManager.generatePlan()` now uses `configManager` (the instance variable) instead of bypassing it with `ConfigManager.shared`.
- **[MODULAR]** Removed the `MonitorInfo` mirror struct from `MonitorVisualizationView.swift`. `CocoaMonitorInfo` now conforms to `Identifiable` and is used directly in SwiftUI views, eliminating a manual field-by-field conversion loop in `DashboardViewModel`.
- **[MODULAR]** Added `ConfigManaging` protocol (`loadConfig / saveConfig / invalidateCache`) so `ConfigManager` can be swapped out in tests; sub-views now receive `any ConfigManaging`.
- **[MODULAR]** Added `ConfigManager.invalidateCache()` public method for explicit cache invalidation.
- **[PRACTICE]** Removed `isMain: Bool` from `CocoaMonitorInfo` (used `NSScreen.main`, forbidden per AGENTS.md; the property was never consumed).
- **[PRACTICE]** Wired the dead `accessibilityErrorDescription(_:)` method into `setWindowPosition()` log output for richer AX error reporting.
- **[PRACTICE]** Introduced `WindowPosition` and `MonitorRole` enums (both `Codable` with matching raw string values). All string-literal comparisons and switch statements across `ConfigManager`, `CocoaCoordinateManager`, `CocoaProfileManager`, and the GUI views now use typed enum cases. `calculateQuadrantPosition()` is now exhaustive.
- **[PRACTICE]** `SettingsView.defaultProfile` picker now uses `@AppStorage` so the selection survives app restarts.
- **[PRACTICE]** Added `AppConstants` namespace in `AppUtils.swift` centralising `defaultWindowSize` and `positioningTolerance`; removed the duplicate `private static let defaultWindowSize` from `CocoaProfileManager` and the inline `let tolerance: CGFloat = 1.0` literals.

- Fixed Outlook window positioning by improving window selection logic to prioritize the main application window and filter out secondary windows like "Reminders".
- Fixed a bug in the GUI build script that was causing it to fail.
- Corrected the coordinate system conversion logic to ensure windows are positioned correctly on external monitors.

### Added

- Implemented a "Plan" feature in the GUI to allow users to preview window positions before applying a layout.
- The plan is now displayed in a separate window with standard macOS controls for a more native feel.
- `plan` command to the CLI to show the execution plan without applying it.
- `generatePlan()` function to `CocoaProfileManager` to generate the execution plan.
- `PlanModels.swift` to the shared module to define the data structures for the execution plan.
- `/create-slash-command`, `/document-commit-push`, and `/inspect` slash commands for internal development.
- `Info.plist` file to create a proper macOS application bundle for the GUI.

### Changed

- The `plan` command in the CLI can now accept an optional profile name.
- Refactored the plan generation logic to be more flexible and reusable.
- Updated the GUI to use the modern `UserNotifications` framework for notifications.

## [1.0.0] - 2025-09-27

### Added

- Initial release of MacAppPositioner.
- `detect` command to detect the current monitor profile.
- `apply` command to apply a window layout profile.
- `generate-config` command to generate a configuration for the current monitor setup.
- `update-profile` command to update a profile with the current monitor setup.
- `test-coordinates` command to test the coordinate system.
- GUI for managing profiles and settings.
