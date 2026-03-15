//
//  FeedViewModel.swift
//  DistillIdeas
//
//  ViewModel for the main idea feed
//

import Foundation
import SwiftData

@MainActor
@Observable
final class FeedViewModel {
    // MARK: - State
    var ideas: [Idea] = []
    var featuredIdea: Idea?
    var selectedCategory: TopicCategory?
    var searchQuery: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var showPaywall: Bool = false
    var paywallSource: String = ""

    // MARK: - Filtered Ideas
    var filteredIdeas: [Idea] {
        var result = ideas

        if let category = selectedCategory {
            result = result.filter { $0.topicCategoryEnum == category }
        }

        if !searchQuery.isEmpty {
            let lower = searchQuery.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(lower) ||
                $0.content.lowercased().contains(lower) ||
                $0.authorName.lowercased().contains(lower) ||
                $0.sourceName.lowercased().contains(lower)
            }
        }

        return result
    }

    var isSearching: Bool {
        !searchQuery.isEmpty
    }

    // MARK: - Load

    func loadFeed(premiumManager: PremiumManager) async {
        isLoading = true

        await ContentService.shared.loadDailyFeed()

        var rawIdeas = ContentService.shared.dailyIdeas
        if !premiumManager.isPremium {
            rawIdeas = rawIdeas.filter {
                !$0.isPremiumContent || FreeTierLimits.freeTopics.contains($0.topicCategoryEnum)
            }
        }

        ideas = rawIdeas
        featuredIdea = ContentService.shared.featuredIdea

        AnalyticsService.shared.track(.appOpen)
        isLoading = false
    }

    func refreshFeed(premiumManager: PremiumManager) async {
        await loadFeed(premiumManager: premiumManager)
    }

    // MARK: - Category Filtering

    func selectCategory(_ category: TopicCategory?, premiumManager: PremiumManager) {
        if let cat = category, cat.isPremium, !premiumManager.isPremium {
            paywallSource = PremiumManager.PaywallSource.premiumTopic.rawValue
            showPaywall = true
            return
        }

        selectedCategory = category
        if let cat = category {
            AnalyticsService.shared.track(.collectionOpened(collectionName: cat.rawValue))
        }
    }

    // MARK: - Mark as Viewed

    func markViewed(_ idea: Idea) {
        idea.viewCount += 1
        AnalyticsService.shared.track(.ideaViewed(ideaID: idea.id.uuidString, category: idea.topicCategory))
    }

    // MARK: - Search

    func performSearch(_ query: String) {
        searchQuery = query
        if !query.isEmpty {
            AnalyticsService.shared.track(.searchPerformed(query: query))
        }
    }

    func clearSearch() {
        searchQuery = ""
        selectedCategory = nil
    }
}
