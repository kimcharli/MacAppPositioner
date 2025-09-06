import SwiftUI

/**
 * Mac App Positioner - SwiftUI GUI Application
 *
 * A native macOS SwiftUI application that provides a graphical interface
 * for the Mac App Positioner window management system.
 *
 * This GUI application shares the same core logic (WindowManager, ProfileManager,
 * CoordinateManager, ConfigManager) with the CLI version, providing users with
 * a choice between command-line and graphical interfaces.
 */

@main
struct MacAppPositionerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
    }
}