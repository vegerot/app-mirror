import AppKit

final class AXMenuActionTarget: NSObject {
    let path: [String]

    init(path: [String]) {
        self.path = path
    }

    @objc func invoke(_ sender: NSMenuItem) {
        guard let pid = TargetConnection.shared.pid(),
              let mainWindow = TargetConnection.shared.mainWindow(pid: pid)
        else { return }
        InputForwarder.activateMainWindow(pid: pid, targetBounds: mainWindow.bounds)
        guard let remote = AXBridge.menuItem(pid: pid, path: path),
              AXBridge.copyAttr(remote, kAXEnabledAttribute as String) as? Bool != false else {
            NSLog("AXMenu: stale \(path.joined(separator: " > "))")
            return
        }
        let error = AXUIElementPerformAction(
            remote,
            kAXPressAction as CFString
        )
        NSLog("AXMenu: AXPress \(sender.title) -> \(error == .success ? "success" : "fail(\(error.rawValue))")")
        fflush(stderr)
        NotificationCenter.default.post(name: .axProxyDidAct, object: nil)
    }
}

private final class RemoteMenu: NSMenu {
    var path: [String] = []
}

final class MenuBridge: NSObject, NSMenuDelegate {
    private var openMenus: Set<ObjectIdentifier> = []
    private var notificationTracking = false
    private weak var rootMenu: NSMenu?
    var isTracking: Bool {
        notificationTracking || !openMenus.isEmpty || rootMenu?.items.contains(where: visibleMenu) == true
    }

    private func visibleMenu(_ item: NSMenuItem) -> Bool {
        item.isHighlighted
            || item.submenu?.highlightedItem != nil
            || item.submenu?.items.contains(where: visibleMenu) == true
    }

    func beginTracking() { notificationTracking = true }
    func endTracking() { notificationTracking = false }

    func menuWillOpen(_ menu: NSMenu) {
        openMenus.insert(ObjectIdentifier(menu))
    }
    func menuDidClose(_ menu: NSMenu) { openMenus.remove(ObjectIdentifier(menu)) }

    func reset() {
        rootMenu?.cancelTrackingWithoutAnimation()
        rootMenu = nil
        notificationTracking = false
        openMenus.removeAll()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        guard let menu = menu as? RemoteMenu,
              let pid = TargetConnection.shared.pid() else { return }
        menu.removeAllItems()
        guard let remote = AXBridge.menuItem(pid: pid, path: menu.path) else { return }
        for child in AXBridge.copyAttr(remote, kAXChildrenAttribute as String) as? [AXUIElement] ?? [] {
            appendMenuChildren(of: child, to: menu, path: menu.path, depth: 0)
        }
    }

    private func submenu(title: String, path: [String]) -> RemoteMenu {
        let menu = RemoteMenu(title: title)
        menu.path = path
        menu.delegate = self
        menu.autoenablesItems = false
        return menu
    }

    static func modifiers(_ raw: Int) -> NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if raw & 1 != 0 { flags.insert(.shift) }
        if raw & 2 != 0 { flags.insert(.option) }
        if raw & 4 != 0 { flags.insert(.control) }
        if raw & 8 == 0 { flags.insert(.command) }
        return flags
    }

    private func updateState(_ item: NSMenuItem, from remote: AXUIElement) {
        item.isEnabled = AXBridge.copyAttr(remote, kAXEnabledAttribute as String) as? Bool ?? true
        let mark = AXBridge.str(remote, "AXMenuItemMarkChar") ?? ""
        item.state = mark.isEmpty ? .off : (mark == "-" ? .mixed : .on)
        item.keyEquivalent = (AXBridge.str(remote, "AXMenuItemCmdChar") ?? "").lowercased()
        item.keyEquivalentModifierMask = Self.modifiers(AXBridge.copyAttr(remote, "AXMenuItemCmdModifiers") as? Int ?? 0)
    }
    func install(pid: pid_t) {
        let application = AXUIElementCreateApplication(pid)
        guard let rawMenuBar = AXBridge.copyAttr(
            application,
            kAXMenuBarAttribute as String
        ),
        CFGetTypeID(rawMenuBar) == AXUIElementGetTypeID()
        else { return }
        let menuBar = rawMenuBar as! AXUIElement
        guard
        let roots = AXBridge.copyAttr(
            menuBar,
            kAXChildrenAttribute as String
        ) as? [AXUIElement]
        else { return }

        reset()
        let mainMenu = NSMenu()
        rootMenu = mainMenu
        for root in roots {
            let title = AXBridge.str(root, kAXTitleAttribute as String) ?? ""
            guard !title.isEmpty, title != "Apple" else { continue }
            let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            let submenu = submenu(title: title, path: [title])
            let children = AXBridge.copyAttr(
                root,
                kAXChildrenAttribute as String
            ) as? [AXUIElement] ?? []
            for child in children {
                appendMenuChildren(
                    of: child,
                    to: submenu,
                    path: [title],
                    depth: 0
                )
            }
            item.submenu = submenu
            mainMenu.addItem(item)
        }
        NSApp.mainMenu = mainMenu
    }

    private func appendMenuChildren(
        of remote: AXUIElement,
        to menu: NSMenu,
        path: [String],
        depth: Int
    ) {
        guard depth < 8 else { return }
        let children = AXBridge.copyAttr(
            remote,
            kAXChildrenAttribute as String
        ) as? [AXUIElement] ?? []
        let role = AXBridge.str(remote, kAXRoleAttribute as String) ?? ""

        if role == (kAXMenuRole as String) {
            for child in children {
                appendMenuChildren(
                    of: child,
                    to: menu,
                    path: path,
                    depth: depth + 1
                )
            }
            return
        }
        guard role == (kAXMenuItemRole as String) else { return }

        let title = AXBridge.str(remote, kAXTitleAttribute as String) ?? ""
        if title.isEmpty {
            menu.addItem(.separator())
            return
        }

        let submenuNode = children.first {
            AXBridge.str($0, kAXRoleAttribute as String)
                == (kAXMenuRole as String)
        }
        if let submenuNode {
            let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            let submenu = submenu(title: title, path: path + [title])
            appendMenuChildren(
                of: submenuNode,
                to: submenu,
                path: path + [title],
                depth: depth + 1
            )
            item.submenu = submenu
            updateState(item, from: remote)
            menu.addItem(item)
            return
        }

        let target = AXMenuActionTarget(path: path + [title])

        let item = NSMenuItem(
            title: title,
            action: #selector(AXMenuActionTarget.invoke(_:)),
            keyEquivalent: ""
        )
        item.target = target
        item.representedObject = target // NSMenuItem.target is weak.
        updateState(item, from: remote)
        menu.addItem(item)
    }

}
