import AppKit

/// Small deterministic controls for the proxy's semantic and input audit.
final class FixturePanel: NSView {
    private let result = NSTextField(labelWithString: "Fixture ready")
    private var replacement: NSButton!
    private var version = 0
    var report: ((String) -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        setAccessibilityLabel("Control fixture")
        result.frame = NSRect(x: 10, y: 550, width: 370, height: 25)
        result.setAccessibilityIdentifier("fixture-result")
        addSubview(result)
        for (index, name) in ["Left group", "Right group"].enumerated() {
            let group = NSView(frame: NSRect(x: 10 + index * 185, y: 485, width: 175, height: 60))
            group.setAccessibilityElement(true)
            group.setAccessibilityRole(.group)
            group.setAccessibilityLabel(name)
            let button = NSButton(title: "Same label", target: self, action: #selector(duplicate(_:)))
            button.tag = index
            button.frame = NSRect(x: 0, y: 10, width: 165, height: 30)
            group.addSubview(button)
            addSubview(group)
        }
        let field = NSTextField(string: "Read only")
        field.isEditable = false
        field.setAccessibilityLabel("Read-only field")
        field.frame = NSRect(x: 10, y: 435, width: 175, height: 28)
        addSubview(field)
        let disabled = NSButton(title: "Disabled action", target: self, action: #selector(duplicate(_:)))
        disabled.isEnabled = false
        disabled.frame = NSRect(x: 195, y: 435, width: 175, height: 28)
        addSubview(disabled)
        let replace = NSButton(title: "Replace after delay", target: self, action: #selector(replaceLater))
        replace.frame = NSRect(x: 10, y: 390, width: 175, height: 30)
        addSubview(replace)
        installReplacement()
        let toggle = NSButton(checkboxWithTitle: "Fixture toggle", target: self, action: #selector(toggle(_:)))
        toggle.frame = NSRect(x: 10, y: 345, width: 170, height: 30)
        addSubview(toggle)
        for (index, name) in ["Left scroll", "Right scroll"].enumerated() {
            let scroll = AuditScrollView(frame: NSRect(x: 10 + index * 185, y: 140, width: 175, height: 180))
            scroll.name = name
            scroll.hasVerticalScroller = true
            scroll.setAccessibilityLabel(name)
            let document = NSView(frame: NSRect(x: 0, y: 0, width: 155, height: 900))
            for row in 0..<30 {
                let text = NSTextField(labelWithString: "\(name) row \(row)")
                text.frame = NSRect(x: 5, y: row * 30, width: 145, height: 25)
                document.addSubview(text)
            }
            scroll.documentView = document
            scroll.report = { [weak self] in self?.result.stringValue = $0 }
            addSubview(scroll)
        }
        let pad = EventPad(frame: NSRect(x: 10, y: 15, width: 360, height: 100))
        pad.report = { [weak self] in
            self?.result.stringValue = $0
            if $0 != "Hover" { self?.report?($0) }
        }
        addSubview(pad)
    }
    required init?(coder: NSCoder) { fatalError("not used") }
    @objc private func duplicate(_ sender: NSButton) { result.stringValue = "Clicked \(sender.tag == 0 ? "Left" : "Right") group" }
    @objc private func toggle(_ sender: NSButton) { result.stringValue = "Toggle \(sender.state.rawValue)" }
    @objc private func replaced() { result.stringValue = "Replacement version \(version)" }
    private func installReplacement() {
        replacement?.removeFromSuperview()
        replacement = NSButton(title: "Replacement", target: self, action: #selector(replaced))
        replacement.setAccessibilityIdentifier("replacement")
        replacement.frame = NSRect(x: 195, y: 390, width: 175, height: 30)
        addSubview(replacement)
    }
    @objc private func replaceLater() {
        result.stringValue = "Replacement pending"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self else { return }
            self.version += 1
            self.installReplacement()
            self.result.stringValue = "Replacement ready \(self.version)"
        }
    }
}

final class EventPad: NSView {
    var report: ((String) -> Void)?
    override var acceptsFirstResponder: Bool { true }
    override func viewDidMoveToWindow() {
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        setAccessibilityLabel("Pointer pad")
        window?.acceptsMouseMovedEvents = true
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseMoved, .activeAlways, .inVisibleRect], owner: self))
    }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.systemBlue.withAlphaComponent(0.15).setFill(); bounds.fill()
        ("Pointer pad: click, hover, drag, context menu" as NSString).draw(at: NSPoint(x: 8, y: 45), withAttributes: [.font: NSFont.systemFont(ofSize: 12)])
    }
    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        report?("Left clicks=\(event.clickCount) mods=0b\(String(event.modifierFlags.rawValue, radix: 2))")
    }
    override func mouseDragged(with event: NSEvent) { report?("Dragged \(Int(event.locationInWindow.x)),\(Int(event.locationInWindow.y))") }
    override func mouseUp(with event: NSEvent) { report?("Released \(Int(event.locationInWindow.x)),\(Int(event.locationInWindow.y))") }
    override func otherMouseDown(with event: NSEvent) { report?("Middle button=\(event.buttonNumber)") }
    override func mouseMoved(with event: NSEvent) { report?("Hover") }
    override func rightMouseDown(with event: NSEvent) {
        report?("Right click")
        let menu = NSMenu(title: "Pad context")
        let item = NSMenuItem(title: "Context action", action: #selector(contextAction), keyEquivalent: "")
        item.target = self; menu.addItem(item)
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }
    @objc private func contextAction() { report?("Context action selected") }
}

final class AuditScrollView: NSScrollView {
    var report: ((String) -> Void)?
    var name = ""
    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        report?("\(name) scroll y=\(Int(contentView.bounds.origin.y))")
    }
}
