import AppKit

/// Preserve the original event type, repeat bit, modifiers and Unicode payload.
/// In particular, key-down must never manufacture a key-up.
struct KeyboardSample {
    let event: CGEvent

    /// AppKit represents navigation/function keys with private-use characters.
    /// They must keep their physical key codes and releases, not become text.
    static func unicodeText(for event: NSEvent) -> String? {
        guard event.type == .keyDown,
              event.modifierFlags.intersection([.command, .control, .option]).isEmpty,
              let text = event.characters,
              !text.unicodeScalars.contains(where: { (0xF700...0xF8FF).contains($0.value) }),
              text.count > 1 || text.unicodeScalars.contains(where: { !$0.isASCII })
        else { return nil }
        return text
    }

    init?(event: NSEvent) {
        guard [.keyDown, .keyUp, .flagsChanged].contains(event.type),
              let original = event.cgEvent else { return nil }
        self.init(original)
    }
    init?(_ original: CGEvent) {
        guard [.keyDown, .keyUp, .flagsChanged].contains(original.type),
              let copy = original.copy() else { return nil }
        event = copy
    }
}
