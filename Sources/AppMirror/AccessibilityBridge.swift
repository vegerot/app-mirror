import AppKit

// Republish the target accessibility surface and forward its supported operations.
enum AXBridge {
    struct Snapshot {
        let path: [PathSegment]
        let parentKey: Int?
        let supportedActions: [String]
        let writableValue: Bool
        let writableSelection: Bool
        let key: Int
        let remote: AXUIElement
        let role: NSAccessibility.Role
        let roleName: String
        let label: String?
        let value: Any?
        let frame: NSRect
        let remoteFrame: CGRect
        let canPress: Bool
        let enabled: Bool
    }

    static func copyAttr(_ el: AXUIElement, _ a: String) -> CFTypeRef? {
        var v: CFTypeRef?
        return AXUIElementCopyAttributeValue(el, a as CFString, &v) == .success ? v : nil
    }
    static func str(_ el: AXUIElement, _ a: String) -> String? { copyAttr(el, a) as? String }
    static func actions(_ el: AXUIElement) -> [String] {
        var names: CFArray?
        return AXUIElementCopyActionNames(el, &names) == .success ? (names as? [String] ?? []) : []
    }

    static func point(_ el: AXUIElement, _ attr: String) -> CGPoint? {
        guard let raw = copyAttr(el, attr),
              CFGetTypeID(raw) == AXValueGetTypeID()
        else { return nil }
        var point = CGPoint.zero
        return AXValueGetValue(raw as! AXValue, .cgPoint, &point) ? point : nil
    }

    static func size(_ el: AXUIElement, _ attr: String) -> CGSize? {
        guard let raw = copyAttr(el, attr),
              CFGetTypeID(raw) == AXValueGetTypeID()
        else { return nil }
        var size = CGSize.zero
        return AXValueGetValue(raw as! AXValue, .cgSize, &size) ? size : nil
    }

    static func mainWindow(pid: pid_t) -> AXUIElement? {
        guard let value = copyAttr(AXUIElementCreateApplication(pid), kAXMainWindowAttribute as String),
              CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }

    private static func simpleValue(_ el: AXUIElement) -> Any? {
        guard let value = copyAttr(el, kAXValueAttribute as String) else { return nil }
        if let string = value as? String { return string }
        if let number = value as? NSNumber { return number }
        return nil
    }

    private struct Node {
        let role: String
        let title: String?
        let desc: String?
        let value: Any?
        let position: CGPoint?
        let size: CGSize?
        let children: [AXUIElement]
        let enabled: Bool

        var label: String? {
            [title, desc]
                .compactMap { $0?.isEmpty == false ? $0 : nil }
                .first ?? (value as? String)
        }
    }

    /// Reads the attributes needed by the snapshot walker in one cross-process
    /// AX request instead of 6-8 individual IPC round trips per element.
    private static func node(_ el: AXUIElement) -> Node? {
        let attributes: [CFString] = [
            kAXRoleAttribute as CFString,
            kAXTitleAttribute as CFString,
            kAXDescriptionAttribute as CFString,
            kAXValueAttribute as CFString,
            kAXPositionAttribute as CFString,
            kAXSizeAttribute as CFString,
            kAXChildrenAttribute as CFString,
            kAXEnabledAttribute as CFString,
        ]
        var rawValues: CFArray?
        let options = AXCopyMultipleAttributeOptions(rawValue: 0)
        guard AXUIElementCopyMultipleAttributeValues(
            el, attributes as CFArray, options, &rawValues
        ) == .success,
           let values = rawValues as? [Any],
           values.count == attributes.count else { return nil }
        // With options=0, unsupported individual attributes occupy error/null
        // slots. A failed request is not a reason to repeat every attribute.

        func present(_ index: Int) -> Any? {
            let value = values[index]
            return value is NSNull ? nil : value
        }
        func pointValue(_ value: Any?) -> CGPoint? {
            guard let value,
                  CFGetTypeID(value as CFTypeRef) == AXValueGetTypeID()
            else { return nil }
            var point = CGPoint.zero
            return AXValueGetValue(value as! AXValue, .cgPoint, &point) ? point : nil
        }
        func sizeValue(_ value: Any?) -> CGSize? {
            guard let value,
                  CFGetTypeID(value as CFTypeRef) == AXValueGetTypeID()
            else { return nil }
            var size = CGSize.zero
            return AXValueGetValue(value as! AXValue, .cgSize, &size) ? size : nil
        }

        let rawValue = present(3)
        let value: Any?
        if let string = rawValue as? String {
            value = string
        } else if let number = rawValue as? NSNumber {
            value = number
        } else {
            value = nil
        }

        return Node(
            role: present(0) as? String ?? "",
            title: present(1) as? String,
            desc: present(2) as? String,
            value: value,
            position: pointValue(present(4)),
            size: sizeValue(present(5)),
            children: present(6) as? [AXUIElement] ?? [],
            enabled: present(7) as? Bool ?? true
        )
    }

