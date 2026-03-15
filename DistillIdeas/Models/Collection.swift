//
//  Collection.swift
//  DistillIdeas
//
//  Topic collection for organizing saved ideas
//

import Foundation
import SwiftData

// MARK: - Collection Model
@Model
final class IdeaCollection {
    var id: UUID
    var name: String
    var collectionDescription: String
    var topicCategory: String
    var colorHex: String
    var emoji: String
    var isSystemCollection: Bool
    var isPremiumCollection: Bool
    var cardIDs: [UUID]
    var dateCreated: Date
    var dateModified: Date
    var sortOrder: Int
    var isFavorite: Bool
    var coverImageURLString: String?

    init(
        id: UUID = UUID(),
        name: String,
        collectionDescription: String = "",
        topicCategory: TopicCategory = .productivity,
        colorHex: String = "#7B61FF",
        emoji: String = "📚",
        isSystemCollection: Bool = false,
        isPremiumCollection: Bool = false,
        cardIDs: [UUID] = [],
        sortOrder: Int = 0,
        isFavorite: Bool = false,
        coverImageURLString: String? = nil
    ) {
        self.id = id
        self.name = name
        self.collectionDescription = collectionDescription
        self.topicCategory = topicCategory.rawValue
        self.colorHex = colorHex
        self.emoji = emoji
        self.isSystemCollection = isSystemCollection
        self.isPremiumCollection = isPremiumCollection
        self.cardIDs = cardIDs
        self.dateCreated = Date()
        self.dateModified = Date()
        self.sortOrder = sortOrder
        self.isFavorite = isFavorite
        self.coverImageURLString = coverImageURLString
    }

    // MARK: - Computed

    var topicCategoryEnum: TopicCategory {
        TopicCategory(rawValue: topicCategory) ?? .productivity
    }

    var cardCount: Int {
        cardIDs.count
    }

    var cardCountLabel: String {
        cardCount == 1 ? "1 idea" : "\(cardCount) ideas"
    }

    // MARK: - Default Collections

    static var defaultCollections: [IdeaCollection] {
        [
            IdeaCollection(
                name: "Psychology",
                collectionDescription: "Understanding the human mind",
                topicCategory: .psychology,
                colorHex: "#7B61FF",
                emoji: "🧠",
                isSystemCollection: true,
                isPremiumCollection: false,
                sortOrder: 0
            ),
            IdeaCollection(
                name: "Productivity",
                collectionDescription: "Work smarter, not harder",
                topicCategory: .productivity,
                colorHex: "#FF9500",
                emoji: "⚡",
                isSystemCollection: true,
                isPremiumCollection: false,
                sortOrder: 1
            ),
            IdeaCollection(
                name: "Science",
                collectionDescription: "Fascinating discoveries",
                topicCategory: .science,
                colorHex: "#34C759",
                emoji: "🔬",
                isSystemCollection: true,
                isPremiumCollection: true,
                sortOrder: 2
            ),
            IdeaCollection(
                name: "Philosophy",
                collectionDescription: "Deep wisdom for modern life",
                topicCategory: .philosophy,
                colorHex: "#5AC8FA",
                emoji: "💭",
                isSystemCollection: true,
                isPremiumCollection: true,
                sortOrder: 3
            ),
            IdeaCollection(
                name: "Business",
                collectionDescription: "Insights from business leaders",
                topicCategory: .business,
                colorHex: "#FF3B30",
                emoji: "💼",
                isSystemCollection: true,
                isPremiumCollection: true,
                sortOrder: 4
            ),
            IdeaCollection(
                name: "Health & Wellness",
                collectionDescription: "Science-backed wellbeing tips",
                topicCategory: .health,
                colorHex: "#30D158",
                emoji: "🌿",
                isSystemCollection: true,
                isPremiumCollection: true,
                sortOrder: 5
            ),
        ]
    }
}
