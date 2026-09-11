import AppKit
import Carbon.HIToolbox

/// UserDefaults-backed settings. Small enough that a struct of computed
/// properties beats any framework.
final class Settings {
    static let shared = Settings()

    private let defaults = UserDefaults.standard
    static let didChange = Notification.Name("TuckSettingsDidChange")

    private enum Key {
        static let keyCode = "hotkeyKeyCode"
        static let modifiers = "hotkeyModifiers"
        static let iconStyle = "iconStyle"
        static let showDivider = "showDivider"
    }

    private init() {
        defaults.register(defaults: [
            Key.keyCode: Int(kVK_ANSI_B),
            Key.modifiers: Int(optionKey | cmdKey),
            Key.iconStyle: IconStyle.chevron.rawValue,
            Key.showDivider: true,
        ])
    }

    var hotkeyKeyCode: UInt32 {
        get { UInt32(defaults.integer(forKey: Key.keyCode)) }
        set { defaults.set(Int(newValue), forKey: Key.keyCode); notify() }
    }

    var hotkeyModifiers: UInt32 {
        get { UInt32(defaults.integer(forKey: Key.modifiers)) }
        set { defaults.set(Int(newValue), forKey: Key.modifiers); notify() }
    }

    var iconStyle: IconStyle {
        get { IconStyle(rawValue: defaults.string(forKey: Key.iconStyle) ?? "") ?? .chevron }
        set { defaults.set(newValue.rawValue, forKey: Key.iconStyle); notify() }
    }

    var showDivider: Bool {
        get { defaults.bool(forKey: Key.showDivider) }
        set { defaults.set(newValue, forKey: Key.showDivider); notify() }
    }

    private func notify() {
        NotificationCenter.default.post(name: Settings.didChange, object: nil)
    }
}

enum IconStyle: String, CaseIterable {
    case chevron, eye, circle

    var title: String {
        switch self {
        case .chevron: return "Chevron"
        case .eye: return "Eye"
        case .circle: return "Circle"
        }
    }

    /// (symbol, plain-text fallback) for each state.
    func symbols(hidden: Bool) -> (String, String) {
        switch self {
        case .chevron: return hidden ? ("chevron.right", "\u{203A}") : ("chevron.left", "\u{2039}")
        case .eye: return hidden ? ("eye.slash", "\u{25CB}") : ("eye", "\u{25C9}")
        case .circle: return hidden ? ("circle", "\u{25CB}") : ("circle.fill", "\u{25CF}")
        }
    }
}

/// Human-readable shortcut string, e.g. "\u{2325}\u{2318}B".
func describeHotkey(keyCode: UInt32, modifiers: UInt32) -> String {
    var parts = ""
    if modifiers & UInt32(controlKey) != 0 { parts += "\u{2303}" }
    if modifiers & UInt32(optionKey) != 0 { parts += "\u{2325}" }
    if modifiers & UInt32(shiftKey) != 0 { parts += "\u{21E7}" }
    if modifiers & UInt32(cmdKey) != 0 { parts += "\u{2318}" }
    return parts + keyName(keyCode)
}

func keyName(_ keyCode: UInt32) -> String {
    let names: [Int: String] = [
        kVK_ANSI_A: "A", kVK_ANSI_B: "B", kVK_ANSI_C: "C", kVK_ANSI_D: "D",
        kVK_ANSI_E: "E", kVK_ANSI_F: "F", kVK_ANSI_G: "G", kVK_ANSI_H: "H",
        kVK_ANSI_I: "I", kVK_ANSI_J: "J", kVK_ANSI_K: "K", kVK_ANSI_L: "L",
        kVK_ANSI_M: "M", kVK_ANSI_N: "N", kVK_ANSI_O: "O", kVK_ANSI_P: "P",
        kVK_ANSI_Q: "Q", kVK_ANSI_R: "R", kVK_ANSI_S: "S", kVK_ANSI_T: "T",
        kVK_ANSI_U: "U", kVK_ANSI_V: "V", kVK_ANSI_W: "W", kVK_ANSI_X: "X",
        kVK_ANSI_Y: "Y", kVK_ANSI_Z: "Z",
        kVK_ANSI_0: "0", kVK_ANSI_1: "1", kVK_ANSI_2: "2", kVK_ANSI_3: "3",
        kVK_ANSI_4: "4", kVK_ANSI_5: "5", kVK_ANSI_6: "6", kVK_ANSI_7: "7",
        kVK_ANSI_8: "8", kVK_ANSI_9: "9",
        kVK_Space: "Space", kVK_Return: "\u{21A9}", kVK_Escape: "\u{238B}",
        kVK_ANSI_Grave: "`", kVK_ANSI_Minus: "-", kVK_ANSI_Equal: "=",
        kVK_ANSI_LeftBracket: "[", kVK_ANSI_RightBracket: "]",    ]
    return names[Int(keyCode)] ?? "Key\(keyCode)"
}