    private static func label(_ el: AXUIElement) -> String? {
        let title = str(el, kAXTitleAttribute as String)
        let desc = str(el, kAXDescriptionAttribute as String)
        return [title, desc]
            .compactMap { $0?.isEmpty == false ? $0 : nil }
            .first ?? (simpleValue(el) as? String)
    }

    struct PathSegment {
        let role: String
        let identifier: String?
        let label: String?
        let ordinal: Int
        let count: Int
    }

    static func isWritable(_ element: AXUIElement, _ attribute: String) -> Bool {
        var writable = DarwinBoolean(false)
        return AXUIElementIsAttributeSettable(element, attribute as CFString, &writable) == .success
            && writable.boolValue
    }

    private static func identity(_ element: AXUIElement) -> String {
        [str(element, kAXRoleAttribute as String) ?? "",
         str(element, kAXIdentifierAttribute as String) ?? "",
         str(element, kAXTitleAttribute as String) ?? str(element, kAXDescriptionAttribute as String) ?? ""]
            .joined(separator: "\u{1f}")
    }

    /// Resolve only inside each recorded parent. Never choose the nearest of
    /// unrelated controls with the same label when the original node disappears.
    static func freshElement(pid: pid_t, path: [PathSegment]) -> AXUIElement? {
        guard var current = mainWindow(pid: pid) else { return nil }
        for segment in path {
            let children = copyAttr(current, kAXChildrenAttribute as String) as? [AXUIElement] ?? []
            let matches = children.filter {
                guard str($0, kAXRoleAttribute as String) == segment.role else { return false }
                if let identifier = segment.identifier, !identifier.isEmpty {
                    return str($0, kAXIdentifierAttribute as String) == identifier
                }
                return (str($0, kAXTitleAttribute as String) ?? str($0, kAXDescriptionAttribute as String)) == segment.label
            }
            guard matches.count == segment.count, matches.indices.contains(segment.ordinal) else { return nil }
            current = matches[segment.ordinal]
        }
        return current
    }

    static func menuItem(pid: pid_t, path: [String]) -> AXUIElement? {
        guard let rootTitle = path.first,
              let rawMenuBar = copyAttr(
                  AXUIElementCreateApplication(pid),
                  kAXMenuBarAttribute as String
              ),
              CFGetTypeID(rawMenuBar) == AXUIElementGetTypeID()
        else { return nil }

        let menuBar = rawMenuBar as! AXUIElement
        let roots = copyAttr(menuBar, kAXChildrenAttribute as String)
            as? [AXUIElement] ?? []
        guard var current = roots.first(where: {
            str($0, kAXTitleAttribute as String) == rootTitle
        }) else { return nil }

        func directItems(_ element: AXUIElement) -> [AXUIElement] {
            let children = copyAttr(element, kAXChildrenAttribute as String)
                as? [AXUIElement] ?? []
            return children.flatMap { child -> [AXUIElement] in
                let role = str(child, kAXRoleAttribute as String) ?? ""
                if role == (kAXMenuItemRole as String) {
                    return [child]
                }
                if role == (kAXMenuRole as String) {
                    return directItems(child)
                }
                return []
            }
        }

        for title in path.dropFirst() {
            guard let match = directItems(current).first(where: {
                str($0, kAXTitleAttribute as String) == title
            }) else { return nil }
            current = match
        }
        return current
    }

