import Foundation
import AppKit

/**
 * Profile Manager
 * 
 * ARCHITECTURE PRINCIPLE:
 * - Uses a consistent internal coordinate system (top-left origin) for all calculations.
 */

class CocoaProfileManager {

    private let configManager: ConfigManaging
    private let coordinateManager: CocoaCoordinateManager
    private let windowController: WindowControlling

    /// Defaults reproduce the previous singleton wiring, so existing call sites
    /// are unchanged; tests inject fixtures instead.
    init(configManager: ConfigManaging = ConfigManager.shared,
         coordinateManager: CocoaCoordinateManager = .shared,
         windowController: WindowControlling? = nil) {
        self.configManager = configManager
        self.coordinateManager = coordinateManager
        self.windowController = windowController
            ?? SystemWindowController(coordinateManager: coordinateManager)
    }
    
    // MARK: - Profile Detection

    /// Monitors for the currently detected profile, with `isWorkspace` resolved.
    ///
    /// Front-ends call this rather than `CocoaCoordinateManager.getAllMonitors`
    /// directly, so the config that flags the workspace monitor is the same one
    /// this manager was constructed with.
    func currentMonitors() -> [CocoaMonitorInfo] {
        let workspaceResolution = detectProfile()
            .flatMap { configManager.loadConfig()?.profiles[$0] }?
            .monitors.first(where: { $0.position == .workspace })?.resolution

        return coordinateManager.getAllMonitors(workspaceResolution: workspaceResolution)
    }

    func detectProfile() -> String? {
        guard let config = configManager.loadConfig() else {
            print("Failed to load config")
            return nil
        }

        let monitors = coordinateManager.getAllMonitors()
        let currentResolutions = Set(monitors.map { AppUtils.normalizeResolution($0.resolution) })

        for (profileName, profile) in config.profiles {
            var profileResolutions: Set<String> = []
            
            for monitor in profile.monitors {
                if CocoaCoordinateManager.isBuiltInAlias(monitor.resolution) {
                    if let builtinMonitor = monitors.first(where: { $0.isBuiltIn }) {
                        profileResolutions.insert(AppUtils.normalizeResolution(builtinMonitor.resolution))
                    }
                } else {
                    profileResolutions.insert(AppUtils.normalizeResolution(monitor.resolution))
                }
            }
            
            if profileResolutions == currentResolutions {
                print("✅ Matched profile: \(profileName)")
                return profileName
            }
        }
        
        return nil
    }
    
    // MARK: - Plan Generation

    func generatePlan(for profileName: String) -> ExecutionPlan? {
        guard let config = configManager.loadConfig(), let profile = config.profiles[profileName] else {
            print("Failed to load config or profile.")
            return nil
        }

        let allMonitors = coordinateManager.getAllMonitors(
            workspaceResolution: profile.monitors.first(where: { $0.position == .workspace })?.resolution
        )
        var actions: [AppAction] = []

        if let workspaceMonitorConfig = profile.monitors.first(where: { $0.position == .workspace }),
           let workspaceMonitor = coordinateManager.findWorkspaceMonitor(resolution: workspaceMonitorConfig.resolution, from: allMonitors),
           let layout = config.layout?.workspace {
            for (bundleID, entry) in layout {
                actions.append(createAppAction(bundleID: bundleID,
                                               entry: entry,
                                               targetMonitor: workspaceMonitor,
                                               appSettings: config.applications?[bundleID]))
            }
        }

        if let builtinApps = config.layout?.builtin,
           let builtinMonitor = allMonitors.first(where: { $0.isBuiltIn }) {
            for (bundleID, entry) in builtinApps {
                actions.append(createAppAction(bundleID: bundleID,
                                               entry: entry,
                                               targetMonitor: builtinMonitor,
                                               appSettings: config.applications?[bundleID]))
            }
        }

        // Layout is a dictionary, so iteration order is not stable. Sort so that
        // plan output is reproducible and apply visits apps in the previewed order.
        actions.sort { $0.bundleID < $1.bundleID }

        return ExecutionPlan(profileName: profileName, monitors: allMonitors, actions: actions)
    }

