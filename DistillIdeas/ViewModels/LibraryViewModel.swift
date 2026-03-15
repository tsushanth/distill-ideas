//
//  LibraryViewModel.swift
//  DistillIdeas
//
//  ViewModel for the personal library of saved cards and collections
//

import Foundation
import SwiftData

@MainActor
@Observable
final class LibraryViewModel {
    // MARK: - State
    var searchQuery: String = ""
    var selectedCollection: IdeaCollection?
    var sortOption: SortOption = .dateAdded
    var showPaywall: Bool = false
    var showCreateCollection: Bool = false
    var newCollectionName: String = ""
    var newCollectionEmoji: String = "📚"
    var errorMessage: String?
    var successMessage: String?

    enum SortOption: String, CaseIterable {
        case dateAdded = "Date Added"
        case alphabetical = "Alphabetical"
        case category = "Category"
        case favorites = "Favorites First"
        case masteryLevel = "Mastery Level"
    }

    // MARK: - Filtered Cards

    func filteredCards(from cards: [IdeaCard]) -> [IdeaCard] {
        var result = cards

        if let collection = selectedCollection {
            result = result.filter { collection.cardIDs.contains($0.id) }
        }

        if !searchQuery.isEmpty {
            let lower = searchQuery.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(lower) ||
                $0.highlightedText.lowercased().contains(lower) ||
                $0.sourceName.lowercased().contains(lower) ||
                $0.authorName.lowercased().contains(lower) ||
                $0.tags.contains { $0.lowercased().contains(lower) }
            }
        }

        switch sortOption {
        case .dateAdded:
            result = result.sorted { $0.dateCreated > $1.dateCreated }
        case .alphabetical:
            result = result.sorted { $0.title < $1.title }
        case .category:
            result = result.sorted { $0.topicCategory < $1.topicCategory }
        case .favorites:
            result = result.sorted { $0.isFavorite && !$1.isFavorite }
        case .masteryLevel:
            break
        }

        return result
    }

    // MARK: - Save Card

    func saveCard(
        from idea: Idea,
        highlightedText: String = "",
        note: String = "",
        context: ModelContext,
        premiumManager: PremiumManager
    ) -> Bool {
        guard premiumManager.canSaveMoreCards() else {
            showPaywall = true
            return false
        }

        let text = highlightedText.isEmpty ? idea.content : highlightedText
        let card = IdeaCard(
            ideaID: idea.id,
            title: idea.title,
            highlightedText: text,
            userNote: note,
            topicCategory: idea.topicCategoryEnum,
            sourceName: idea.sourceName,
            authorName: idea.authorName,
            colorAccentHex: idea.topicCategoryEnum.colorHex
        )

        context.insert(card)
        idea.isSaved = true
        premiumManager.savedCardCount += 1

        AnalyticsService.shared.track(.cardCreated(cardID: card.id.uuidString))
        successMessage = "Idea saved to library!"
        return true
    }

    // MARK: - Delete Card

    func deleteCard(_ card: IdeaCard, context: ModelContext, premiumManager: PremiumManager) {
        context.delete(card)
        premiumManager.savedCardCount = max(0, premiumManager.savedCardCount - 1)
    }

    // MARK: - Toggle Favorite

    func toggleFavorite(_ card: IdeaCard) {
        card.isFavorite.toggle()
        card.dateModified = Date()
    }

    // MARK: - Create Collection

    func createCollection(context: ModelContext) {
        guard !newCollectionName.isEmpty else { return }

        let collection = IdeaCollection(
            name: newCollectionName,
            emoji: newCollectionEmoji,
            isSystemCollection: false,
            isPremiumCollection: false
        )

        context.insert(collection)
        newCollectionName = ""
        newCollectionEmoji = "📚"
        showCreateCollection = false
        successMessage = "Collection created!"
    }

    // MARK: - Add Card to Collection

    func addCard(_ card: IdeaCard, to collection: IdeaCollection) {
        guard !collection.cardIDs.contains(card.id) else { return }
        collection.cardIDs.append(card.id)
        if !card.collectionIDs.contains(collection.id) {
            card.collectionIDs.append(collection.id)
        }
        collection.dateModified = Date()
    }

    // MARK: - Share Card

    func shareText(for card: IdeaCard) -> String {
        var text = "\"\(card.highlightedText)\""
        if !card.authorName.isEmpty {
            text += "\n— \(card.authorName)"
        }
        if !card.sourceName.isEmpty {
            text += ", \(card.sourceName)"
        }
        text += "\n\nDistilled with Distill: Ideas That Stick"
        return text
    }
}
