import Carbon.HIToolbox
import AppKit

/// Registers a system-wide hotkey (default: Cmd+Shift+V) using the Carbon Event Manager,
/// since it works without requiring Accessibility/Input Monitoring permission.
final class HotKeyManager {
    private static var registry: [UInt32: HotKeyManager] = [:]
    private static var nextID: UInt32 = 1

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    fileprivate let hotKeyID: EventHotKeyID
    fileprivate let onTrigger: () -> Void

    init?(keyCode: UInt32 = UInt32(kVK_ANSI_V), modifiers: UInt32 = UInt32(cmdKey | shiftKey), onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger
        let id = Self.nextID
        Self.nextID += 1
        self.hotKeyID = EventHotKeyID(signature: OSType(0x434C_5056), id: id) // 'CLPV'

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyCEventHandler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
        guard installStatus == noErr else { return nil }

        Self.registry[id] = self

        let registerStatus = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        guard registerStatus == noErr else {
            Self.registry[id] = nil
            return nil
        }
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
        Self.registry[hotKeyID.id] = nil
    }

    fileprivate static func manager(forID id: UInt32) -> HotKeyManager? {
        registry[id]
    }
}

/// Non-capturing C callback required by Carbon's InstallEventHandler; dispatches back
/// to the owning HotKeyManager instance via the userData pointer.
private let hotKeyCEventHandler: EventHandlerUPP = { _, eventRef, userData in
    guard let eventRef, let userData else { return noErr }

    var hkID = EventHotKeyID()
    let status = GetEventParameter(
        eventRef,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hkID
    )
    guard status == noErr else { return status }

    let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
    if manager.hotKeyID.id == hkID.id {
        DispatchQueue.main.async {
            manager.onTrigger()
        }
    }
    return noErr
}
