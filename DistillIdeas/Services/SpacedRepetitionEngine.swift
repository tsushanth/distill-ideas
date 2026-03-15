//
//  SpacedRepetitionEngine.swift
//  DistillIdeas
//
//  Engine that drives the spaced repetition review system
//

import Foundation
import SwiftData

// MARK: - Review Session
struct ReviewSession {
    let id: UUID
    let ideas: [Idea]
    var currentIndex: Int
    var completedCount: Int
    var correctCount: Int
    var startTime: Date
    let totalCount: Int

    init(ideas: [Idea]) {
        self.id = UUID()
        self.ideas = ideas
        self.currentIndex = 0
        self.completedCount = 0
        self.correctCount = 0
        self.startTime = Date()
        self.totalCount = ideas.count
    }

    var currentIdea: Idea? {
        guard currentIndex < ideas.count else { return nil }
        return ideas[currentIndex]
    }

    var isComplete: Bool {
        currentIndex >= ideas.count
    }

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var accuracy: Double {
        guard completedCount > 0 else { return 0 }
        return Double(correctCount) / Double(completedCount)
    }

    var sessionDuration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
}

// MARK: - Spaced Repetition Engine
@MainActor
@Observable
final class SpacedRepetitionEngine {
    static let shared = SpacedRepetitionEngine()

    private(set) var currentSession: ReviewSession?
    private(set) var dueCount: Int = 0
    private(set) var isSessionActive: Bool = false

    private init() {}

    // MARK: - Session Management

    func startSession(with ideas: [Idea]) {
        let dueIdeas = ideas.filter { $0.isScheduledForReview || $0.reviewCount == 0 }
        let sessionIdeas = Array(dueIdeas.prefix(20)) // Max 20 per session

        if sessionIdeas.isEmpty {
            return
        }

        currentSession = ReviewSession(ideas: sessionIdeas)
        isSessionActive = true
    }

    func processReview(idea: Idea, quality: ReviewQuality) {
        guard var session = currentSession else { return }

        // Apply SM-2 algorithm to the idea
        applySpacedRepetition(to: idea, quality: quality)

        // Track correct answers
        if quality.rawValue >= 3 {
            session.correctCount += 1
        }
        session.completedCount += 1
        session.currentIndex += 1

        if session.isComplete {
            isSessionActive = false
        }

        currentSession = session
    }

    func endSession() {
        isSessionActive = false
        currentSession = nil
    }

    // MARK: - SM-2 Algorithm

    func applySpacedRepetition(to idea: Idea, quality: ReviewQuality) {
        let q = quality.rawValue
        let oldEaseFactor = idea.easeFactor

        // Update ease factor
        let newEaseFactor = idea.easeFactor + (0.1 - Double(5 - q) * (0.08 + Double(5 - q) * 0.02))
        idea.easeFactor = max(1.3, newEaseFactor)

        idea.reviewCount += 1
        idea.lastReviewDate = Date()
        idea.dateModified = Date()

        if q < 3 {
            // Failed recall - reset
            idea.reviewInterval = 1
        } else {
            switch idea.reviewCount {
            case 1:
                idea.reviewInterval = 1
            case 2:
                idea.reviewInterval = 6
            default:
                idea.reviewInterval = Int(Double(idea.reviewInterval) * oldEaseFactor)
            }
        }

        idea.reviewInterval = min(idea.reviewInterval, 180)
        idea.nextReviewDate = Calendar.current.date(
            byAdding: .day,
            value: idea.reviewInterval,
            to: Date()
        )

        // Update mastery
        updateMastery(for: idea, quality: quality)
    }

    private func updateMastery(for idea: Idea, quality: ReviewQuality) {
        if quality.rawValue >= 4 {
            idea.masteryLevel = min(5, idea.masteryLevel + 1)
        } else if quality.rawValue < 3 {
            idea.masteryLevel = max(0, idea.masteryLevel - 1)
        }
    }

    // MARK: - Due Count

    func updateDueCount(from ideas: [Idea]) {
        dueCount = ideas.filter { $0.isScheduledForReview || $0.reviewCount == 0 }.count
    }

    // MARK: - Statistics

    func retentionRate(from ideas: [Idea]) -> Double {
        let reviewed = ideas.filter { $0.reviewCount > 0 }
        guard !reviewed.isEmpty else { return 0 }
        let mastered = reviewed.filter { $0.masteryLevel >= 3 }
        return Double(mastered.count) / Double(reviewed.count)
    }

    func averageMastery(from ideas: [Idea]) -> Double {
        guard !ideas.isEmpty else { return 0 }
        let total = ideas.reduce(0) { $0 + $1.masteryLevel }
        return Double(total) / Double(ideas.count)
    }
}
