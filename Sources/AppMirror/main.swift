import AppKit
import CoreGraphics

extension Notification.Name {
    static let axProxyDidAct = Notification.Name("AXProxyDidAct")
}

// MARK: - Permission diagnostics

/// Reports whether the two TCC permissions this app relies on are granted:
/// - Screen Recording: required by CGWindowListCreateImage to capture TargetConnection.shared.
/// - Accessibility: required by CGEvent.postToPid to forward clicks/keystrokes.
/// Logs each to stderr at launch so a denied grant is obvious instead of
/// silently producing a blank mirror or dropped input.
enum Permissions {
    /// Pure check — no prompts, no logging. Safe to call repeatedly (e.g. from
    /// the capture timer) so the window title can reflect live status.
    /// Accessibility trust is uncached on macOS, so this updates the moment the
    /// user toggles the grant.
    static func status() -> (screen: Bool, accessibility: Bool) {
        (CGPreflightScreenCaptureAccess(), AXIsProcessTrusted())
    }

    /// Short title-bar summary: "" when all granted, else " — missing: …".
    /// No logging or prompting, so it is cheap to call every capture tick.
    static func summary() -> String {
        let (screen, ax) = status()
        var missing: [String] = []
        if !screen { missing.append("Screen Recording") }
        if !ax { missing.append("Accessibility") }
        return missing.isEmpty ? "" : " — missing: \(missing.joined(separator: ", "))"
    }

    /// Logs current status once and, if `prompt` is set, surfaces the system
    /// grant dialogs for anything denied. Called at launch.
    @discardableResult
    static func report(prompt: Bool) -> String {
        let (screen, ax) = status()
        NSLog("PERMISSION Screen Recording: \(screen ? "GRANTED" : "DENIED")")
        NSLog("PERMISSION Accessibility:    \(ax ? "GRANTED" : "DENIED")")
        if !screen {
            NSLog("PERMISSION hint: capture will be blank until Screen Recording is enabled for AppMirror in System Settings > Privacy & Security.")
            if prompt { CGRequestScreenCaptureAccess() }
        }
        if !ax {
            NSLog("PERMISSION hint: click/keystroke forwarding will be dropped until Accessibility is enabled for AppMirror in System Settings > Privacy & Security.")
            if prompt {
                let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
                _ = AXIsProcessTrustedWithOptions(opts)
            }
        }
        return summary()
    }
}

// MARK: - App

