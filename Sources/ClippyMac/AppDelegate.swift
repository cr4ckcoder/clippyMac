import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let clipboardManager = ClipboardManager()
    private var statusBarController: StatusBarController?
    private var historyPanelController: HistoryPanelController?
    private var hotKeyManager: HotKeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        historyPanelController = HistoryPanelController(clipboardManager: clipboardManager) { item in
            PasteSimulator.simulatePaste()
        }

        statusBarController = StatusBarController(
            onShowHistory: { [weak self] in self?.historyPanelController?.toggle() },
            onClearHistory: { [weak self] in self?.clipboardManager.clearHistory() },
            onQuit: { NSApp.terminate(nil) }
        )

        hotKeyManager = HotKeyManager { [weak self] in
            self?.historyPanelController?.toggle()
        }
        if hotKeyManager == nil {
            NSLog("ClippyMac: failed to register the ⌘⇧V global hotkey.")
        }

        clipboardManager.startMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardManager.stopMonitoring()
    }
}
