import SwiftUI
import AppKit

// A deliberately minimal SwiftUI target used to test the AppMirror
// forwarding path against a native app we fully control.
//
// The question this answers: are synthetic CGEvents posted via
// CGEvent.postToPid honored by a normal AppKit/SwiftUI responder chain?
// ChatGPT's composer lives inside a WKWebView (web-area), which is the prime
// suspect for swallowing synthetic input. If "hi" lands here but not in
// ChatGPT, the problem is web-content hit-testing, not our forwarding.
//
// State is surfaced two ways so Computer Use can verify it without any log
// capture (which proved flaky):
//   1. The TextField content itself (did the keystrokes land?).
//   2. The window title, which mirrors counters + field text.

/// Differential-probe tokens. The whole experiment hinges on these two strings
/// being different and living in mutually exclusive channels:
///   - pixelToken is DRAWN (Core Graphics) but never exposed to accessibility.
///   - axToken is exposed as an AX value but NEVER drawn.
/// Ask Codex "what is the secret code?" — the token it reports reveals which
/// channel its Computer Use actually relies on. (get_app_state hands it BOTH a
/// screenshot and the AX tree, so this measures preference, not mere access.)
enum Probe {
    static let untitledWindow = ProcessInfo.processInfo.environment["PROBE_UNTITLED"] == "1"
    static let pixelToken = "PXL-KILO-42"
    static let axToken = "AXS-LIMA-97"
    /// Displayed name for this app's header/title/logs. Overridable via
    /// PROBE_APP_NAME so a copy running from a neutral temp bundle can present
    /// an innocuous identity — otherwise "Mirror Target" would be a filesystem
    /// breadcrumb leading Codex back to the source dir where both tokens sit in
    /// plaintext, defeating the point of the differential probe.
    static let appName = ProcessInfo.processInfo.environment["PROBE_APP_NAME"]
        ?? "Mirror Target"
}

final class Model: ObservableObject {
    @Published var text: String = ""
    @Published var clicks: Int = 0
    @Published var keys: Int = 0
    /// Count of how many times the AX-only secret value has been read. Bumps on
    /// every accessibility query of the probe's value, so a client that walks
    /// the AX tree (rather than only screenshotting) is visible as a rising
    /// number even before it reports which token it saw.
    @Published var axReads: Int = 0
    /// Rolling log of every observed event, newest last. Shown on-screen so it
    /// can be read via a screenshot / Computer Use get_app_state without relying
    /// on stderr or unified-log capture (both proved flaky when forwarding).
    @Published var events: [String] = []

    private let maxEvents = 12
    func log(_ line: String) {
        NSLog("\(Probe.appName) EVENT \(line)")
        events.append(line)
        if events.count > maxEvents { events.removeFirst(events.count - maxEvents) }
    }
}

/// A text field subclass that counts the mouseDown / keyDown events it actually
/// receives, so we can distinguish "event arrived but text engine ignored it"
/// from "event never arrived at all".
final class CountingTextField: NSTextField {
    var onClick: (() -> Void)?
    var onKey: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        onClick?()
        super.mouseDown(with: event)
    }

    override func keyDown(with event: NSEvent) {
        onKey?()
        super.keyDown(with: event)
    }
}

struct CountingField: NSViewRepresentable {
    @ObservedObject var model: Model

    func makeCoordinator() -> Coordinator { Coordinator(model: model) }

    func makeNSView(context: Context) -> CountingTextField {
        let field = CountingTextField()
        field.placeholderString = "Type here (target composer)"
        field.font = .systemFont(ofSize: 20)
        field.bezelStyle = .roundedBezel
        field.delegate = context.coordinator
        field.onClick = { [weak model] in
            model?.clicks += 1
            model?.log("field.mouseDown")
        }
        field.onKey = { [weak model] in model?.keys += 1 }
        return field
    }

    func updateNSView(_ nsView: CountingTextField, context: Context) {
        if nsView.stringValue != model.text { nsView.stringValue = model.text }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        let model: Model
        init(model: Model) { self.model = model }
        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            model.text = field.stringValue
        }
    }
}

