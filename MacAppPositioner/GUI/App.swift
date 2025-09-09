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

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarManager: MenuBarManager?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        menuBarManager = MenuBarManager()
        menuBarManager?.setupMenuBar()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

@main
struct MacAppPositionerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            // This is needed to have an empty scene for the menu bar app
        }
    }
}