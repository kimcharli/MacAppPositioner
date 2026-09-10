import Foundation
import CoreGraphics

/**
 * Layout Engine
 *
 * ARCHITECTURE PRINCIPLE:
 * - This is the **single owner of target window geometry**. Both plan generation
 *   and layout application call `resolve(...)`, so the two cannot drift apart.
 * - Deliberately pure: no AppKit, no Accessibility API, no singletons, no I/O.
 *   Everything it needs arrives as a parameter, which makes it directly testable
 *   against fixtures rather than against the operator's physical displays.
 *
 * All coordinates are in the internal top-left-origin system (Y down), matching
 * the Accessibility API. See DEVELOPMENT.md Section 6.
 */

/// A monitor reduced to just the geometry the layout rules need.
/// Decoupled from `NSScreen` and `CocoaMonitorInfo` on purpose.
struct MonitorGeometry: Equatable {
    /// Full monitor bounds, internal top-left origin.
    let frame: CGRect
    /// Bounds excluding menu bar and Dock, internal top-left origin.
    let visibleFrame: CGRect

    init(frame: CGRect, visibleFrame: CGRect) {
        self.frame = frame
        self.visibleFrame = visibleFrame
    }
}

enum LayoutEngine {

    /// Why the engine reached its conclusion. Carried through to the CLI and GUI
    /// so neither front-end has to re-derive the rationale.
    enum Decision: Equatable {
        /// The window should be moved to the resolved target frame.
        case move
        /// Layout explicitly requests `keep`; the window is never touched.
        case keepConfigured
        /// The window is already at the target, within `positioningTolerance`.
        case keepAlreadyPlaced
        /// A `center` window whose centre already lies on the target monitor.
        case keepOnTargetScreen
        /// No running process with a moveable window for this bundle ID.
        case appUnavailable

        /// How this decision is reported in an execution plan.
        var actionType: ActionType {
            switch self {
            case .move:               return .move
            case .appUnavailable:     return .unavailable
            case .keepConfigured,
                 .keepAlreadyPlaced,
                 .keepOnTargetScreen: return .keep
            }
        }

        var explanation: String {
            switch self {
            case .move:               return "will be repositioned"
            case .keepConfigured:     return "layout says 'keep' — not repositioned"
            case .keepAlreadyPlaced:  return "already at the target position"
            case .keepOnTargetScreen: return "already on the target screen"
            case .appUnavailable:     return "not running, or no moveable window"
            }
        }
    }

    /// The engine's verdict for one application.
    ///
    /// `targetFrame` is `nil` whenever there is nothing to do. That is the whole
    /// point of this type: the previous implementation fabricated a top-left
    /// target for `keep` and non-running apps, and the `plan` command printed it
    /// as though the window were about to move there.
    struct Placement: Equatable {
        let targetFrame: CGRect?
        let decision: Decision

        var shouldMove: Bool { decision == .move }
    }

    // MARK: - Resolution

    /// Resolves the target geometry for a single application.
    ///
    /// - Parameters:
    ///   - position: Configured layout position for this app.
    ///   - sizing: Per-entry sizing hint from the layout (`"keep"` preserves the
    ///     current window size).
    ///   - appSizingOverride: Sizing hint from the `applications` config section.
    ///   - currentFrame: The window's present frame, or `nil` when the app is not
    ///     running or exposes no moveable window.
    ///   - monitor: Geometry of the monitor this app is assigned to.
    ///   - tolerance: Positional slack, in points, below which a window counts as
    ///     already placed.
    static func resolve(position: WindowPosition,
                        sizing: String?,
                        appSizingOverride: String?,
                        currentFrame: CGRect?,
                        monitor: MonitorGeometry,
                        tolerance: CGFloat = AppConstants.positioningTolerance) -> Placement {

        // Explicit opt-out always wins, running or not.
        guard position != .keep else {
            return Placement(targetFrame: nil, decision: .keepConfigured)
        }

        let size = resolveWindowSize(currentSize: currentFrame?.size,
                                     sizing: sizing,
                                     appSizingOverride: appSizingOverride)

        let target = CGRect(origin: origin(for: position, size: size, in: monitor.visibleFrame),
                            size: size)

        // An app we cannot address still reports its would-be target, so the plan
        // stays informative, but it is labelled UNAVAILABLE rather than MOVE.
        guard let currentFrame = currentFrame else {
            return Placement(targetFrame: target, decision: .appUnavailable)
        }

        // A centred window that already lives on the target monitor is left alone,
        // so re-applying a profile does not nudge windows the user has arranged.
        if position == .center {
            let centre = CGPoint(x: currentFrame.midX, y: currentFrame.midY)
            if monitor.frame.contains(centre) {
                return Placement(targetFrame: nil, decision: .keepOnTargetScreen)
            }
        }

        if abs(currentFrame.origin.x - target.origin.x) < tolerance,
           abs(currentFrame.origin.y - target.origin.y) < tolerance {
            return Placement(targetFrame: target, decision: .keepAlreadyPlaced)
        }

        return Placement(targetFrame: target, decision: .move)
    }

    // MARK: - Geometry

    /// Top-left corner for a window of `size` placed at `position` within `visibleFrame`.
    ///
    /// Note the `.center` case: the previous `calculateQuadrantPosition` folded
    /// `.center` and `.keep` into the `.topLeft` branch, which is precisely how
    /// `plan` and `apply` came to disagree.
    static func origin(for position: WindowPosition,
                       size: CGSize,
                       in visibleFrame: CGRect) -> CGPoint {
        switch position {
        case .topLeft:
            return CGPoint(x: visibleFrame.minX, y: visibleFrame.minY)
        case .topRight:
            return CGPoint(x: visibleFrame.maxX - size.width, y: visibleFrame.minY)
        case .bottomLeft:
            return CGPoint(x: visibleFrame.minX, y: visibleFrame.maxY - size.height)
        case .bottomRight:
            return CGPoint(x: visibleFrame.maxX - size.width, y: visibleFrame.maxY - size.height)
        case .center:
            return CGPoint(x: visibleFrame.midX - size.width / 2,
                           y: visibleFrame.midY - size.height / 2)
        case .keep:
            // Unreachable: `resolve` returns before this point for `.keep`.
            // Kept explicit so the switch stays exhaustive without a `default`,
            // which would silently swallow any future WindowPosition case.
            return currentOriginPlaceholder(in: visibleFrame)
        }
    }

    private static func currentOriginPlaceholder(in visibleFrame: CGRect) -> CGPoint {
        CGPoint(x: visibleFrame.minX, y: visibleFrame.minY)
    }

    /// Window size to use: preserve the current size when either the layout entry
    /// or the per-application override asks to `keep` it, otherwise fall back to
    /// `AppConstants.defaultWindowSize`.
    static func resolveWindowSize(currentSize: CGSize?,
                                  sizing: String?,
                                  appSizingOverride: String?) -> CGSize {
        if sizing == "keep" || appSizingOverride == "keep", let currentSize = currentSize {
            return currentSize
        }
        return AppConstants.defaultWindowSize
    }
}
