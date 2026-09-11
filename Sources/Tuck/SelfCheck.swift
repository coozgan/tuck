import Foundation
import Carbon.HIToolbox

/// Assert-based check for the logic that isn't obvious by reading it.
/// Run with: swift run Tuck --self-check
func selfCheck() {
    assert(describeHotkey(keyCode: UInt32(kVK_ANSI_B), modifiers: UInt32(optionKey | cmdKey)) == "\u{2325}\u{2318}B",
           "default shortcut should render as \u{2325}\u{2318}B")
    assert(describeHotkey(keyCode: UInt32(kVK_ANSI_H), modifiers: UInt32(controlKey | shiftKey)) == "\u{2303}\u{21E7}H",
           "modifier order should be \u{2303}\u{2325}\u{21E7}\u{2318}")

    // Every style must produce distinct icons per state, or the control gives
    // no feedback about whether items are hidden.
    for style in IconStyle.allCases {
        let shown = style.symbols(hidden: false)
        let hidden = style.symbols(hidden: true)
        assert(shown != hidden, "\(style.title): hidden and shown icons must differ")
        assert(!shown.1.isEmpty && !hidden.1.isEmpty, "\(style.title): fallback text must be non-empty")
    }

    // Round-trip through UserDefaults.
    let original = Settings.shared.iconStyle
    for style in IconStyle.allCases {
        Settings.shared.iconStyle = style
        assert(Settings.shared.iconStyle == style, "iconStyle should persist")
    }
    Settings.shared.iconStyle = original

    print("self-check passed")
}
