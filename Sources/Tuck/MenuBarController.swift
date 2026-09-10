import AppKit
import ServiceManagement

/// Hides menu bar items by growing a status item until everything to its left
/// is pushed off the left edge of the screen. This is the only mechanism macOS
/// gives a sandbox-free app for this; no private API, no accessibility grant.
final class MenuBarController {
    private let expandedLength: CGFloat = 10_000

    private let divider = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let control = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var hotkey: Hotkey?

    private var isHidden = false {
        didSet { applyState() }
    }

    init() {
        divider.autosaveName = "TuckDivider"
        divider.button?.target = self
        divider.button?.action = #selector(toggle)

        control.autosaveName = "TuckControl"
        control.menu = buildMenu()

        // macOS persists per-autosaveName visibility. If an item was ever
        // dropped for lack of room (common on notched displays) it stays
        // invisible forever unless we assert it on every launch.
        divider.isVisible = true
        control.isVisible = true

        // ⌥⌘B
        hotkey = Hotkey(keyCode: 11, modifiers: [.option, .command]) { [weak self] in
            self?.toggle()
        }

        applyState()

        if ProcessInfo.processInfo.environment["TUCK_DEBUG"] != nil {
            for (name, item) in [("divider", divider), ("control", control)] {
                print("\(name): visible=\(item.isVisible) length=\(item.length) button=\(item.button != nil)")
            }
            print("hotkey registered: \(hotkey != nil)")
        }
    }

    @objc private func toggle() {
        isHidden.toggle()
    }

    /// Symbols can fail to load (missing SF Symbol, older OS). Falling back to
    /// a title keeps the item visible — a variableLength item with neither
    /// image nor title collapses to zero width and looks like a crash.
    private func setIcon(_ item: NSStatusItem, symbol: String, fallback: String, description: String) {
        guard let button = item.button else { return }
        if let image = NSImage(systemSymbolName: symbol, accessibilityDescription: description) {
            image.isTemplate = true
            button.image = image
            button.title = ""
        } else {
            button.image = nil
            button.title = fallback
        }
    }

    private func applyState() {
        if isHidden {
            divider.length = expandedLength
            divider.button?.image = nil
            divider.button?.title = ""
        } else {
            divider.length = NSStatusItem.variableLength
            setIcon(divider, symbol: "line.3.vertical", fallback: "|", description: "Divider")
        }

        setIcon(control,
                symbol: isHidden ? "chevron.right" : "chevron.left",
                fallback: isHidden ? "›" : "‹",
                description: isHidden ? "Show items" : "Hide items")

        menuItem(tag: 1)?.title = isHidden ? "Show Items" : "Hide Items"
    }

    // MARK: - Menu

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(title: "Hide Items", action: #selector(toggle), keyEquivalent: "b")
        toggleItem.keyEquivalentModifierMask = [.option, .command]
        toggleItem.target = self
        toggleItem.tag = 1
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        loginItem.target = self
        loginItem.tag = 2
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(loginItem)

        let tip = NSMenuItem(title: "Tip: ⌘-drag the divider to choose which items hide",
                             action: nil, keyEquivalent: "")
        tip.isEnabled = false
        menu.addItem(tip)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Tuck", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)

        return menu
    }

    private func menuItem(tag: Int) -> NSMenuItem? {
        control.menu?.items.first { $0.tag == tag }
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSAlert(error: error).runModal()
        }
        sender.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }
}
