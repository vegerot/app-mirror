import AppKit

// MARK: - Locate the target app

/// Finds the target app's process id and the bounds of its frontmost window.
/// Defaults to ChatGPT, but MIRROR_TARGET_BUNDLE_ID can point it at any app
/// (e.g. the native MirrorTarget test app) to isolate whether forwarding
/// failures are ChatGPT/WebView-specific or general to CGEvent.postToPid.
final class TargetConnection {
    static let shared = TargetConnection()
    let bundleID = ProcessInfo.processInfo.environment["MIRROR_TARGET_BUNDLE_ID"]
        ?? "com.openai.codex"

    var displayName: String {
        NSWorkspace.shared.runningApplications
            .first { $0.bundleIdentifier == bundleID }?.localizedName ?? bundleID
    }

    private(set) var process: NSRunningApplication?
    private(set) var window: (id: CGWindowID, bounds: CGRect)?
    private(set) var accessibilityWindow: AXUIElement?
    private var generation = 0

    func refresh() {
        let next = NSWorkspace.shared.runningApplications.first { $0.bundleIdentifier == bundleID }
        if next?.processIdentifier != process?.processIdentifier {
            generation += 1
            if let next {
                // Some web-backed apps publish their full tree only when an AX
                // client requests it. Unsupported attributes are harmless errors.
                let application = AXUIElementCreateApplication(next.processIdentifier)
                for attribute in ["AXManualAccessibility", "AXEnhancedUserInterface"] {
                    let result = AXUIElementSetAttributeValue(application, attribute as CFString, kCFBooleanTrue)
                    NSLog("AX accessibility request \(attribute): \(result.rawValue)")
                }
            }
        }
        process = next
        accessibilityWindow = next.flatMap { AXBridge.mainWindow(pid: $0.processIdentifier) }
        let mainBounds: CGRect? = accessibilityWindow.flatMap {
            guard let position = AXBridge.point($0, kAXPositionAttribute as String),
                  let size = AXBridge.size($0, kAXSizeAttribute as String) else { return nil }
            return CGRect(origin: position, size: size)
        }
        window = nil
        if let next, let mainBounds,
           let infos = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] {
            window = Self.captureWindow(in: infos, pid: next.processIdentifier, mainBounds: mainBounds)
        }
    }

    func pid() -> pid_t? { process?.isTerminated == false ? process?.processIdentifier : nil }
    func mainWindow(pid: pid_t) -> (id: CGWindowID, bounds: CGRect)? { window }

    func enqueue(after delay: Double, _ action: @escaping () -> Void) {
        let expected = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.generation == expected, self.pid() != nil else { return }
            action()
        }
    }

    /// Find the capture ID for our one AX main window. Claude has exposed a
    /// small layer-zero utility surface ahead of it; capturing that surface
    /// would combine unrelated pixels with the main window's controls.
    /// No ranking, title requirement, or fallback to another window.
    static func captureWindow(in infos: [[String: Any]], pid: pid_t, mainBounds: CGRect) -> (id: CGWindowID, bounds: CGRect)? {
        for info in infos {
            guard let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t, ownerPID == pid,
                  let layer = info[kCGWindowLayer as String] as? Int, layer == 0,
                  let id = info[kCGWindowNumber as String] as? CGWindowID,
                  let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
                  let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary),
                  bounds.equalTo(mainBounds)
            else { continue }
            return (id, bounds)
        }
        return nil
    }
}
