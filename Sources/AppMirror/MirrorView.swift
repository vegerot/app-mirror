import AppKit

// MARK: - Input forwarding view

/// Displays captured frames of ChatGPT and forwards clicks/keystrokes to its process.
final class MirrorView: NSImageView {
    var targetPID: pid_t = 0
    var targetBounds: CGRect = .zero
    private var mouseGesture: [PointerSample] = []
    var hasPointerGesture: Bool { !mouseGesture.isEmpty }

    // Observable event counters, surfaced in the window title so forwarding can
    // be verified without relying on stderr/unified-log capture (which proved
    // flaky when the app was launched detached).
    private(set) var mouseDowns = 0
    private(set) var keyDowns = 0
    private(set) var scrolls = 0
    private(set) var lastEvent = "none"

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    /// Maps a view-local point (AppKit, bottom-left origin) to ChatGPT's global
    /// screen coordinate (top-left origin) using the current window bounds.
    private func globalPoint(from event: NSEvent) -> CGPoint {
        let local = convert(event.locationInWindow, from: nil)
        return CoordinateMap(target: targetBounds, mirror: bounds.size).remotePoint(local)

    }

    func pointer(_ event: NSEvent) {
        guard targetPID != 0, let sample = PointerSample(event: event, point: globalPoint(from: event)) else { return }
        switch event.type {
        case .leftMouseDown, .rightMouseDown, .otherMouseDown:
            window?.makeFirstResponder(self)
            mouseDowns += 1
            mouseGesture = [sample]
        case .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
            if !mouseGesture.isEmpty { mouseGesture.append(sample) }
        case .leftMouseUp, .rightMouseUp, .otherMouseUp:
            guard !mouseGesture.isEmpty else { return }
            mouseGesture.append(sample)
            let samples = mouseGesture
            mouseGesture.removeAll()
            lastEvent = "pointer#\(mouseDowns):\(sample.button.rawValue)"
            InputForwarder.activateMainWindow(pid: targetPID, targetBounds: targetBounds)
            TargetConnection.shared.enqueue(after: 0.1) {
                InputForwarder.postMouse(.mouseMoved, at: samples[0].point, clickCount: 0)
                samples.forEach { InputForwarder.postPointer($0) }
                NotificationCenter.default.post(name: .axProxyDidAct, object: nil)
            }
        case .mouseMoved:
            InputForwarder.activateMainWindow(pid: targetPID, targetBounds: targetBounds)
            TargetConnection.shared.enqueue(after: 0.1) {
                InputForwarder.postPointer(sample)
                NotificationCenter.default.post(name: .axProxyDidAct, object: nil)
            }
        default: break
        }
    }

    override func mouseDown(with event: NSEvent) { pointer(event) }
    override func mouseDragged(with event: NSEvent) { pointer(event) }
    override func mouseUp(with event: NSEvent) { pointer(event) }
    override func rightMouseDown(with event: NSEvent) { pointer(event) }
    override func rightMouseUp(with event: NSEvent) { pointer(event) }
    override func otherMouseDown(with event: NSEvent) { pointer(event) }
    override func otherMouseUp(with event: NSEvent) { pointer(event) }

    private var textKeyUps: Set<UInt16> = []

    func resetInput() {
        mouseGesture.removeAll()
        textKeyUps.removeAll()
    }

    func keyboard(_ event: NSEvent) {
        guard targetPID != 0 else { return }
        if event.type == .keyUp, textKeyUps.remove(event.keyCode) != nil { return }
        if event.type == .keyDown {
            keyDowns += 1
            lastEvent = "key#\(keyDowns):\(event.keyCode)"
        }
        InputForwarder.activateMainWindow(pid: targetPID, targetBounds: targetBounds)
        if let text = KeyboardSample.unicodeText(for: event) {
            textKeyUps.insert(event.keyCode)
            InputForwarder.forwardText(text, targetPID: targetPID)
        } else if let sample = KeyboardSample(event: event) {
            // Keep physical down, repeat, flags, and up events in receipt order.
            if event.type == .keyDown { usleep(100_000) }
            InputForwarder.forwardKey(sample, targetPID: targetPID)
            if event.type == .keyDown, event.modifierFlags.contains(.command),
               event.charactersIgnoringModifiers?.lowercased() == "v" {
                // Allow the target to read a temporary pasteboard before the
                // caller restores it. This does not synthesize a key release.
                usleep(150_000)
            }
        }
        NotificationCenter.default.post(name: .axProxyDidAct, object: nil)
    }

    override func keyDown(with event: NSEvent) { keyboard(event) }
    override func keyUp(with event: NSEvent) { keyboard(event) }
    override func flagsChanged(with event: NSEvent) { keyboard(event) }

    override func scrollWheel(with event: NSEvent) {
        scrolls += 1
        lastEvent = "scroll#\(scrolls):\(Int(event.scrollingDeltaY))"
        NSLog("MIRROR scrollWheel dy=\(event.scrollingDeltaY) dx=\(event.scrollingDeltaX) pid=\(targetPID)")
        InputForwarder.activateMainWindow(pid: targetPID, targetBounds: targetBounds)
        let deltaY = Int32(event.scrollingDeltaY.rounded())
        let deltaX = Int32(event.scrollingDeltaX.rounded())
        let location = globalPoint(from: event)
        TargetConnection.shared.enqueue(after: 0.1) {
            guard let scroll = CGEvent(
                scrollWheelEvent2Source: nil,
                units: .pixel,
                wheelCount: 2,
                wheel1: deltaY,
                wheel2: deltaX,
                wheel3: 0
            ) else { return }
            scroll.location = location
            scroll.flags = CGEventFlags(rawValue: UInt64(event.modifierFlags.rawValue))
            scroll.post(tap: .cghidEventTap)
            NotificationCenter.default.post(name: .axProxyDidAct, object: nil)
        }
    }
}
