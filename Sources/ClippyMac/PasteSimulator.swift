import AppKit
import Carbon.HIToolbox

enum PasteSimulator {
    /// Posts a synthetic Cmd+V to the frontmost application. Requires Accessibility
    /// permission (System Settings > Privacy & Security > Accessibility).
    static func simulatePaste() {
        guard AXIsProcessTrusted() else {
            promptForAccessibilityAccess()
            return
        }

        let source = CGEventSource(stateID: .hidSystemState)
        let keyCode = CGKeyCode(kVK_ANSI_V)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            return
        }
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    static func promptForAccessibilityAccess() {
        let options: [String: Any] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
