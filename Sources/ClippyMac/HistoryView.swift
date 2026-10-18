import AppKit
import SwiftUI

/// Soft corkboard-tray palette: paper surfaces, graphite type, amber pin accent.
private enum ClipTheme {
    static let pin = Color(red: 0.78, green: 0.52, blue: 0.22) // cork-warm amber
    static let pinSoft = Color(red: 0.78, green: 0.52, blue: 0.22).opacity(0.14)
    static let ink = Color.primary
    static let graphite = Color.secondary
    static let mute = Color.secondary.opacity(0.7)
    static let iconWell = Color.primary.opacity(0.05)
    static let hairline = Color.primary.opacity(0.08)
    static let radiusRow: CGFloat = 8
    static let radiusThumb: CGFloat = 5
}

struct HistoryView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    let onSelect: (ClipboardItem) -> Void
    let onClear: () -> Void

    private var pinned: [ClipboardItem] { clipboardManager.pinnedItems }
    private var recent: [ClipboardItem] { clipboardManager.recentItems }
    private var isEmpty: Bool { clipboardManager.history.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle()
                .fill(ClipTheme.hairline)
                .frame(height: 1)

            if isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        if !pinned.isEmpty {
                            sectionLabel("Pinned")
                            ForEach(pinned) { item in
                                HistoryRow(
                                    item: item,
                                    onSelect: { onSelect(item) },
                                    onTogglePin: { clipboardManager.togglePin(item) }
                                )
                            }
                        }

                        if !recent.isEmpty {
                            sectionLabel("Recent")
                            ForEach(recent) { item in
                                HistoryRow(
                                    item: item,
                                    onSelect: { onSelect(item) },
                                    onTogglePin: { clipboardManager.togglePin(item) }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
            }
        }
        .frame(width: 380, height: 440)
        .background(.regularMaterial)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(ClipTheme.graphite)
            Text("Clipboard")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(ClipTheme.ink)
            Spacer(minLength: 0)
            if !recent.isEmpty {
                Button(action: onClear) {
                    Text("Clear")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(ClipTheme.graphite)
                }
                .buttonStyle(.plain)
                .help("Clear recent history (pins stay)")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(ClipTheme.iconWell)
                    .frame(width: 48, height: 48)
                Image(systemName: "pin.slash")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(ClipTheme.mute)
            }
            Text("Nothing copied yet")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(ClipTheme.ink)
            Text("Copy text or an image and it will show up here.\nPin important copies so they stay on top.")
                .font(.system(size: 11))
                .foregroundStyle(ClipTheme.mute)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(28)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(ClipTheme.mute)
            .padding(.horizontal, 6)
            .padding(.top, 4)
            .padding(.bottom, 2)
    }
}

private struct HistoryRow: View {
    let item: ClipboardItem
    let onSelect: () -> Void
    let onTogglePin: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onSelect) {
                HStack(spacing: 10) {
                    thumbnail
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.preview.isEmpty ? "Empty" : item.preview)
                            .lineLimit(2)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(ClipTheme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(item.timestamp, style: .relative)
                            .font(.system(size: 10.5))
                            .foregroundStyle(ClipTheme.mute)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            pinButton
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: ClipTheme.radiusRow, style: .continuous)
                .fill(item.isPinned ? ClipTheme.pinSoft : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ClipTheme.radiusRow, style: .continuous)
                .strokeBorder(item.isPinned ? ClipTheme.pin.opacity(0.22) : Color.clear, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: ClipTheme.radiusRow, style: .continuous))
    }

    private var pinButton: some View {
        Button(action: onTogglePin) {
            Image(systemName: item.isPinned ? "pin.fill" : "pin")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(item.isPinned ? ClipTheme.pin : ClipTheme.graphite)
                .frame(width: 26, height: 26)
                .background(
                    Circle()
                        .fill(item.isPinned ? ClipTheme.pinSoft : ClipTheme.iconWell)
                )
        }
        .buttonStyle(.plain)
        .help(item.isPinned ? "Unpin" : "Pin to top")
    }

    @ViewBuilder
    private var thumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: ClipTheme.radiusThumb, style: .continuous)
                .fill(ClipTheme.iconWell)
                .frame(width: 32, height: 32)

            switch item.kind {
            case .text:
                Image(systemName: "text.alignleft")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ClipTheme.graphite)
            case .image:
                if let data = item.imageData, let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: ClipTheme.radiusThumb, style: .continuous))
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(ClipTheme.graphite)
                }
            }
        }
    }
}