    /// Builds one plan entry. All target geometry comes from `LayoutEngine`, which
    /// is also what `executePlan` acts on — so a preview and an apply cannot disagree.
    private func createAppAction(bundleID: String,
                                 entry: AppLayoutEntry,
                                 targetMonitor: CocoaMonitorInfo,
                                 appSettings: AppSettings?) -> AppAction {

        let currentFrame = windowController.currentWindowFrame(bundleID: bundleID)

        let placement = LayoutEngine.resolve(
            position: entry.position,
            sizing: entry.sizing,
            appSizingOverride: appSettings?.sizing,
            currentFrame: currentFrame,
            monitor: MonitorGeometry(frame: targetMonitor.frame,
                                     visibleFrame: targetMonitor.visibleFrame)
        )

        let appName = windowController.localizedName(bundleID: bundleID) ?? bundleID

        return AppAction(
            bundleID: bundleID,
            appName: appName,
            currentPosition: currentFrame,
            targetPosition: placement.targetFrame,
            action: placement.decision.actionType,
            reason: placement.decision.explanation
        )
    }

    // MARK: - Profile Application

    /// Applies a profile by generating a plan and executing it.
    ///
    /// Apply is deliberately *defined* as "execute what plan describes". The two
    /// used to be separate implementations of the same geometry rules and had
    /// already drifted: plan routed `center` and `keep` through the quadrant
    /// calculation and reported a top-left target that apply never used.
    func applyProfile(_ profileName: String) {
        guard let plan = generatePlan(for: profileName) else { return }
        executePlan(plan)
    }

    /// Executes a previously generated plan.
    ///
    /// PIDs are resolved here rather than captured in the plan, so an `AppAction`
    /// stays a pure description and cannot carry a stale process identifier.
    func executePlan(_ plan: ExecutionPlan) {
        // Remember which app had focus so we can restore it after positioning.
        let previousBundleID = windowController.frontmostBundleID()

        for action in plan.actions {
            print("\n📱 \(action.bundleID): \(action.action.rawValue) — \(action.reason)")

            guard action.action == .move, let target = action.targetPosition else { continue }

            guard let pid = windowController.addressablePID(bundleID: action.bundleID) else {
                print("  ❌ No moveable window found for \(action.bundleID).")
                continue
            }

            print("  \(coordinateManager.debugDescription(rect: target, label: "Target"))")
            windowController.setWindowPosition(pid: pid, position: target.origin, size: nil)
        }

        // Restore focus to the app that was active before positioning.
        if let previousBundleID = previousBundleID {
            windowController.activate(bundleID: previousBundleID)
        }
    }

    // MARK: - Utility Functions

    // MARK: - Profile Generation
    
    func updateProfile(name: String) {
        guard var config = configManager.loadConfig() else {
            print("Failed to load config.json")
            return
        }

        let existing = config.profiles[name]

        // Keep the workspace monitor the operator already chose. Without this the
        // role is recomputed from scratch, comes back empty, and every
        // layout.workspace app silently vanishes from the plan.
        let currentWorkspace = existing?.monitors
            .first(where: { $0.position == .workspace })?
            .resolution

        let newMonitors = coordinateManager.profileMonitors(preservingWorkspace: currentWorkspace)
        config.profiles[name] = Profile(monitors: newMonitors)

        guard configManager.saveConfig(config) else {
            print("❌ Failed to save updated configuration.")
            return
        }

        // Say which happened. Creating a profile and overwriting one are very
        // different outcomes to run by accident.
        print(existing == nil
              ? "✅ Profile '\(name)' created from the current monitor setup."
              : "✅ Profile '\(name)' updated successfully.")

        for monitor in newMonitors {
            print("   \(monitor.position.rawValue): \(monitor.resolution)")
        }
    }
    