    /// Flattens visible, inspectable controls from the target window into
    /// proxy-local frames. A flat first pass keeps identity/action forwarding
    /// testable before reproducing ChatGPT's full nested hierarchy.
    static func snapshots(
        pid: pid_t,
        targetBounds: CGRect,
        mirrorSize: CGSize,
        maxElements: Int = 300,
        maxVisited: Int = 1_000
    ) -> [Snapshot] {
        let supportedRoles: Set<String> = [
            kAXButtonRole as String,
            kAXCheckBoxRole as String,
            kAXPopUpButtonRole as String,
            kAXRadioButtonRole as String,
            kAXMenuItemRole as String,
            kAXTextAreaRole as String,
            kAXTextFieldRole as String,
            kAXStaticTextRole as String,
            kAXSplitterRole as String,
            "AXLink",
            kAXSliderRole as String,
        ]
        let containerRoles: Set<String> = [kAXGroupRole as String, kAXScrollAreaRole as String, kAXMenuRole as String]
        var actionable: [Snapshot] = []
        var passive: [Snapshot] = []
        var visited = 0

        let coordinates = CoordinateMap(target: targetBounds, mirror: mirrorSize)

        guard let root = mainWindow(pid: pid) else { return [] }

        var queue: [(element: AXUIElement, depth: Int, path: [PathSegment], parent: Int?, clip: CGRect)] = [(root, 0, [], nil, targetBounds)]
        var index = 0
        while index < queue.count, visited < maxVisited
        {
            let (el, depth, path, parent, clip) = queue[index]
            var childClip = clip
            var childParent = parent
            index += 1
            guard depth <= 50 else { continue }
            visited += 1
            guard let node = node(el) else { continue }
            let roleName = node.role
            if roleName == (kAXMenuBarRole as String) { continue }

            let namedGroup = roleName == (kAXGroupRole as String)
                && [node.title, node.desc].contains { $0?.isEmpty == false }
            let isContainer = containerRoles.contains(roleName)
                && (roleName != (kAXGroupRole as String) || namedGroup)
                && !node.children.isEmpty
            if supportedRoles.contains(roleName) || isContainer,
               let position = node.position,
               let elementSize = node.size,
               let frame = coordinates.localFrame(CGRect(origin: position, size: elementSize).intersection(clip))
            {
                let supportedActions = actions(el)
                let canPress = supportedActions.contains(kAXPressAction as String)
                    || supportedActions.contains(kAXShowMenuAction as String)
                let textInput = roleName == (kAXTextFieldRole as String) || roleName == (kAXTextAreaRole as String)
                let proxyRole = NSAccessibility.Role(rawValue: roleName)
                let key = Int(CFHash(el))
                let snapshot = Snapshot(
                    path: path, parentKey: parent, supportedActions: supportedActions,
                    writableValue: (textInput || roleName == (kAXSliderRole as String)) && isWritable(el, kAXValueAttribute as String),
                    writableSelection: textInput && isWritable(el, kAXSelectedTextRangeAttribute as String),
                    key: Int(CFHash(el)),
                    remote: el,
                    role: proxyRole,
                    roleName: roleName,
                    label: isContainer ? (node.title ?? node.desc) : node.label,
                    value: node.value,
                    frame: frame,
                    remoteFrame: CGRect(origin: position, size: elementSize),
                    canPress: canPress,
                    enabled: node.enabled
                )
                if isContainer { childParent = key }
                if roleName == (kAXScrollAreaRole as String) {
                    childClip = clip.intersection(CGRect(origin: position, size: elementSize))
                }
                if canPress || isContainer {
                    actionable.append(snapshot)
                } else if passive.count < maxElements {
                    passive.append(snapshot)
                }
            }

            let identities = node.children.map(identity)
            for (index, child) in node.children.enumerated() {
                let signature = identities[index]
                let segment = PathSegment(
                    role: str(child, kAXRoleAttribute as String) ?? "",
                    identifier: str(child, kAXIdentifierAttribute as String),
                    label: str(child, kAXTitleAttribute as String) ?? str(child, kAXDescriptionAttribute as String),
                    ordinal: identities.prefix(index).filter { $0 == signature }.count,
                    count: identities.filter { $0 == signature }.count)
                queue.append((child, depth + 1, path + [segment], childParent, childClip))
            }
        }
        return Array((actionable + passive).prefix(maxElements))
    }
}

