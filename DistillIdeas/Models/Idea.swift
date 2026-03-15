//
//  Idea.swift
//  DistillIdeas
//
//  Core Idea model representing a bite-sized lesson or insight
//

import Foundation
import SwiftData

// MARK: - Topic Category
enum TopicCategory: String, Codable, CaseIterable {
    case psychology = "Psychology"
    case productivity = "Productivity"
    case science = "Science"
    case philosophy = "Philosophy"
    case business = "Business"
    case health = "Health"
    case technology = "Technology"
    case creativity = "Creativity"
    case relationships = "Relationships"
    case finance = "Finance"

    var emoji: String {
        switch self {
        case .psychology: return "🧠"
        case .productivity: return "⚡"
        case .science: return "🔬"
        case .philosophy: return "💭"
        case .business: return "💼"
        case .health: return "🌿"
        case .technology: return "💻"
        case .creativity: return "🎨"
        case .relationships: return "❤️"
        case .finance: return "💰"
        }
    }

    var colorHex: String {
        switch self {
        case .psychology: return "#7B61FF"
        case .productivity: return "#FF9500"
        case .science: return "#34C759"
        case .philosophy: return "#5AC8FA"
        case .business: return "#FF3B30"
        case .health: return "#30D158"
        case .technology: return "#0A84FF"
        case .creativity: return "#FF6B6B"
        case .relationships: return "#FF2D55"
        case .finance: return "#FFD60A"
        }
    }

    var isPremium: Bool {
        switch self {
        case .psychology, .productivity: return false
        default: return true
        }
    }
}

// MARK: - Source Type
enum SourceType: String, Codable, CaseIterable {
    case book = "Book"
    case article = "Article"
    case podcast = "Podcast"
    case video = "Video"
    case research = "Research"
    case quote = "Quote"

    var icon: String {
        switch self {
        case .book: return "book.fill"
        case .article: return "doc.text.fill"
        case .podcast: return "mic.fill"
        case .video: return "play.rectangle.fill"
        case .research: return "chart.bar.doc.horizontal.fill"
        case .quote: return "quote.bubble.fill"
        }
    }
}

// MARK: - Idea Model
@Model
final class Idea {
    var id: UUID
    var title: String
    var content: String
    var summary: String
    var authorName: String
    var sourceName: String
    var sourceType: String
    var topicCategory: String
    var tags: [String]
    var readingTimeSeconds: Int
    var isBookmarked: Bool
    var isSaved: Bool
    var dateCreated: Date
    var dateModified: Date
    var viewCount: Int
    var likeCount: Int
    var shareCount: Int
    var isFeatured: Bool
    var isPremiumContent: Bool
    var imageURLString: String?
    var sourceURLString: String?

    // Spaced repetition fields
    var nextReviewDate: Date?
    var reviewInterval: Int // days
    var easeFactor: Double
    var reviewCount: Int
    var lastReviewDate: Date?
    var masteryLevel: Int // 0-5

    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        summary: String = "",
        authorName: String = "",
        sourceName: String = "",
        sourceType: SourceType = .article,
        topicCategory: TopicCategory = .productivity,
        tags: [String] = [],
        readingTimeSeconds: Int = 60,
        isBookmarked: Bool = false,
        isSaved: Bool = false,
        isFeatured: Bool = false,
        isPremiumContent: Bool = false,
        imageURLString: String? = nil,
        sourceURLString: String? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.summary = summary.isEmpty ? String(content.prefix(120)) + "..." : summary
        self.authorName = authorName
        self.sourceName = sourceName
        self.sourceType = sourceType.rawValue
        self.topicCategory = topicCategory.rawValue
        self.tags = tags
        self.readingTimeSeconds = readingTimeSeconds
        self.isBookmarked = isBookmarked
        self.isSaved = isSaved
        self.dateCreated = Date()
        self.dateModified = Date()
        self.viewCount = 0
        self.likeCount = 0
        self.shareCount = 0
        self.isFeatured = isFeatured
        self.isPremiumContent = isPremiumContent
        self.imageURLString = imageURLString
        self.sourceURLString = sourceURLString
        self.nextReviewDate = nil
        self.reviewInterval = 1
        self.easeFactor = 2.5
        self.reviewCount = 0
        self.lastReviewDate = nil
        self.masteryLevel = 0
    }

    // MARK: - Computed Properties

    var topicCategoryEnum: TopicCategory {
        TopicCategory(rawValue: topicCategory) ?? .productivity
    }

    var sourceTypeEnum: SourceType {
        SourceType(rawValue: sourceType) ?? .article
    }

    var readingTimeLabel: String {
        let minutes = readingTimeSeconds / 60
        let seconds = readingTimeSeconds % 60
        if minutes == 0 {
            return "\(seconds)s read"
        } else if seconds == 0 {
            return "\(minutes)m read"
        } else {
            return "\(minutes)m \(seconds)s read"
        }
    }

    var isScheduledForReview: Bool {
        guard let nextDate = nextReviewDate else { return false }
        return nextDate <= Date()
    }

    var masteryLabel: String {
        switch masteryLevel {
        case 0: return "New"
        case 1: return "Learning"
        case 2: return "Familiar"
        case 3: return "Proficient"
        case 4: return "Advanced"
        case 5: return "Mastered"
        default: return "New"
        }
    }
}
