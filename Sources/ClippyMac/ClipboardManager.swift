import AppKit
import Combine

final class ClipboardManager: ObservableObject {
    static let maxHistoryItems = 50
    private static let pollInterval: TimeInterval = 0.5

    @Published private(set) var history: [ClipboardItem] = []

    private var lastChangeCount: Int
    private var timer: Timer?
    private var isInternalWrite = false
    private let storageURL: URL

    var pinnedItems: [ClipboardItem] {
        history.filter(\.isPinned).sorted { ($0.pinnedAt ?? .distantPast) > ($1.pinnedAt ?? .distantPast) }
    }

    var recentItems: [ClipboardItem] {
        history.filter { !$0.isPinned }
    }

    init() {
        let pasteboard = NSPasteboard.general
        lastChangeCount = pasteboard.changeCount

        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ClippyMac", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        storageURL = dir.appendingPathComponent("history.json")

        loadHistory()
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            self?.pollPasteboard()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func pollPasteboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        if isInternalWrite {
            isInternalWrite = false
            return
        }

        if let string = pasteboard.string(forType: .string), !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addItem(ClipboardItem(kind: .text, text: string))
        } else if let imageData = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png) {
            addItem(ClipboardItem(kind: .image, imageData: imageData))
        }
    }

    private func addItem(_ item: ClipboardItem) {
        // Skip if this content is already the newest unpinned entry.
        if let firstUnpinned = history.first(where: { !$0.isPinned }),
           firstUnpinned.kind == item.kind,
           firstUnpinned.text == item.text,
           firstUnpinned.imageData == item.imageData {
            return
        }

        // Drop unpinned duplicates; leave any pinned copy in the shelf.
        history.removeAll {
            !$0.isPinned && $0.kind == item.kind && $0.text == item.text && $0.imageData == item.imageData
        }

        if history.contains(where: {
            $0.isPinned && $0.kind == item.kind && $0.text == item.text && $0.imageData == item.imageData
        }) {
            saveHistory()
            return
        }

        let insertIndex = history.firstIndex(where: { !$0.isPinned }) ?? history.count
        history.insert(item, at: insertIndex)
        trimHistory()
        saveHistory()
    }

    func togglePin(_ item: ClipboardItem) {
        guard let index = history.firstIndex(where: { $0.id == item.id }) else { return }
        var updated = history[index]
        updated.isPinned.toggle()
        updated.pinnedAt = updated.isPinned ? Date() : nil
        history[index] = updated
        resortHistory()
        saveHistory()
    }

    func copyToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        isInternalWrite = true
        pasteboard.clearContents()
        switch item.kind {
        case .text:
            pasteboard.setString(item.text ?? "", forType: .string)
        case .image:
            if let data = item.imageData {
                pasteboard.setData(data, forType: .tiff)
            }
        }
        lastChangeCount = pasteboard.changeCount
    }

    /// Clears unpinned history only; pinned items stay.
    func clearHistory() {
        history.removeAll { !$0.isPinned }
        saveHistory()
    }

    private func resortHistory() {
        let pinned = history.filter(\.isPinned).sorted {
            ($0.pinnedAt ?? .distantPast) > ($1.pinnedAt ?? .distantPast)
        }
        let recent = history.filter { !$0.isPinned }.sorted { $0.timestamp > $1.timestamp }
        history = pinned + recent
    }

    private func trimHistory() {
        let pinnedCount = history.filter(\.isPinned).count
        let maxUnpinned = max(0, Self.maxHistoryItems - pinnedCount)
        var unpinnedSeen = 0
        history = history.filter { item in
            if item.isPinned { return true }
            unpinnedSeen += 1
            return unpinnedSeen <= maxUnpinned
        }
    }

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(history) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }

    private func loadHistory() {
        guard let data = try? Data(contentsOf: storageURL),
              let items = try? JSONDecoder().decode([ClipboardItem].self, from: data) else { return }
        history = items
        resortHistory()
    }
}
