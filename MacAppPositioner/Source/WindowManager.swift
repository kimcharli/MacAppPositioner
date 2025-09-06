import AppKit

/**
 * WindowManager handles window manipulation using macOS Accessibility APIs.
 * 
 * This class provides methods to get and set window positions and sizes for running applications.
 * It uses the AXUIElement API which requires accessibility permissions to function properly.
 * 
 * Key Requirements:
 * - Accessibility permissions must be granted in System Preferences
 * - Target applications must be running and have visible windows
 * - Applications must not be in full-screen mode for positioning to work
 */
class WindowManager {

    /**
     * Retrieves the current frame (position and size) of an application's main window.
     *
     * This method uses the Accessibility API to query window attributes from a running application.
     * The position returned is in the system's default coordinate system (top-left origin).
     *
     * @param pid: Process ID of the target application
     * @return: Tuple containing (position: CGPoint, size: CGSize) if successful, nil if failed
     *
     * Failure reasons:
     * - Application not running or no main window
     * - Accessibility permissions not granted
     * - Application window is minimized or hidden
     * - Application doesn't support Accessibility API properly
     */
    func getWindowFrame(pid: pid_t) -> (position: CGPoint, size: CGSize)? {
        // Create Accessibility element reference for the application
        let app = AXUIElementCreateApplication(pid)
        var window: AnyObject?
        
        // Get reference to the application's main window
        let result = AXUIElementCopyAttributeValue(app, kAXMainWindowAttribute as CFString, &window)

        if result == .success, let window = window {
            var positionRef: AnyObject?
            var sizeRef: AnyObject?
            
            // Query window position and size attributes
            let positionResult = AXUIElementCopyAttributeValue(window as! AXUIElement, kAXPositionAttribute as CFString, &positionRef)
            let sizeResult = AXUIElementCopyAttributeValue(window as! AXUIElement, kAXSizeAttribute as CFString, &sizeRef)

            if positionResult == .success && sizeResult == .success,
               let positionRef = positionRef, let sizeRef = sizeRef {
                
                var position = CGPoint.zero
                var size = CGSize.zero
                
                // Extract CGPoint and CGSize from AXValue objects
                let positionSuccess = AXValueGetValue(positionRef as! AXValue, AXValueType.cgPoint, &position)
                let sizeSuccess = AXValueGetValue(sizeRef as! AXValue, AXValueType.cgSize, &size)
                
                if positionSuccess && sizeSuccess {
                    return (position, size)
                }
            }
        }
        
        return nil
    }

    /**
     * Sets the position of an application's main window.
     *
     * This method uses the Accessibility API to move a window to the specified position.
     * The position should be in screen coordinates with top-left origin.
     *
     * @param pid: Process ID of the target application
     * @param position: New position for the window (top-left corner)
     * @return: Boolean indicating success or failure
     *
     * Common failure reasons:
     * - Accessibility permissions not granted
     * - Application not running or no main window
     * - Application in full-screen mode
     * - Window is minimized or hidden
     * - Application actively resisting positioning (some apps like Chrome)
     * - Invalid coordinates (off-screen or negative values)
     */
    func setWindowPosition(pid: pid_t, position: CGPoint) -> Bool {
        // Create Accessibility element reference for the application
        let app = AXUIElementCreateApplication(pid)
        var window: AnyObject?
        
        // Get reference to the application's main window
        let result = AXUIElementCopyAttributeValue(app, kAXMainWindowAttribute as CFString, &window)

        if result == .success, let window = window {
            var positionValue = position
            
            // Create AXValue from CGPoint for the API call
            if let positionRef = AXValueCreate(AXValueType.cgPoint, &positionValue) {
                // Attempt to set the window position
                let error = AXUIElementSetAttributeValue(window as! AXUIElement, kAXPositionAttribute as CFString, positionRef)
                
                if error != .success {
                    print("Error setting window position: \(error.rawValue) - \(accessibilityErrorDescription(error))")
                    return false
                }
                return true
            }
        } else {
            print("Failed to get main window for PID \(pid) - \(accessibilityErrorDescription(result))")
        }
        
        return false
    }
    
    /**
     * Sets both position and size of an application's main window.
     * Convenience method for complete window frame manipulation.
     *
     * @param pid: Process ID of the target application
     * @param frame: Complete window frame (position and size)
     * @return: Boolean indicating success or failure
     */
    func setWindowFrame(pid: pid_t, frame: CGRect) -> Bool {
        let positionSuccess = setWindowPosition(pid: pid, position: frame.origin)
        
        if positionSuccess {
            return setWindowSize(pid: pid, size: frame.size)
        }
        
        return false
    }
    
    /**
     * Sets the size of an application's main window.
     *
     * @param pid: Process ID of the target application  
     * @param size: New size for the window
     * @return: Boolean indicating success or failure
     */
    func setWindowSize(pid: pid_t, size: CGSize) -> Bool {
        let app = AXUIElementCreateApplication(pid)
        var window: AnyObject?
        
        let result = AXUIElementCopyAttributeValue(app, kAXMainWindowAttribute as CFString, &window)

        if result == .success, let window = window {
            var sizeValue = size
            
            if let sizeRef = AXValueCreate(AXValueType.cgSize, &sizeValue) {
                let error = AXUIElementSetAttributeValue(window as! AXUIElement, kAXSizeAttribute as CFString, sizeRef)
                
                if error != .success {
                    print("Error setting window size: \(error.rawValue) - \(accessibilityErrorDescription(error))")
                    return false
                }
                return true
            }
        }
        
        return false
    }
    
    /**
     * Checks if an application is currently running and has a main window.
     *
     * @param pid: Process ID to check
     * @return: Boolean indicating if application has accessible main window
     */
    func hasMainWindow(pid: pid_t) -> Bool {
        let app = AXUIElementCreateApplication(pid)
        var window: AnyObject?
        let result = AXUIElementCopyAttributeValue(app, kAXMainWindowAttribute as CFString, &window)
        return result == .success && window != nil
    }
    
    // MARK: - Helper Methods
    
    /**
     * Provides human-readable descriptions for Accessibility API error codes.
     *
     * @param error: AXError code from Accessibility API
     * @return: String description of the error
     */
    private func accessibilityErrorDescription(_ error: AXError) -> String {
        switch error {
        case .success:
            return "Success"
        case .failure:
            return "Generic failure"
        case .illegalArgument:
            return "Illegal argument"
        case .invalidUIElement:
            return "Invalid UI element"
        case .invalidUIElementObserver:
            return "Invalid UI element observer"
        case .cannotComplete:
            return "Cannot complete operation"
        case .attributeUnsupported:
            return "Attribute unsupported"
        case .actionUnsupported:
            return "Action unsupported"
        case .notificationUnsupported:
            return "Notification unsupported"
        case .notImplemented:
            return "Not implemented"
        case .notificationAlreadyRegistered:
            return "Notification already registered"
        case .notificationNotRegistered:
            return "Notification not registered"
        case .apiDisabled:
            return "Accessibility API disabled"
        case .noValue:
            return "No value"
        case .parameterizedAttributeUnsupported:
            return "Parameterized attribute unsupported"
        case .notEnoughPrecision:
            return "Not enough precision"
        @unknown default:
            return "Unknown error (\(error.rawValue))"
        }
    }
}
