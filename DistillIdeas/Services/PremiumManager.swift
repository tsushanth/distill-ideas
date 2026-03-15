//
//  PremiumManager.swift
//  DistillIdeas
//
//  Premium status management and paywall logic
//

import Foundation
import StoreKit

// MARK: - Premium Feature
enum PremiumFeature: String, CaseIterable {
    case unlimitedSaves = "unlimited_saves"
    case allTopics = "all_topics"
    case offlineAccess = "offline_access"
    case aiSummaries = "ai_summaries"
    case advancedReview = "advanced_review"
    case noAds = "no_ads"
    case exportCards = "export_cards"

    var title: String {
        switch self {
        case .unlimitedSaves: return "Unlimited Saves"
        case .allTopics: return "All Topic Collections"
        case .offlineAccess: return "Offline Access"
        case .aiSummaries: return "AI Summaries"
        case .advancedReview: return "Advanced Review Stats"
        case .noAds: return "No Ads"
        case .exportCards: return "Export Cards"
        }
    }

    var description: String {
        switch self {
        case .unlimitedSaves: return "Save as many ideas as you want"
        case .allTopics: return "Access all 10 topic categories"
        case .offlineAccess: return "Read and review without internet"
        case .aiSummaries: return "Get AI-powered summaries of ideas"
        case .advancedReview: return "Detailed retention analytics"
        case .noAds: return "Enjoy a completely ad-free experience"
        case .exportCards: return "Export your cards as images or PDF"
        }
    }

    var icon: String {
        switch self {
        case .unlimitedSaves: return "infinity"
        case .allTopics: return "square.grid.2x2.fill"
        case .offlineAccess: return "wifi.slash"
        case .aiSummaries: return "sparkles"
        case .advancedReview: return "chart.bar.fill"
        case .noAds: return "xmark.circle.fill"
        case .exportCards: return "square.and.arrow.up.fill"
        }
    }
}

// MARK: - Free Tier Limits
struct FreeTierLimits {
    static let maxSavedCards = 10
    static let maxTopics = 2
    static let freeTopics: [TopicCategory] = [.productivity, .psychology]
}

// MARK: - Premium Manager
@MainActor
@Observable
final class PremiumManager {
    var isPremium: Bool = false
    var savedCardCount: Int = 0
    var isLoading: Bool = false

    private let premiumKey = "com.appfactory.distillideas.isPremium"
    private let userDefaults = UserDefaults.standard

    init() {
        isPremium = userDefaults.bool(forKey: premiumKey)
    }

    func refreshPremiumStatus() async {
        isLoading = true
        var hasPurchase = false

        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result, tx.revocationDate == nil {
                hasPurchase = true
                break
            }
        }

        isPremium = hasPurchase
        userDefaults.set(isPremium, forKey: premiumKey)
        isLoading = false
    }

    func setPremium(_ value: Bool) {
        isPremium = value
        userDefaults.set(value, forKey: premiumKey)
    }

    // MARK: - Feature Gating

    func canSaveMoreCards() -> Bool {
        isPremium || savedCardCount < FreeTierLimits.maxSavedCards
    }

    func canAccessCategory(_ category: TopicCategory) -> Bool {
        isPremium || FreeTierLimits.freeTopics.contains(category)
    }

    func canAccessFeature(_ feature: PremiumFeature) -> Bool {
        isPremium
    }

    var savedCardsRemaining: Int {
        max(0, FreeTierLimits.maxSavedCards - savedCardCount)
    }

    var saveLimitLabel: String {
        "\(savedCardCount)/\(FreeTierLimits.maxSavedCards) ideas saved"
    }

    // MARK: - Paywall Source Tracking

    enum PaywallSource: String {
        case saveIdea = "save_idea"
        case premiumTopic = "premium_topic"
        case aiSummary = "ai_summary"
        case offlineAccess = "offline_access"
        case settings = "settings"
        case onboarding = "onboarding"
        case saveLimit = "save_limit"
    }
}