    /// Prints every configured profile, its monitors, and which one matches the
    /// hardware attached right now.
    ///
    /// Without this there is no way to see what environments exist: `detect`
    /// names only the profile that matched, and on a machine that matches
    /// nothing it reports just that, leaving the operator to read the JSON to
    /// find out what it was looking for.
    func listProfiles() {
        guard let config = configManager.loadConfig() else {
            print("Failed to load config")
            return
        }

        guard !config.profiles.isEmpty else {
            print("No profiles configured.")
            return
        }

        let matched = detectProfile()
        let attached = Set(coordinateManager.getAllMonitors()
            .map { AppUtils.normalizeResolution($0.resolution) })

        print("\nProfiles:")
        for name in config.profiles.keys.sorted() {
            guard let profile = config.profiles[name] else { continue }
            let marker = name == matched ? " ← matches current setup" : ""
            print("\n  \(name)\(marker)")

            for monitor in profile.monitors.sorted(by: { $0.position.rawValue < $1.position.rawValue }) {
                // Resolve the alias so a profile written as "macbook" still shows
                // whether that display is actually here.
                let resolved = CocoaCoordinateManager.isBuiltInAlias(monitor.resolution)
                    ? coordinateManager.getAllMonitors().first(where: { $0.isBuiltIn })
                        .map { AppUtils.normalizeResolution($0.resolution) }
                    : AppUtils.normalizeResolution(monitor.resolution)

                let present = resolved.map(attached.contains) ?? false
                print("    \(present ? "✓" : "✗") \(monitor.position.rawValue): \(monitor.resolution)")
            }
        }

        if matched == nil {
            print("\n❌ Nothing matches the displays attached right now:")
            for resolution in attached.sorted() {
                print("    \(resolution)")
            }
            print("\n   A profile matches only when its monitor set is exactly the")
            print("   attached set. Run 'update <name>' here to record this setup.")
        }

        print("")
    }

    func generateConfig() {
        let config = generateConfigForCurrentSetup()
        print(config)
    }
    
    func generateConfigForCurrentSetup() -> String {
        let monitors = coordinateManager.getAllMonitors()

        // No profile exists yet when bootstrapping a config, so every monitor's
        // `isWorkspace` is false and `positionLabel(for:)` cannot classify them.
        // Heuristic: the first non-builtin display becomes the workspace monitor,
        // any further displays are secondary. Roles use the same vocabulary that
        // `positionLabel(for:)` emits, so a generated config and one written by
        // `update <profile>` agree.
        var workspaceAssigned = false
        let configuredMonitors: [Monitor] = monitors.map { monitor in
            let role: MonitorRole
            if monitor.isBuiltIn {
                role = .builtin
            } else if !workspaceAssigned {
                role = .workspace
                workspaceAssigned = true
            } else {
                role = .secondary
            }
            return Monitor(resolution: AppUtils.normalizeResolution(monitor.resolution),
                           position: role)
        }

        let config = Config(
            layout: Layout(
                workspace: [
                    "com.google.Chrome": AppLayoutEntry(position: .topLeft),
                    "com.microsoft.teams2": AppLayoutEntry(position: .topRight),
                    "com.microsoft.Outlook": AppLayoutEntry(position: .bottomLeft),
                    "com.slack.Slack": AppLayoutEntry(position: .bottomRight)
                ],
                builtin: [
                    "md.obsidian": AppLayoutEntry(position: .center)
                ]
            ),
            applications: nil,
            profiles: ["detected": Profile(monitors: configuredMonitors)],
            log_directory: nil
        )

        // Encode rather than concatenate strings. The previous template emitted a
        // trailing comma after `layout`, producing JSON that ConfigManager refused
        // to decode; encoding makes malformed output structurally impossible.
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(config),
              let json = String(data: data, encoding: .utf8) else {
            print("❌ Failed to encode generated configuration.")
            return ""
        }

        return json
    }
}
