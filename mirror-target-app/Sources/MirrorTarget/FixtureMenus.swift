import AppKit

final class FixtureMenus: NSObject, NSMenuDelegate {
    private let model: Model
    private var allowed = false
    private var count = 0
    private var nestedCount = 0
    private var countItem: NSMenuItem?

    init(model: Model) { self.model = model }

    func install() {
        let main = NSMenu()
        let appItem = NSMenuItem(title: "MirrorTarget", action: nil, keyEquivalent: "")
        let appMenu = NSMenu(title: "MirrorTarget")
        appMenu.addItem(withTitle: "Quit MirrorTarget", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        main.addItem(appItem)
        let edit = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        let editMenu = NSMenu(title: "Edit")
        for (title, action, key) in [
            ("Cut", #selector(NSText.cut(_:)), "x"),
            ("Copy", #selector(NSText.copy(_:)), "c"),
            ("Paste", #selector(NSText.paste(_:)), "v"),
            ("Select All", #selector(NSText.selectAll(_:)), "a"),
        ] {
            editMenu.addItem(withTitle: title, action: action, keyEquivalent: key)
        }
        edit.submenu = editMenu
        main.addItem(edit)
        let root = NSMenuItem(title: "Fixture", action: nil, keyEquivalent: "")
        let menu = NSMenu(title: "Fixture")
        menu.delegate = self
        menu.autoenablesItems = false
        root.submenu = menu
        main.addItem(root)
        NSApp.mainMenu = main
        menuNeedsUpdate(menu)
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        if menu.title == "Nested" {
            let action = NSMenuItem(title: "Nested action (\(nestedCount))", action: #selector(incrementNested), keyEquivalent: "")
            action.target = self
            menu.addItem(action)
            return
        }
        let toggle = NSMenuItem(title: "Allow count", action: #selector(toggle), keyEquivalent: "")
        toggle.target = self
        toggle.state = allowed ? .on : .off
        menu.addItem(toggle)
        let action = NSMenuItem(title: "Count action (\(count))", action: #selector(increment), keyEquivalent: "j")
        action.keyEquivalentModifierMask = [.command, .shift]
        action.target = self
        action.isEnabled = allowed
        countItem = action
        menu.addItem(action)
        menu.addItem(.separator())
        let nested = NSMenuItem(title: "Nested", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "Nested")
        submenu.delegate = self
        submenu.autoenablesItems = false
        menuNeedsUpdate(submenu)
        nested.submenu = submenu
        menu.addItem(nested)
        menu.addItem(.separator())
        let prefs = NSMenuItem(title: "Preferences…", action: #selector(preferencesAction), keyEquivalent: ",")
        prefs.target = self
        menu.addItem(prefs)
        model.log("Menu state: allowed=\(allowed) count=\(count)")
    }

    func menuWillOpen(_ menu: NSMenu) { model.log("Menu opened: \(menu.title)") }
    func menuDidClose(_ menu: NSMenu) { model.log("Menu closed: \(menu.title)") }
    func menu(_ menu: NSMenu, willHighlight item: NSMenuItem?) {
        model.log("Menu highlight: \(item?.title ?? "none")")
    }

    @objc private func toggle() {
        allowed.toggle()
        // State is changed after an action, while titles are rebuilt on opening.
        NSApp.mainMenu?.items.last?.submenu?.items.first?.state = allowed ? .on : .off
        countItem?.isEnabled = allowed
        model.log("Menu allowed=\(allowed)")
    }
    @objc private func increment() {
        guard allowed else { return }
        count += 1
        model.log("Menu count=\(count)")
    }
    @objc private func incrementNested() {
        nestedCount += 1
        model.log("Nested menu count=\(nestedCount)")
    }
    @objc private func preferencesAction() {
        model.log("Menu action: Preferences opened")
    }
}
