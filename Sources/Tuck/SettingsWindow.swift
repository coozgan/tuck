import AppKit
import ServiceManagement
import Carbon.HIToolbox

/// Plain AppKit settings window — no SwiftUI, so the app stays a single
/// dependency-free binary that builds with only Command Line Tools.
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private let recorder = ShortcutRecorder()
    private var launchAtLoginCheckbox: NSButton!
    private var dividerCheckbox: NSButton!
    private var stylePopup: NSPopUpButton!

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 260),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Tuck Settings"
        window.center()
        window.isReleasedWhenClosed = false
        self.init(window: window)
        window.delegate = self
        buildContent()
    }

    private func buildContent() {
        guard let window else { return }

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 24, bottom: 20, right: 24)
        stack.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(header("Shortcut"))
        stack.addArrangedSubview(row("Toggle hiding:", recorder))

        stack.addArrangedSubview(header("Appearance"))

        stylePopup = NSPopUpButton()
        stylePopup.addItems(withTitles: IconStyle.allCases.map(\.title))
        stylePopup.selectItem(at: IconStyle.allCases.firstIndex(of: Settings.shared.iconStyle) ?? 0)
        stylePopup.target = self
        stylePopup.action = #selector(styleChanged)
        stack.addArrangedSubview(row("Icon style:", stylePopup))

        dividerCheckbox = NSButton(checkboxWithTitle: "Show divider handle when items are visible",
                                   target: self, action: #selector(dividerChanged))
        dividerCheckbox.state = Settings.shared.showDivider ? .on : .off
        stack.addArrangedSubview(dividerCheckbox)

        stack.addArrangedSubview(header("General"))

        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch at login",
                                         target: self, action: #selector(launchAtLoginChanged))
        launchAtLoginCheckbox.state = SMAppService.mainApp.status == .enabled ? .on : .off
        stack.addArrangedSubview(launchAtLoginCheckbox)

        let tip = NSTextField(wrappingLabelWithString:
            "Hold \u{2318} first, then drag the divider so every item you want hidden sits to its left.")
        tip.font = .systemFont(ofSize: 11)
        tip.textColor = .secondaryLabelColor
        tip.preferredMaxLayoutWidth = 370
        stack.addArrangedSubview(tip)

        let content = NSView()
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: content.topAnchor),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor),
        ])
        window.contentView = content
    }

    private func header(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .boldSystemFont(ofSize: 12)
        label.textColor = .secondaryLabelColor
        return label
    }

    private func row(_ title: String, _ control: NSView) -> NSStackView {
        let label = NSTextField(labelWithString: title)
        let row = NSStackView(views: [label, control])
        row.orientation = .horizontal
        row.spacing = 10
        label.widthAnchor.constraint(equalToConstant: 110).isActive = true
        return row
    }

    @objc private func styleChanged() {
        Settings.shared.iconStyle = IconStyle.allCases[stylePopup.indexOfSelectedItem]
    }

    @objc private func dividerChanged() {
        Settings.shared.showDivider = dividerCheckbox.state == .on
    }

    @objc private func launchAtLoginChanged() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSAlert(error: error).runModal()
        }
        launchAtLoginCheckbox.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    func windowWillClose(_ notification: Notification) {
        recorder.stopRecording()
    }
}

/// Click, then press a shortcut. Captures keys locally while recording so the
/// keystroke doesn't leak to the rest of the app.
final class ShortcutRecorder: NSButton {
    private var monitor: Any?

    private var isRecording = false {
        didSet { updateTitle() }
    }

    init() {
        super.init(frame: .zero)
        bezelStyle = .rounded
        target = self
        action = #selector(startRecording)
        widthAnchor.constraint(equalToConstant: 140).isActive = true
        updateTitle()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) unused") }

    deinit { stopRecording() }

    private func updateTitle() {
        title = isRecording
            ? "Press keys\u{2026}"
            : describeHotkey(keyCode: Settings.shared.hotkeyKeyCode,
                             modifiers: Settings.shared.hotkeyModifiers)
    }

    @objc private func startRecording() {
        guard !isRecording else { return stopRecording() }
        isRecording = true

        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard let self, event.type == .keyDown else { return event }

            if event.keyCode == UInt16(kVK_Escape) {
                self.stopRecording()
                return nil
            }

            let carbon = ShortcutRecorder.carbonModifiers(from: event.modifierFlags)
            // Require at least one non-shift modifier; a bare key would swallow
            // normal typing system-wide.
            guard carbon & ~UInt32(shiftKey) != 0 else { return nil }

            Settings.shared.hotkeyKeyCode = UInt32(event.keyCode)
            Settings.shared.hotkeyModifiers = carbon
            self.stopRecording()
            return nil
        }
    }

    func stopRecording() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        isRecording = false
    }

    private static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.command) { result |= UInt32(cmdKey) }
        if flags.contains(.option) { result |= UInt32(optionKey) }
        if flags.contains(.control) { result |= UInt32(controlKey) }
        if flags.contains(.shift) { result |= UInt32(shiftKey) }
        return result
    }
}