final class AXOverlayView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        let hit = super.hitTest(point)
        return hit === self ? nil : hit
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private var mirror: MirrorView!
    private var windowID: CGWindowID = 0
    private var connectedPID: pid_t?
    private var timer: Timer?
    private var axOverlay: AXOverlayView!
    private var axViews: [Int: AXProxyElementView] = [:]
    private var axActionObserver: NSObjectProtocol?
    private var keyMonitor: Any?
    private var mouseMonitor: Any?
    private var scrollMonitor: Any?
    private let menus = MenuBridge()
    private var lastAXRefresh = Date.distantPast
    private var menuTrackingObservers: [NSObjectProtocol] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Prompt once at launch for anything genuinely missing.
        Permissions.report(prompt: true)
        TargetConnection.shared.refresh()

        let contentW: CGFloat = 900, contentH: CGFloat = 640
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: contentW, height: contentH),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered, defer: false
        )
        window.title = "App Mirror"
        window.acceptsMouseMovedEvents = true

        let container = NSView(frame: NSRect(x: 0, y: 0, width: contentW, height: contentH))

        mirror = MirrorView(frame: NSRect(x: 0, y: 0, width: contentW, height: contentH))
        mirror.imageScaling = .scaleAxesIndependently
        mirror.autoresizingMask = [.width, .height]
        container.addSubview(mirror)

        axOverlay = AXOverlayView(frame: mirror.frame)
        axOverlay.autoresizingMask = [.width, .height]
        axOverlay.setAccessibilityElement(true)
        axOverlay.setAccessibilityRole(.scrollArea)
        axOverlay.setAccessibilityLabel("\(TargetConnection.shared.displayName) content")
        container.addSubview(axOverlay, positioned: .above, relativeTo: mirror)

        window.contentView = container
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(mirror)
        NSApp.activate(ignoringOtherApps: true)
        if let pid = TargetConnection.shared.pid() {
            menus.install(pid: pid)
        }
        menuTrackingObservers = [
            NotificationCenter.default.addObserver(
                forName: NSMenu.didBeginTrackingNotification, object: nil, queue: .main
            ) { [weak self] _ in self?.menus.beginTracking() },
            NotificationCenter.default.addObserver(
                forName: NSMenu.didEndTrackingNotification, object: nil, queue: .main
            ) { [weak self] _ in self?.menus.endTracking() },
        ]
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) {
            [weak self] event in
            guard let self else { return event }
            // AppKit owns navigation and shortcuts while its menu tracks.
            guard !self.menus.isTracking else { return event }
            self.mirror.keyboard(event)
            return nil
        }
        mouseMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp,
                       .rightMouseDown, .rightMouseDragged, .rightMouseUp,
                       .otherMouseDown, .otherMouseDragged, .otherMouseUp, .mouseMoved]
        ) { [weak self] event in
            guard let self, !self.menus.isTracking, self.window.isKeyWindow else { return event }
            let point = self.mirror.convert(event.locationInWindow, from: nil)
            guard self.mirror.bounds.contains(point) || self.mirror.hasPointerGesture else { return event }
            self.mirror.pointer(event)
            return nil
        }
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) {
            [weak self] event in
            guard let self, !self.menus.isTracking, self.window.isKeyWindow else { return event }
            self.mirror.scrollWheel(with: event)
            return nil
        }

        axActionObserver = NotificationCenter.default.addObserver(
            forName: .axProxyDidAct, object: nil, queue: .main
        ) { [weak self] _ in
            self?.refreshAXAfterAction()
        }

        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
        }
        if let mouseMonitor {
            NSEvent.removeMonitor(mouseMonitor)
        }
        if let scrollMonitor {
            NSEvent.removeMonitor(scrollMonitor)
        }
        menuTrackingObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    /// Captures the latest ChatGPT frame and refreshes the mirror's target bounds.
    private func tick() {
        // Live permission status in the title bar, visible however the app was
        // launched (unlike stderr logs, which vanish when launched via Finder).
        TargetConnection.shared.refresh()
        let perms = Permissions.summary()
        guard let pid = TargetConnection.shared.pid() else {
            connectedPID = nil
            clearSurface()
            menus.reset()
            NSApp.mainMenu = nil
            window.title = "Mirror — \(TargetConnection.shared.bundleID) not running\(perms)"
            return
        }
        guard let (id, bounds) = TargetConnection.shared.mainWindow(pid: pid) else {
            clearSurface()
            window.title = "\(TargetConnection.shared.displayName) Mirror — no window found\(perms)"
            return
        }
        if connectedPID != pid {
            // Match the outer window size once per connection, keeping its
            // top-left corner in place. Later target resizes do not resize us.
            var frame = window.frame
            frame.origin.y = frame.maxY - bounds.height
            frame.size = bounds.size
            window.setFrame(frame, display: true)
            connectedPID = pid
            menus.install(pid: pid)
            NSLog("MIRROR connected pid=\(pid) targetSize=\(bounds.size) proxySize=\(window.frame.size)")
        }
        windowID = id
        mirror.targetPID = pid
        mirror.targetBounds = bounds
        // Include live event counters so forwarding is verifiable via the title
        // (readable by Computer Use's get_app_state) without log capture.
        window.title = "\(TargetConnection.shared.displayName) Mirror\(perms) [m:\(mirror.mouseDowns) k:\(mirror.keyDowns) \(mirror.lastEvent)]"

        guard let image = CGWindowListCreateImage(
            .null, .optionIncludingWindow, id, [.boundsIgnoreFraming, .nominalResolution]
        ) else { return }
        mirror.image = NSImage(cgImage: image, size: bounds.size)

        // Network-backed pages can finish loading after the action's delayed
        // refresh. Keep the semantic tree current even when no input arrives.
        if axViews.isEmpty || Date().timeIntervalSince(lastAXRefresh) >= 1 {
            refreshAXOverlay(pid: pid, targetBounds: bounds)
        }
    }

    private func clearSurface() {
        mirror.targetPID = 0
        mirror.resetInput()
        mirror.image = nil
        axViews.values.forEach { $0.removeFromSuperview() }
        axViews.removeAll()
        axOverlay.setAccessibilityChildren([])
    }

    private func refreshAXOverlay(pid: pid_t, targetBounds: CGRect) {
        lastAXRefresh = Date()
        let snapshots = AXBridge.snapshots(
            pid: pid,
            targetBounds: targetBounds,
            mirrorSize: axOverlay.bounds.size
        )
        .enumerated()
        .sorted { lhs, rhs in
            func priority(_ snapshot: AXBridge.Snapshot) -> Int {
                if snapshot.roleName == (kAXMenuItemRole as String) { return 0 }
                if snapshot.roleName == (kAXStaticTextRole as String) { return 3 }
                if snapshot.canPress || snapshot.writableValue { return 1 }
                return 2
            }
            let lhsPriority = priority(lhs.element)
            let rhsPriority = priority(rhs.element)
            if lhsPriority != rhsPriority {
                return lhsPriority < rhsPriority
            }
            return lhs.offset < rhs.offset
        }
        .map(\.element)
        let liveKeys = Set(snapshots.map(\.key))

        let staleKeys = axViews.keys.filter { !liveKeys.contains($0) }
        for key in staleKeys {
            axViews[key]?.removeFromSuperview()
            axViews.removeValue(forKey: key)
        }
        for snapshot in snapshots {
            if let view = axViews[snapshot.key] {
                view.update(from: snapshot)
            } else {
                let view = AXProxyElementView(snapshot: snapshot)
                axViews[snapshot.key] = view
                axOverlay.addSubview(view)
            }
        }
        // NSViews stay in overlay coordinates; AX parentage follows useful target containers.
        let children = Dictionary(grouping: snapshots, by: { $0.parentKey })
        for snapshot in snapshots {
            let view = axViews[snapshot.key]!
            view.setAccessibilityParent(snapshot.parentKey.flatMap { axViews[$0] } ?? axOverlay)
            view.setAccessibilityChildren((children[snapshot.key] ?? []).compactMap { axViews[$0.key] })
        }
        axOverlay.setAccessibilityChildren((children[nil] ?? []).compactMap { axViews[$0.key] })
    }

    private func refreshAXAfterAction() {
        guard let pid = TargetConnection.shared.pid(), mirror.targetBounds.width > 0 else { return }
        refreshAXOverlay(pid: pid, targetBounds: mirror.targetBounds)
        TargetConnection.shared.enqueue(after: 0.8) { [weak self] in
            guard let self,
                  let pid = TargetConnection.shared.pid(),
                  self.mirror.targetBounds.width > 0
            else { return }
            self.refreshAXOverlay(pid: pid, targetBounds: self.mirror.targetBounds)
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
