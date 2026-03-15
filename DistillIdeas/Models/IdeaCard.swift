//
//  IdeaCard.swift
//  DistillIdeas
//
//  User-saved insight cards for personal library
//

import Foundation
import SwiftData

// MARK: - Card Style
enum CardStyle: String, Codable, CaseIterable {
    case minimal = "Minimal"
    case bold = "Bold"
    case gradient = "Gradient"
    case classic = "Classic"

    var backgroundColorHex: String {
        switch self {
        case .minimal: return "#FFFFFF"
        case .bold: return "#1C1C1E"
        case .gradient: return "#7B61FF"
        case .classic: return "#FFF9E6"
        }
    }
}

// MARK: - IdeaCard Model
@Model
final class IdeaCard {
    var id: UUID
    var ideaID: UUID
    var title: String
    var highlightedText: String
    var userNote: String
    var cardStyle: String
    var topicCategory: String
    var sourceName: String
    var authorName: String
    var dateCreated: Date
    var dateModified: Date
    var isFavorite: Bool
    var tags: [String]
    var collectionIDs: [UUID]
    var shareCount: Int
    var colorAccentHex: String

    init(
        id: UUID = UUID(),
        ideaID: UUID,
        title: String,
        highlightedText: String,
        userNote: String = "",
        cardStyle: CardStyle = .minimal,
        topicCategory: TopicCategory = .productivity,
        sourceName: String = "",
        authorName: String = "",
        isFavorite: Bool = false,
        tags: [String] = [],
        collectionIDs: [UUID] = [],
        colorAccentHex: String = "#7B61FF"
    ) {
        self.id = id
        self.ideaID = ideaID
        self.title = title
        self.highlightedText = highlightedText
        self.userNote = userNote
        self.cardStyle = cardStyle.rawValue
        self.topicCategory = topicCategory.rawValue
        self.sourceName = sourceName
        self.authorName = authorName
        self.dateCreated = Date()
        self.dateModified = Date()
        self.isFavorite = isFavorite
        self.tags = tags
        self.collectionIDs = collectionIDs
        self.shareCount = 0
        self.colorAccentHex = colorAccentHex
    }

    // MARK: - Computed

    var cardStyleEnum: CardStyle {
        CardStyle(rawValue: cardStyle) ?? .minimal
    }

    var topicCategoryEnum: TopicCategory {
        TopicCategory(rawValue: topicCategory) ?? .productivity
    }

    var previewText: String {
        let maxLength = 100
        if highlightedText.count > maxLength {
            return String(highlightedText.prefix(maxLength)) + "..."
        }
        return highlightedText
    }
}