/// Invisible AppKit accessibility element backed by one live target AX element.
/// Computer Use sees this view as belonging to the proxy bundle, while actions
/// are forwarded to the matching element in TargetConnection.shared.
final class AXProxyElementView: NSView {
    var path: [AXBridge.PathSegment] = []
    var supportedActions: [String] = []
    var writableValue = false
    var writableSelection = false
    var remote: AXUIElement
    var roleName: String
    var elementLabel: String?
    var remoteFrame: CGRect
    var canPress: Bool
    var elementEnabled: Bool

    init(snapshot: AXBridge.Snapshot) {
        path = snapshot.path
        supportedActions = snapshot.supportedActions
        writableValue = snapshot.writableValue
        writableSelection = snapshot.writableSelection
        remote = snapshot.remote
        roleName = snapshot.roleName
        elementLabel = snapshot.label
        remoteFrame = snapshot.remoteFrame
        canPress = snapshot.canPress
        elementEnabled = snapshot.enabled
        super.init(frame: snapshot.frame)
        update(from: snapshot)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        canPress ? self : nil
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { canPress }

    override func mouseDown(with event: NSEvent) {
        _ = accessibilityPerformPress()
    }

    override func accessibilityFrame() -> NSRect {
        guard let window else { return .zero }
        return window.convertToScreen(convert(bounds, to: nil))
    }

    override func isAccessibilityEnabled() -> Bool {
        AXBridge.copyAttr(remote, kAXEnabledAttribute as String) as? Bool ?? elementEnabled
    }

    override func isAccessibilitySelectorAllowed(_ selector: Selector) -> Bool {
        switch NSStringFromSelector(selector) {
        case "setAccessibilityValue:": return writableValue
        case "setAccessibilitySelectedTextRange:": return writableSelection
        case "accessibilityPerformPress": return canPress
        case "accessibilityPerformShowMenu": return supportedActions.contains("AXShowMenu")
        case "accessibilityPerformIncrement": return supportedActions.contains("AXIncrement")
        case "accessibilityPerformDecrement": return supportedActions.contains("AXDecrement")
        case "accessibilityPerformCancel": return supportedActions.contains("AXCancel")
        case "accessibilityPerformConfirm": return supportedActions.contains("AXConfirm")
        default: return super.isAccessibilitySelectorAllowed(selector)
        }
    }

    private func perform(_ action: String) -> Bool {
        guard supportedActions.contains(action), isAccessibilityEnabled(),
              let pid = TargetConnection.shared.pid(),
              let current = AXBridge.freshElement(pid: pid, path: path) else { return false }
        let ok = AXUIElementPerformAction(current, action as CFString) == .success
        NotificationCenter.default.post(name: .axProxyDidAct, object: nil)
        return ok
    }
    override func accessibilityPerformShowMenu() -> Bool { perform("AXShowMenu") }
    override func accessibilityPerformIncrement() -> Bool { perform("AXIncrement") }
    override func accessibilityPerformDecrement() -> Bool { perform("AXDecrement") }
    override func accessibilityPerformCancel() -> Bool { perform("AXCancel") }
    override func accessibilityPerformConfirm() -> Bool { perform("AXConfirm") }

    override func accessibilityLabel() -> String? {
        elementLabel ?? super.accessibilityLabel()
    }

    override func accessibilityValue() -> Any? {
        if canPress, roleName == (kAXStaticTextRole as String) {
            return nil
        }
        return AXBridge.copyAttr(remote, kAXValueAttribute as String)
            ?? super.accessibilityValue()
    }

    override func setAccessibilityValue(_ accessibilityValue: Any?) {
        let canSetValue = roleName == (kAXTextFieldRole as String)
            || roleName == (kAXTextAreaRole as String)
            || roleName == (kAXSliderRole as String)
        guard canSetValue, writableValue,
              let pid = TargetConnection.shared.pid(),
              let mainWindow = TargetConnection.shared.mainWindow(pid: pid)
        else { return }
        InputForwarder.activateMainWindow(pid: pid, targetBounds: mainWindow.bounds)
        usleep(100_000)
        guard let current = AXBridge.freshElement(
            pid: pid,
            path: path
        ) else {
            NSLog("AXProxy: stale value target \(elementLabel ?? roleName)")
            NotificationCenter.default.post(name: .axProxyDidAct, object: nil)
            return
        }
        remote = current
        let error = AXUIElementSetAttributeValue(
            current,
            kAXValueAttribute as CFString,
            accessibilityValue as CFTypeRef
        )
        NSLog("AXProxy: setValue \(elementLabel ?? roleName) -> \(error == .success ? "success" : "fail(\(error.rawValue))")")
        usleep(150_000)
        NotificationCenter.default.post(name: .axProxyDidAct, object: nil)
    }

    override func accessibilitySelectedTextRange() -> NSRange {
        guard let raw = AXBridge.copyAttr(
            remote,
            kAXSelectedTextRangeAttribute as String
        ),
        CFGetTypeID(raw) == AXValueGetTypeID()
        else { return super.accessibilitySelectedTextRange() }

        var range = CFRange()
        guard AXValueGetValue(raw as! AXValue, .cfRange, &range)
        else { return super.accessibilitySelectedTextRange() }
        return NSRange(location: range.location, length: range.length)
    }

    override func setAccessibilitySelectedTextRange(
        _ accessibilitySelectedTextRange: NSRange
    ) {
        let canSelectText = roleName == (kAXTextFieldRole as String)
            || roleName == (kAXTextAreaRole as String)
        guard canSelectText, writableSelection,
              let pid = TargetConnection.shared.pid(),
              let mainWindow = TargetConnection.shared.mainWindow(pid: pid)
        else { return }

        InputForwarder.activateMainWindow(pid: pid, targetBounds: mainWindow.bounds)
        usleep(100_000)
        guard let current = AXBridge.freshElement(
            pid: pid,
            path: path
        ) else {
            NSLog("AXProxy: stale selection target \(elementLabel ?? roleName)")
            return
        }

        remote = current
        _ = AXUIElementSetAttributeValue(
            current,
            kAXFocusedAttribute as CFString,
            kCFBooleanTrue
        )
        var range = CFRange(
            location: accessibilitySelectedTextRange.location,
            length: accessibilitySelectedTextRange.length
        )
        guard let value = AXValueCreate(.cfRange, &range) else { return }
        let error = AXUIElementSetAttributeValue(
            current,
            kAXSelectedTextRangeAttribute as CFString,
            value
        )
        NSLog("AXProxy: selectRange \(elementLabel ?? roleName) \(range.location),\(range.length) -> \(error == .success ? "success" : "fail(\(error.rawValue))")")
        fflush(stderr)
    }

    func update(from snapshot: AXBridge.Snapshot) {
        path = snapshot.path
        supportedActions = snapshot.supportedActions
        writableValue = snapshot.writableValue
        writableSelection = snapshot.writableSelection
        remote = snapshot.remote
        roleName = snapshot.roleName
        elementLabel = snapshot.label
        remoteFrame = snapshot.remoteFrame
        canPress = snapshot.canPress
        elementEnabled = snapshot.enabled
        frame = snapshot.frame
        setAccessibilityElement(true)
        setAccessibilityRole(snapshot.role)
        setAccessibilityTitle(snapshot.label)
        setAccessibilityLabel(snapshot.label)
        super.setAccessibilityValue(snapshot.value)
        setAccessibilityEnabled(snapshot.enabled)
    }

    override func accessibilityPerformPress() -> Bool {
        guard canPress, isAccessibilityEnabled() else { return false }
        let pid = TargetConnection.shared.pid()
        if let pid, let mainWindow = TargetConnection.shared.mainWindow(pid: pid) {
            InputForwarder.activateMainWindow(pid: pid, targetBounds: mainWindow.bounds)
            usleep(100_000)
        }
        guard let current = pid.flatMap({
            AXBridge.freshElement(
                pid: $0,
                path: path
            )
        }) else {
            NSLog("AXProxy: stale \(accessibilityLabel() ?? accessibilityRole()?.rawValue ?? "?")")
            NotificationCenter.default.post(name: .axProxyDidAct, object: nil)
            return false
        }
        remote = current
        let ok = InputForwarder.press(current)
        NSLog("AXProxy: pointer press \(elementLabel ?? roleName) -> \(ok ? "success" : "failed")")
        fflush(stderr)
        if ok {
            usleep(150_000)
            NotificationCenter.default.post(name: .axProxyDidAct, object: nil)
        }
        return ok
    }
}
