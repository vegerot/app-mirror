import AppKit

enum InputForwarder {
    /// A single pointer press works for the tested native and web window controls.
    /// Native menu items use AXPress in MenuBridge. Never retry a no-op press.
    static func press(_ element: AXUIElement) -> Bool { click(element) }

    static func activateMainWindow(pid: pid_t, targetBounds: CGRect) {
        NSRunningApplication(processIdentifier: pid)?.activate()
        let application = AXUIElementCreateApplication(pid)
        _ = AXUIElementSetAttributeValue(
            application,
            kAXFrontmostAttribute as CFString,
            kCFBooleanTrue
        )
        if let target = TargetConnection.shared.accessibilityWindow {
            _ = AXUIElementPerformAction(target, kAXRaiseAction as CFString)
        }
    }

    static func click(_ element: AXUIElement) -> Bool {
        guard let position = AXBridge.point(element, kAXPositionAttribute as String),
              let elementSize = AXBridge.size(element, kAXSizeAttribute as String)
        else { return false }
        let center = CGPoint(
            x: position.x + elementSize.width / 2,
            y: position.y + elementSize.height / 2
        )
        let sequence: [(CGEventType, useconds_t)] = [
            (.mouseMoved, 50_000),
            (.leftMouseDown, 80_000),
            (.leftMouseUp, 0),
        ]
        for (type, delay) in sequence {
            guard let event = CGEvent(
                mouseEventSource: nil,
                mouseType: type,
                mouseCursorPosition: center,
                mouseButton: .left
            ) else { return false }
            event.post(tap: .cghidEventTap)
            usleep(delay)
        }
        return true
    }

    static func postPointer(_ sample: PointerSample) {
        guard let event = sample.cgEvent() else { return }
        event.post(tap: .cghidEventTap)
    }

    static func postMouse(_ type: CGEventType, at point: CGPoint, clickCount: Int64) {
        postPointer(PointerSample(type: type, point: point, button: .left, clickCount: clickCount, flags: []))
    }

    static func forwardKey(_ sample: KeyboardSample, targetPID: pid_t) {
        sample.event.postToPid(targetPID)
    }

    static func forwardText(_ text: String, targetPID: pid_t) {
        let source = CGEventSource(stateID: .hidSystemState)
        for scalar in text.unicodeScalars {
            var utf16 = Array(String(scalar).utf16)
            for down in [true, false] {
                guard let event = CGEvent(
                    keyboardEventSource: source,
                    virtualKey: 0,
                    keyDown: down
                ) else { continue }
                event.keyboardSetUnicodeString(
                    stringLength: utf16.count,
                    unicodeString: &utf16
                )
                event.postToPid(targetPID)
            }
            usleep(20_000)
        }
    }

}
