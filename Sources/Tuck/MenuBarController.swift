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
        divider.button?.imagePosition = .imageOnly

        control.autosaveName = "TuckControl"
        control.button?.image = NSImage(
            systemSymbolName: "chevron.left.chevron.right",
            accessibilityDescription: "Tuck"
        )
        control.menu = buildMenu()

        // ⌥⌘B
        hotkey = Hotkey(keyCode: 11, modifiers: [.option, .command]) { [weak self] in
            self?.toggle()
        }

        applyState()
    }

    @objc private func toggle() {
        isHidden.toggle()
    }

    private func applyState() {
        divider.length = isHidden ? expandedLength : NSStatusItem.variableLength
        divider.button?.image = isHidden
            ? nil
            : NSImage(systemSymbolName: "line.3.vertical", accessibilityDescription: "Divider")
        control.button?.image = NSImage(
            systemSymbolName: isHidden ? "chevron.right" : "chevron.left",
            accessibilityDescription: isHidden ? "Show items" : "Hide items"
        )
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

        menu.addItem(withTitle: "Tip: ⌘-drag the divider to choose which items hide",
                     action: nil, keyEquivalent: "").isEnabled = false

        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Tuck", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

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
