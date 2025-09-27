# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

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
