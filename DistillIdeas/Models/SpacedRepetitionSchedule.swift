//
//  SpacedRepetitionSchedule.swift
//  DistillIdeas
//
//  SM-2 algorithm implementation for spaced repetition scheduling
//

import Foundation
import SwiftData

// MARK: - Review Quality Rating
enum ReviewQuality: Int, CaseIterable {
    case blackout = 0      // Complete blackout
    case incorrect = 1     // Incorrect, but remembered on seeing answer
    case hardRecall = 2    // Incorrect, but easy to recall after seeing
    case correct = 3       // Correct with significant difficulty
    case good = 4          // Correct after hesitation
    case perfect = 5       // Perfect recall

    var label: String {
        switch self {
        case .blackout: return "Didn't know"
        case .incorrect: return "Incorrect"
        case .hardRecall: return "Hard"
        case .correct: return "Good"
        case .good: return "Easy"
        case .perfect: return "Perfect"
        }
    }

    var emoji: String {
        switch self {
        case .blackout: return "😵"
        case .incorrect: return "😟"
        case .hardRecall: return "😐"
        case .correct: return "🙂"
        case .good: return "😊"
        case .perfect: return "🤩"
        }
    }

    var color: String {
        switch self {
        case .blackout, .incorrect: return "#FF3B30"
        case .hardRecall: return "#FF9500"
        case .correct: return "#34C759"
        case .good: return "#30D158"
        case .perfect: return "#7B61FF"
        }
    }
}

// MARK: - Review Record
@Model
final class ReviewRecord {
    var id: UUID
    var ideaID: UUID
    var reviewDate: Date
    var qualityRating: Int
    var intervalDays: Int
    var easeFactorBefore: Double
    var easeFactorAfter: Double
    var responseTimeSeconds: Double

    init(
        id: UUID = UUID(),
        ideaID: UUID,
        reviewDate: Date = Date(),
        qualityRating: ReviewQuality,
        intervalDays: Int,
        easeFactorBefore: Double,
        easeFactorAfter: Double,
        responseTimeSeconds: Double = 0
    ) {
        self.id = id
        self.ideaID = ideaID
        self.reviewDate = reviewDate
        self.qualityRating = qualityRating.rawValue
        self.intervalDays = intervalDays
        self.easeFactorBefore = easeFactorBefore
        self.easeFactorAfter = easeFactorAfter
        self.responseTimeSeconds = responseTimeSeconds
    }

    var qualityEnum: ReviewQuality {
        ReviewQuality(rawValue: qualityRating) ?? .correct
    }
}

// MARK: - Spaced Repetition Schedule
@Model
final class SpacedRepetitionSchedule {
    var id: UUID
    var ideaID: UUID
    var nextReviewDate: Date
    var intervalDays: Int
    var easeFactor: Double
    var reviewCount: Int
    var consecutiveCorrect: Int
    var dateCreated: Date
    var dateModified: Date
    var isActive: Bool
    var masteryLevel: Int

    init(
        id: UUID = UUID(),
        ideaID: UUID,
        nextReviewDate: Date = Date(),
        intervalDays: Int = 1,
        easeFactor: Double = 2.5,
        reviewCount: Int = 0,
        consecutiveCorrect: Int = 0,
        isActive: Bool = true,
        masteryLevel: Int = 0
    ) {
        self.id = id
        self.ideaID = ideaID
        self.nextReviewDate = nextReviewDate
        self.intervalDays = intervalDays
        self.easeFactor = easeFactor
        self.reviewCount = reviewCount
        self.consecutiveCorrect = consecutiveCorrect
        self.dateCreated = Date()
        self.dateModified = Date()
        self.isActive = isActive
        self.masteryLevel = masteryLevel
    }

    // MARK: - SM-2 Algorithm

    /// Apply SM-2 algorithm to update schedule based on review quality
    func applyReview(quality: ReviewQuality) {
        let q = quality.rawValue
        let oldEaseFactor = easeFactor

        // Calculate new ease factor
        let newEaseFactor = easeFactor + (0.1 - Double(5 - q) * (0.08 + Double(5 - q) * 0.02))
        easeFactor = max(1.3, newEaseFactor)

        reviewCount += 1
        dateModified = Date()

        if q < 3 {
            // Failed recall - reset to beginning
            intervalDays = 1
            consecutiveCorrect = 0
        } else {
            // Successful recall
            consecutiveCorrect += 1

            switch reviewCount {
            case 1:
                intervalDays = 1
            case 2:
                intervalDays = 6
            default:
                intervalDays = Int(Double(intervalDays) * oldEaseFactor)
            }
        }

        // Cap maximum interval at 180 days
        intervalDays = min(intervalDays, 180)

        // Calculate next review date
        nextReviewDate = Calendar.current.date(
            byAdding: .day,
            value: intervalDays,
            to: Date()
        ) ?? Date()

        // Update mastery level
        updateMasteryLevel()
    }

    private func updateMasteryLevel() {
        switch consecutiveCorrect {
        case 0: masteryLevel = 0
        case 1: masteryLevel = 1
        case 2: masteryLevel = 2
        case 3...4: masteryLevel = 3
        case 5...7: masteryLevel = 4
        default: masteryLevel = 5
        }
    }

    var isDueForReview: Bool {
        nextReviewDate <= Date()
    }

    var daysUntilReview: Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: nextReviewDate).day ?? 0
        return max(0, days)
    }

    var reviewStatusLabel: String {
        if isDueForReview {
            return "Due now"
        } else if daysUntilReview == 1 {
            return "Due tomorrow"
        } else {
            return "Due in \(daysUntilReview) days"
        }
    }
}
