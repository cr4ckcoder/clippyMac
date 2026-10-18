import AppKit
import SwiftUI

/// Owns the floating, non-activating panel that shows clipboard history near the
/// cursor, mirroring the popup behavior of Windows' Win+V clipboard history.
final class HistoryPanelController: NSObject {
    private let panel: KeyablePanel
    private let clipboardManager: ClipboardManager
    private var previousApp: NSRunningApplication?

    init(clipboardManager: ClipboardManager, onSelect: @escaping (ClipboardItem) -> Void) {
        self.clipboardManager = clipboardManager

        let panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 440),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.level = .popUpMenu
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        self.panel = panel

        super.init()

        let view = HistoryView(
            clipboardManager: clipboardManager,
            onSelect: { [weak self] item in
                self?.select(item, onSelect: onSelect)
            },
            onClear: {
                clipboardManager.clearHistory()
            }
        )
        panel.contentView = NSHostingView(rootView: view)
        panel.onEscape = { [weak self] in self?.hide() }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(panelResignedKey),
            name: NSWindow.didResignKeyNotification,
            object: panel
        )
    }

    func toggle() {
        if panel.isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        previousApp = NSWorkspace.shared.frontmostApplication
        positionNearMouse()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        panel.orderOut(nil)
    }

    @objc private func panelResignedKey() {
        hide()
    }

    private func positionNearMouse() {
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }) ?? NSScreen.main else { return }
        let mouseLocation = NSEvent.mouseLocation
        var origin = NSPoint(x: mouseLocation.x - panel.frame.width / 2, y: mouseLocation.y - panel.frame.height - 12)

        let visibleFrame = screen.visibleFrame
        origin.x = max(visibleFrame.minX, min(origin.x, visibleFrame.maxX - panel.frame.width))
        origin.y = max(visibleFrame.minY, min(origin.y, visibleFrame.maxY - panel.frame.height))

        panel.setFrameOrigin(origin)
    }

    private func select(_ item: ClipboardItem, onSelect: @escaping (ClipboardItem) -> Void) {
        hide()
        clipboardManager.copyToPasteboard(item)
        previousApp?.activate(options: [.activateIgnoringOtherApps])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onSelect(item)
        }
    }
}

/// A borderless NSPanel that can still become key (needed to receive keyboard input
/// and close on Escape) despite using the .nonactivatingPanel style mask.
final class KeyablePanel: NSPanel {
    var onEscape: (() -> Void)?

    override var canBecomeKey: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            onEscape?()
        } else {
            super.keyDown(with: event)
        }
    }
}
