import AppKit

struct PointerSample {
    let type: CGEventType
    let point: CGPoint
    let button: CGMouseButton
    let clickCount: Int64
    let flags: CGEventFlags

    init(type: CGEventType, point: CGPoint, button: CGMouseButton, clickCount: Int64, flags: CGEventFlags) {
        self.type = type; self.point = point; self.button = button
        self.clickCount = clickCount; self.flags = flags
    }

    init?(event: NSEvent, point: CGPoint) {
        switch event.type {
        case .leftMouseDown: type = .leftMouseDown
        case .leftMouseUp: type = .leftMouseUp
        case .leftMouseDragged: type = .leftMouseDragged
        case .rightMouseDown: type = .rightMouseDown
        case .rightMouseUp: type = .rightMouseUp
        case .rightMouseDragged: type = .rightMouseDragged
        case .otherMouseDown: type = .otherMouseDown
        case .otherMouseUp: type = .otherMouseUp
        case .otherMouseDragged: type = .otherMouseDragged
        case .mouseMoved: type = .mouseMoved
        default: return nil
        }
        self.point = point
        button = CGMouseButton(rawValue: UInt32(event.buttonNumber)) ?? .left
        clickCount = Int64(event.clickCount)
        flags = CGEventFlags(rawValue: UInt64(event.modifierFlags.rawValue))
    }

    func cgEvent() -> CGEvent? {
        guard let event = CGEvent(mouseEventSource: nil, mouseType: type,
                                  mouseCursorPosition: point, mouseButton: button) else { return nil }
        event.flags = flags
        event.setIntegerValueField(.mouseEventClickState, value: clickCount)
        return event
    }
}
