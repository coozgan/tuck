import AppKit
import Carbon.HIToolbox

/// Minimal global hotkey via Carbon. Works without Accessibility permission.
final class Hotkey {
    struct Modifiers: OptionSet {
        let rawValue: UInt32
        static let command = Modifiers(rawValue: UInt32(cmdKey))
        static let option = Modifiers(rawValue: UInt32(optionKey))
        static let control = Modifiers(rawValue: UInt32(controlKey))
        static let shift = Modifiers(rawValue: UInt32(shiftKey))
    }

    private static var handlers: [UInt32: () -> Void] = [:]
    private static var nextID: UInt32 = 1
    private static var eventHandler: EventHandlerRef?

    private var ref: EventHotKeyRef?
    private let id: UInt32

    init?(keyCode: UInt32, modifiers: Modifiers, action: @escaping () -> Void) {
        Hotkey.installEventHandlerIfNeeded()

        id = Hotkey.nextID
        Hotkey.nextID += 1

        let hotKeyID = EventHotKeyID(signature: OSType(0x54_55_43_4B), id: id) // 'TUCK'
        let status = RegisterEventHotKey(keyCode, modifiers.rawValue, hotKeyID, GetEventDispatcherTarget(), 0, &ref)
        guard status == noErr else { return nil }

        Hotkey.handlers[id] = action
    }

    deinit {
        Hotkey.handlers[id] = nil
        if let ref { UnregisterEventHotKey(ref) }
    }

    private static func installEventHandlerIfNeeded() {
        guard eventHandler == nil else { return }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetEventDispatcherTarget(), { _, event, _ -> OSStatus in
            var id = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject),
                                           EventParamType(typeEventHotKeyID), nil,
                                           MemoryLayout<EventHotKeyID>.size, nil, &id)
            guard status == noErr, let action = Hotkey.handlers[id.id] else { return status }
            DispatchQueue.main.async(execute: action)
            return noErr
        }, 1, &spec, nil, &eventHandler)
    }
}
