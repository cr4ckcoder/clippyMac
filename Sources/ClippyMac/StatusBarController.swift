import AppKit

final class StatusBarController {
    private let statusItem: NSStatusItem
    private let onShowHistory: () -> Void
    private let onClearHistory: () -> Void
    private let onQuit: () -> Void

    init(onShowHistory: @escaping () -> Void, onClearHistory: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.onShowHistory = onShowHistory
        self.onClearHistory = onClearHistory
        self.onQuit = onQuit

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "ClippyMac")
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "Show History (⌘⇧V)", action: #selector(showHistory), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Clear Recent History", action: #selector(clearHistory), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit ClippyMac", action: #selector(quit), keyEquivalent: "q").target = self
        statusItem.menu = menu
    }

    @objc private func showHistory() {
        onShowHistory()
    }

    @objc private func clearHistory() {
        onClearHistory()
    }

    @objc private func quit() {
        onQuit()
    }
}
