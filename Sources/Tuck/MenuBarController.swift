import AppKit
import ServiceManagement

/// Hides menu bar items by growing a spacer status item until everything to its
/// left is pushed off the left edge of the screen. This is the only mechanism
/// macOS gives a sandbox-free app; no private API, no accessibility grant.
final class MenuBarController {
    private let expandedLength: CGFloat = 10_000

    private let divider: NSStatusItem
    private let control: NSStatusItem
    private var hotkey: Hotkey?
    private var settingsWindow: SettingsWindowController?

    private var isHidden = false {
        didSet { applyState() }
    }

    init() {
        // Order matters: macOS creates new status items at the LEFT end of the
        // status area, so the control would land left of the divider and be
        // swallowed when the divider expands. "Preferred Position" is distance
        // from the right edge (lower = further right) and is read only at
        // creation time. Seed it only when unset, or we stomp the user's
        // own ⌘-drag on every launch.
        MenuBarController.seedPosition(autosaveName: "TuckControl", position: 0)
        MenuBarController.seedPosition(autosaveName: "TuckDivider", position: 1)

        control = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        divider = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        control.autosaveName = "TuckControl"
        control.button?.target = self
        control.button?.action = #selector(controlClicked)
        control.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        divider.autosaveName = "TuckDivider"
        divider.button?.target = self
        divider.button?.action = #selector(toggle)

        // macOS persists per-autosaveName visibility; an item dropped for lack
        // of room stays invisible forever unless we assert it each launch.
        control.isVisible = true
        divider.isVisible = true

        registerHotkey()
        applyState()

        NotificationCenter.default.addObserver(
            self, selector: #selector(settingsChanged),
            name: Settings.didChange, object: nil
        )
    }

    private static func seedPosition(autosaveName: String, position: Int) {
        let key = "NSStatusItem Preferred Position \(autosaveName)"
        guard UserDefaults.standard.object(forKey: key) == nil else { return }
        UserDefaults.standard.set(position, forKey: key)
    }

    // MARK: - State

    @objc private func toggle() {
        isHidden.toggle()
    }

    /// Left click toggles, right click opens the menu. Assigning `control.menu`
    /// permanently would make left click open the menu too, so the menu is
    /// popped up manually instead.
    @objc private func controlClicked() {
        guard let event = NSApp.currentEvent, let button = control.button else { return toggle() }
        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            buildMenu().popUp(positioning: nil,
                              at: NSPoint(x: 0, y: button.bounds.height + 4),
                              in: button)
        } else {
            toggle()
        }
    }

    private func applyState() {
        let settings = Settings.shared

        // The divider is what does the hiding. The control sits to its right so
        // it always stays on screen.
        divider.isVisible = settings.showDivider || isHidden
        if isHidden {
            divider.length = expandedLength
            divider.button?.image = nil
            divider.button?.title = ""
        } else {
            divider.length = NSStatusItem.variableLength
            setIcon(divider, symbol: "line.3.vertical", fallback: "|", description: "Divider")
        }

        let (symbol, fallback) = settings.iconStyle.symbols(hidden: isHidden)
        setIcon(control, symbol: symbol, fallback: fallback,
                description: isHidden ? "Show menu bar items" : "Hide menu bar items")
        control.button?.toolTip = isHidden ? "Show items (\(shortcutText))" : "Hide items (\(shortcutText))"
    }

    private var shortcutText: String {
        describeHotkey(keyCode: Settings.shared.hotkeyKeyCode, modifiers: Settings.shared.hotkeyModifiers)
    }

    /// Symbols can fail to load. Falling back to a title keeps the item
    /// visible — a variableLength item with neither image nor title collapses
    /// to zero width and looks exactly like a crash.
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

    @objc private func settingsChanged() {
        registerHotkey()
        applyState()
    }

    private func registerHotkey() {
        hotkey = nil   // deinit unregisters the old one
        hotkey = Hotkey(keyCode: Settings.shared.hotkeyKeyCode,
                        modifiers: Settings.shared.hotkeyModifiers) { [weak self] in
            self?.toggle()
        }
    }

    // MARK: - Menu

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(title: isHidden ? "Show Items" : "Hide Items",
                                    action: #selector(toggle), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Tuck", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)

        return menu
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindowController()
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.showWindow(nil)
    }
}