/// PIXEL-ONLY probe. Draws `Probe.pixelToken` with Core Graphics but hides
/// itself from accessibility (`accessibilityElement = false` and no exposed
/// value), so the token exists in screenshots yet never appears in the AX tree.
final class PixelTokenView: NSView {
    override var isFlipped: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        setAccessibilityElement(false)
        // Make sure no child/self value leaks the token to the AX tree.
        setAccessibilityRole(.unknown)
        setAccessibilityLabel(nil)
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor(white: 0.95, alpha: 1).setFill()
        bounds.fill()
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 20, weight: .bold),
            .foregroundColor: NSColor.black,
        ]
        let s = Probe.pixelToken as NSString
        let size = s.size(withAttributes: attrs)
        s.draw(
            at: NSPoint(x: (bounds.width - size.width) / 2,
                        y: (bounds.height - size.height) / 2),
            withAttributes: attrs
        )
    }
}

struct PixelToken: NSViewRepresentable {
    func makeNSView(context: Context) -> PixelTokenView { PixelTokenView() }
    func updateNSView(_ nsView: PixelTokenView, context: Context) {}
}

/// AX-ONLY probe. Exposes `Probe.axToken` as its accessibility value but draws
/// nothing readable (blank swatch), so the token appears in the AX tree yet
/// never in a screenshot. Each read of the value bumps `model.axReads`, making
/// tree-walking visible as a rising counter.
final class AXTokenView: NSView {
    weak var model: Model?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        setAccessibilityElement(true)
        setAccessibilityRole(.staticText)
        setAccessibilityLabel("secret code")
    }

    // Every accessibility read of the value counts as one tree query.
    override func accessibilityValue() -> Any? {
        DispatchQueue.main.async { [weak self] in
            guard let m = self?.model else { return }
            m.axReads += 1
            // NB: do NOT echo the token here — this log is drawn on-screen, so
            // printing axToken would leak it into the pixel channel and break
            // the differential. Record only that a read happened.
            // The visible read counter covers AX activity; keep input logs readable.
        }
        return Probe.axToken
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor(white: 0.95, alpha: 1).setFill()
        bounds.fill()
        // Deliberately draw NO token text — a client relying on pixels sees
        // only a blank grey swatch here.
        let hint = "(secret via AX only)" as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.tertiaryLabelColor,
        ]
        hint.draw(at: NSPoint(x: 6, y: 6), withAttributes: attrs)
    }
}

struct AXToken: NSViewRepresentable {
    @ObservedObject var model: Model
    func makeNSView(context: Context) -> AXTokenView {
        let v = AXTokenView()
        v.model = model
        return v
    }
    func updateNSView(_ nsView: AXTokenView, context: Context) { nsView.model = model }
}

struct ContentView: View {
    @ObservedObject var model: Model
    var body: some View {
        VStack(spacing: 12) {
            Text(Probe.appName)
                .font(.title).bold()
            // Differential probe: the two secret-code channels disagree on
            // purpose. Whichever token Codex reports reveals its channel.
            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("PIXEL").font(.caption2).foregroundStyle(.secondary)
                    PixelToken().frame(width: 170, height: 40)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(.quaternary))
                }
                VStack(spacing: 2) {
                    Text("AX").font(.caption2).foregroundStyle(.secondary)
                    AXToken(model: model).frame(width: 170, height: 40)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(.quaternary))
                }
            }
            CountingField(model: model)
                .frame(width: 360)
            HStack(spacing: 24) {
                Label("\(model.clicks)", systemImage: "cursorarrow.click")
                Label("\(model.keys)", systemImage: "keyboard")
                Label("\(model.axReads)", systemImage: "eye")
            }
            .font(.title3.monospacedDigit())
            Text(model.text.isEmpty ? "—" : model.text)
                .font(.headline)
                .foregroundStyle(.secondary)
            // Live event log — every observed mouse/key event, newest last.
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 1) {
                        ForEach(Array(model.events.enumerated()), id: \.offset) { idx, line in
                            Text(line)
                                .font(.system(size: 10, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(idx)
                        }
                    }
                    .padding(6)
                }
                .frame(width: 400, height: 130)
                .background(Color.black.opacity(0.05))
                .cornerRadius(6)
                .onChange(of: model.events.count) { _ in
                    proxy.scrollTo(model.events.count - 1, anchor: .bottom)
                }
            }
        }
        .padding(24)
        .frame(width: 460, height: 520)
    }
}

