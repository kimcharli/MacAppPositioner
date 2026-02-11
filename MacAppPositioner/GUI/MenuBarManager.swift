import Foundation
import AppKit
import SwiftUI
import UserNotifications

class MenuBarManager: NSObject {
    private var statusItem: NSStatusItem?
    private var window: NSWindow?
    private let profileManager = CocoaProfileManager()

    func setupMenuBar() {
        // Request notification permissions (requires valid app bundle)
        if Bundle.main.bundleIdentifier != nil {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error = error {
                    NSLog("Failed to request notification permissions: \(error.localizedDescription)")
                }
            }
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "display.2", accessibilityDescription: "Mac App Positioner")
            button.action = #selector(showMenu(_:))
            button.target = self
        }
    }

    @objc func showMenu(_ sender: AnyObject?) {
        let menu = NSMenu()

        // Detect current setup
        let detectMenuItem = NSMenuItem(title: "Detect Current Setup", action: #selector(detectCurrentSetup), keyEquivalent: "d")
        detectMenuItem.target = self
        detectMenuItem.image = NSImage(systemSymbolName: "doc.text.magnifyingglass", accessibilityDescription: "Detect Setup")
        menu.addItem(detectMenuItem)

        // Auto apply (detect and apply matching profile)
        let autoApplyMenuItem = NSMenuItem(title: "Apply Auto", action: #selector(autoApplyProfile), keyEquivalent: "a")
        autoApplyMenuItem.target = self
        autoApplyMenuItem.image = NSImage(systemSymbolName: "wand.and.stars", accessibilityDescription: "Auto Apply")
        menu.addItem(autoApplyMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Profiles submenu
        let profilesMenuItem = NSMenuItem(title: "Profiles", action: nil, keyEquivalent: "")
        profilesMenuItem.image = NSImage(systemSymbolName: "folder.fill", accessibilityDescription: "Profiles")
        menu.addItem(profilesMenuItem)

        let profilesSubmenu = NSMenu()
        if case .success(let profiles) = AppUtils.loadProfileNames() {
            for profileName in profiles {
                let profileMenuItem = NSMenuItem(title: profileName, action: #selector(applyProfile(_:)), keyEquivalent: "")
                profileMenuItem.target = self
                profileMenuItem.representedObject = profileName
                if profileName.lowercased() == "home" {
                    profileMenuItem.image = NSImage(systemSymbolName: "house.fill", accessibilityDescription: "Home Profile")
                } else if profileName.lowercased() == "office" {
                    profileMenuItem.image = NSImage(systemSymbolName: "building.2.fill", accessibilityDescription: "Office Profile")
                } else {
                    profileMenuItem.image = NSImage(systemSymbolName: "display.2", accessibilityDescription: "Profile")
                }
                profilesSubmenu.addItem(profileMenuItem)
            }
        } else {
            let noProfilesItem = NSMenuItem(title: "No profiles found", action: nil, keyEquivalent: "")
            noProfilesItem.isEnabled = false
            profilesSubmenu.addItem(noProfilesItem)
        }
        menu.setSubmenu(profilesSubmenu, for: profilesMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Open dashboard (optional GUI)
        let openMenuItem = NSMenuItem(title: "Open Dashboard", action: #selector(openWindow), keyEquivalent: "o")
        openMenuItem.target = self
        openMenuItem.image = NSImage(systemSymbolName: "rectangle.3.group.fill", accessibilityDescription: "Dashboard")
        menu.addItem(openMenuItem)

        menu.addItem(NSMenuItem.separator())

        // About menu item
        let aboutMenuItem = NSMenuItem(title: "About Mac App Positioner", action: #selector(showAbout), keyEquivalent: "")
        aboutMenuItem.target = self
        aboutMenuItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: "About")
        menu.addItem(aboutMenuItem)

        menu.addItem(NSMenuItem.separator())

        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitMenuItem)

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc func openWindow() {
        if window == nil {
            let contentView = ContentView()
            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false)
            window?.center()
            window?.setFrameAutosaveName("Main Window")
            window?.contentView = NSHostingView(rootView: contentView)
            window?.isReleasedWhenClosed = false
            window?.title = "Mac App Positioner"
            // Ensure window appears above other windows
            window?.level = NSWindow.Level.floating
        }
        
        // Bring window to front and make it key
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        
        // Reset window level to normal after bringing to front
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.window?.level = NSWindow.Level.normal
        }
    }

    @objc func detectCurrentSetup() {
        if let profile = profileManager.detectProfile() {
            showNotification(title: "Profile Detected", message: "Current setup matches profile: \(profile)")
        } else {
            showNotification(title: "No Profile Match", message: "Current monitor setup doesn't match any saved profiles.")
        }
    }
    
    @objc func autoApplyProfile() {
        NSLog("MenuBarManager: autoApplyProfile called")
        print("MenuBarManager: autoApplyProfile called (print)")
        
        if let detectedProfile = profileManager.detectProfile() {
            NSLog("MenuBarManager: Detected profile: \(detectedProfile)")
            print("MenuBarManager: Detected profile: \(detectedProfile) (print)")
            
            NSLog("MenuBarManager: About to call applyProfile")
            print("MenuBarManager: About to call applyProfile (print)")
            
            profileManager.applyProfile(detectedProfile)
            
            NSLog("MenuBarManager: applyProfile completed")
            print("MenuBarManager: applyProfile completed (print)")
            
            showNotification(title: "Profile Applied", message: "Applied profile: \(detectedProfile)")
        } else {
            NSLog("MenuBarManager: No profile detected")
            print("MenuBarManager: No profile detected (print)")
            showNotification(title: "Auto Apply Failed", message: "No matching profile found for current setup.")
        }
    }

    @objc func applyProfile(_ sender: NSMenuItem) {
        if let profileName = sender.representedObject as? String {
            profileManager.applyProfile(profileName)
            showNotification(title: "Profile Applied", message: "Applied profile: \(profileName)")
        }
    }
    
    @objc func showAbout() {
        let buildDate = getCurrentBuildDate()
        let alert = NSAlert()
        alert.messageText = "Mac App Positioner"
        alert.informativeText = """
        Version: 1.0
        Build Date: \(buildDate)
        
        A native macOS application for intelligent window positioning across multiple monitors.
        
        Features:
        • Automatic profile detection and application
        • Multi-monitor workspace management
        • Native Cocoa coordinate system
        • Reliable builtin screen detection
        
        © 2025 Mac App Positioner
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func getCurrentBuildDate() -> String {
        // Try to get the executable creation date (more accurate than bundle)
        if let executablePath = Bundle.main.executablePath,
           let attributes = try? FileManager.default.attributesOfItem(atPath: executablePath),
           let creationDate = attributes[.creationDate] as? Date {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            formatter.timeZone = TimeZone.current
            return formatter.string(from: creationDate)
        }
        
        // Fallback to current timestamp (this will be the build time since it's embedded at compile time)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone.current
        return formatter.string(from: Date())
    }
    
    private func showNotification(title: String, message: String) {
        guard Bundle.main.bundleIdentifier != nil else {
            NSLog("\(title): \(message)")
            return
        }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                NSLog("Failed to deliver notification: \(error.localizedDescription)")
            }
        }
    }
}
