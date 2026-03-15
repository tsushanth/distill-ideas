//
//  ReviewViewModel.swift
//  DistillIdeas
//
//  ViewModel for the spaced repetition review session
//

import Foundation
import SwiftData

@MainActor
@Observable
final class ReviewViewModel {
    // MARK: - State
    var isSessionActive: Bool = false
    var currentIdea: Idea?
    var sessionIdeas: [Idea] = []
    var currentIndex: Int = 0
    var completedCount: Int = 0
    var correctCount: Int = 0
    var sessionStartTime: Date = Date()
    var isFlipped: Bool = false
    var showQualityPicker: Bool = false
    var showSessionComplete: Bool = false
    var selectedQuality: ReviewQuality?
    var reviewStartTime: Date = Date()

    // MARK: - Computed

    var totalCount: Int { sessionIdeas.count }

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(currentIndex) / Double(totalCount)
    }

    var accuracy: Double {
        guard completedCount > 0 else { return 0 }
        return Double(correctCount) / Double(completedCount)
    }

    var sessionDuration: TimeInterval {
        Date().timeIntervalSince(sessionStartTime)
    }

    var sessionDurationLabel: String {
        let minutes = Int(sessionDuration) / 60
        let seconds = Int(sessionDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var isComplete: Bool {
        currentIndex >= totalCount && totalCount > 0
    }

    var dueCount: Int = 0

    // MARK: - Start Session

    func startSession(savedCards: [IdeaCard], ideas: [Idea]) {
        // Find ideas that are saved and due for review
        let savedIdeaIDs = Set(savedCards.map { $0.ideaID })
        let dueIdeas = ideas.filter { idea in
            savedIdeaIDs.contains(idea.id) &&
            (idea.isScheduledForReview || idea.reviewCount == 0)
        }

        guard !dueIdeas.isEmpty else {
            return
        }

        sessionIdeas = Array(dueIdeas.prefix(20))
        currentIndex = 0
        completedCount = 0
        correctCount = 0
        sessionStartTime = Date()
        isFlipped = false
        showSessionComplete = false
        isSessionActive = true
        advanceToNext()
    }

    private func advanceToNext() {
        guard currentIndex < sessionIdeas.count else {
            endSession()
            return
        }
        currentIdea = sessionIdeas[currentIndex]
        isFlipped = false
        showQualityPicker = false
        selectedQuality = nil
        reviewStartTime = Date()
    }

    // MARK: - Flip Card

    func flipCard() {
        isFlipped = true
        showQualityPicker = true
    }

    // MARK: - Rate Review

    func rateReview(_ quality: ReviewQuality) {
        guard let idea = currentIdea else { return }

        selectedQuality = quality
        let responseTime = Date().timeIntervalSince(reviewStartTime)

        // Apply spaced repetition
        SpacedRepetitionEngine.shared.applySpacedRepetition(to: idea, quality: quality)

        // Track stats
        if quality.rawValue >= 3 {
            correctCount += 1
        }
        completedCount += 1

        AnalyticsService.shared.track(.reviewItemRated(
            ideaID: idea.id.uuidString,
            quality: quality.rawValue
        ))

        // Advance
        currentIndex += 1

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.advanceToNext()
        }
    }

    // MARK: - End Session

    func endSession() {
        isSessionActive = false
        showSessionComplete = true

        AnalyticsService.shared.track(.reviewCompleted(
            sessionID: UUID().uuidString,
            count: completedCount,
            accuracy: accuracy
        ))

        ReviewManager.shared.recordSignificantEvent()
    }

    // MARK: - Due Count

    func updateDueCount(savedCards: [IdeaCard], ideas: [Idea]) {
        let savedIdeaIDs = Set(savedCards.map { $0.ideaID })
        dueCount = ideas.filter { idea in
            savedIdeaIDs.contains(idea.id) &&
            (idea.isScheduledForReview || idea.reviewCount == 0)
        }.count
    }

    // MARK: - Stats

    var sessionSummary: String {
        let pct = Int(accuracy * 100)
        return "\(completedCount) cards reviewed · \(pct)% accuracy · \(sessionDurationLabel)"
    }

    var motivationalMessage: String {
        switch accuracy {
        case 0.9...: return "Outstanding! Your knowledge is solid."
        case 0.7..<0.9: return "Great work! Keep building on this."
        case 0.5..<0.7: return "Good progress. Keep reviewing!"
        default: return "Keep going—practice makes permanent."
        }
    }
}