final class DraftView: NSTextView {
    var report: ((String) -> Void)?
    override func didChangeText() {
        super.didChangeText()
        report?("Draft: " + string.replacingOccurrences(of: "\n", with: "\\n"))
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = Model()
    private var window: NSWindow!
    private var timer: Timer?
    private var monitor: Any?
    private lazy var menus = FixtureMenus(model: model)

    func applicationDidFinishLaunching(_ notification: Notification) {
        menus.install()
        let view = ContentView(model: model)
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 880, height: 720),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered, defer: false
        )
        window.title = Probe.untitledWindow ? "" : Probe.appName
        model.log("Window title: \(Probe.untitledWindow ? "empty" : Probe.appName)")
        let content = NSView(frame: NSRect(x: 0, y: 0, width: 880, height: 720))
        let original = NSHostingView(rootView: view)
        original.frame = NSRect(x: 0, y: 0, width: 460, height: 600)
        content.addSubview(original)
        let panel = FixturePanel(frame: NSRect(x: 470, y: 0, width: 400, height: 600))
        panel.report = { [weak self] in self?.model.log($0) }
        content.addSubview(panel)
        let draft = DraftView(frame: NSRect(x: 20, y: 610, width: 840, height: 90))
        draft.isRichText = false
        draft.font = .systemFont(ofSize: 16)
        draft.setAccessibilityLabel("Multiline draft")
        draft.report = { [weak self] in self?.model.log($0) }
        content.addSubview(draft)
        window.contentView = content
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // App-wide monitor: log EVERY mouse/key event this process receives,
        // regardless of which view (if any) ends up handling it. This is the
        // ground truth for "did the forwarded CGEvent actually arrive?" — a
        // click that lands outside the field, or a keystroke with an unexpected
        // keyCode, still shows up here even though the field counters wouldn't.
        let mask: NSEvent.EventTypeMask = [
            .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp, .otherMouseDown, .otherMouseUp,
            .leftMouseDragged, .rightMouseDragged, .otherMouseDragged,
            .keyDown, .keyUp, .flagsChanged,
        ]
        monitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.record(event)
            return event  // don't swallow — let normal handling proceed
        }

        // Surface live state in the title so Computer Use's get_app_state reads
        // it directly — same trick the mirror uses.
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self else { return }
            let t = self.model.text.isEmpty ? "∅" : self.model.text
            self.window.title = Probe.untitledWindow ? "" : "\(Probe.appName) [c:\(self.model.clicks) k:\(self.model.keys) ax:\(self.model.axReads) text:\(t)]"
        }
    }

    /// Formats and records one observed event into the model's on-screen log.
    private func record(_ event: NSEvent) {
        let p = event.locationInWindow
        let pos = "(\(Int(p.x)),\(Int(p.y)))"
        let modifiers = "0b" + String(event.modifierFlags.rawValue, radix: 2)
        let line: String
        switch event.type {
        case .keyDown, .keyUp:
            let chars = event.charactersIgnoringModifiers ?? "?"
            line = "\(event.type == .keyDown ? "keyDown" : "keyUp") code=\(event.keyCode) chars=\"\(chars)\" repeat=\(event.isARepeat) mods=\(modifiers)"
        case .flagsChanged:
            line = "flagsChanged mods=\(modifiers)"
        default:
            line = "\(mouseName(event.type)) \(pos) clicks=\(event.clickCount) mods=\(modifiers)"
        }
        model.log(line)
    }

    private func mouseName(_ t: NSEvent.EventType) -> String {
        switch t {
        case .leftMouseDown: return "leftMouseDown"
        case .leftMouseUp: return "leftMouseUp"
        case .rightMouseDown: return "rightMouseDown"
        case .otherMouseDown: return "otherMouseDown"
        default: return "mouse(\(t.rawValue))"
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
