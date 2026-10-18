import Foundation

enum ClipboardItemKind: String, Codable {
    case text
    case image
}

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let kind: ClipboardItemKind
    let text: String?
    let imageData: Data?
    let timestamp: Date
    var isPinned: Bool
    var pinnedAt: Date?

    init(
        id: UUID = UUID(),
        kind: ClipboardItemKind,
        text: String? = nil,
        imageData: Data? = nil,
        timestamp: Date = Date(),
        isPinned: Bool = false,
        pinnedAt: Date? = nil
    ) {
        self.id = id
        self.kind = kind
        self.text = text
        self.imageData = imageData
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.pinnedAt = pinnedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        kind = try container.decode(ClipboardItemKind.self, forKey: .kind)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        pinnedAt = try container.decodeIfPresent(Date.self, forKey: .pinnedAt)
    }

    var preview: String {
        switch kind {
        case .text:
            let collapsed = (text ?? "").replacingOccurrences(of: "\n", with: " ")
            return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
        case .image:
            return "Image"
        }
    }
}
