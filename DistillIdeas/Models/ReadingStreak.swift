//
//  ReadingStreak.swift
//  DistillIdeas
//
//  Tracks daily reading streaks and engagement
//

import Foundation
import SwiftData

// MARK: - Daily Activity
@Model
final class DailyActivity {
    var id: UUID
    var date: Date
    var ideasRead: Int
    var ideasSaved: Int
    var reviewsCompleted: Int
    var minutesSpent: Int
    var streakDay: Int

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        ideasRead: Int = 0,
        ideasSaved: Int = 0,
        reviewsCompleted: Int = 0,
        minutesSpent: Int = 0,
        streakDay: Int = 0
    ) {
        self.id = id
        self.date = date
        self.ideasRead = ideasRead
        self.ideasSaved = ideasSaved
        self.reviewsCompleted = reviewsCompleted
        self.minutesSpent = minutesSpent
        self.streakDay = streakDay
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

// MARK: - Reading Streak Model
@Model
final class ReadingStreak {
    var id: UUID
    var currentStreak: Int
    var longestStreak: Int
    var totalDaysActive: Int
    var totalIdeasRead: Int
    var totalIdeasSaved: Int
    var totalReviewsCompleted: Int
    var lastActiveDate: Date?
    var streakStartDate: Date?
    var dateCreated: Date

    init(
        id: UUID = UUID(),
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        totalDaysActive: Int = 0,
        totalIdeasRead: Int = 0,
        totalIdeasSaved: Int = 0,
        totalReviewsCompleted: Int = 0,
        lastActiveDate: Date? = nil,
        streakStartDate: Date? = nil
    ) {
        self.id = id
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalDaysActive = totalDaysActive
        self.totalIdeasRead = totalIdeasRead
        self.totalIdeasSaved = totalIdeasSaved
        self.totalReviewsCompleted = totalReviewsCompleted
        self.lastActiveDate = lastActiveDate
        self.streakStartDate = streakStartDate
        self.dateCreated = Date()
    }

    // MARK: - Streak Logic

    func recordActivity() {
        let today = Calendar.current.startOfDay(for: Date())

        if let lastDate = lastActiveDate {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            let daysDiff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysDiff == 0 {
                // Already active today
                return
            } else if daysDiff == 1 {
                // Consecutive day - extend streak
                currentStreak += 1
            } else {
                // Streak broken
                currentStreak = 1
                streakStartDate = today
            }
        } else {
            // First activity
            currentStreak = 1
            streakStartDate = today
        }

        lastActiveDate = Date()
        totalDaysActive += 1

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
    }

    var streakEmoji: String {
        switch currentStreak {
        case 0: return "💤"
        case 1...3: return "🔥"
        case 4...7: return "🔥🔥"
        case 8...14: return "🔥🔥🔥"
        case 15...30: return "⚡🔥"
        default: return "💎🔥"
        }
    }

    var streakTitle: String {
        switch currentStreak {
        case 0: return "Start your streak!"
        case 1: return "Day 1 - Great start!"
        case 2...6: return "\(currentStreak) day streak!"
        case 7: return "One week strong! 🎉"
        case 8...29: return "\(currentStreak) day streak! Keep going!"
        case 30: return "30 day milestone! 🏆"
        default: return "\(currentStreak) day streak! Incredible!"
        }
    }

    var nextMilestone: Int {
        let milestones = [3, 7, 14, 21, 30, 60, 90, 180, 365]
        return milestones.first { $0 > currentStreak } ?? currentStreak + 30
    }

    var progressToNextMilestone: Double {
        let milestone = nextMilestone
        let previous = [0, 3, 7, 14, 21, 30, 60, 90, 180, 365].last { $0 < milestone } ?? 0
        let range = Double(milestone - previous)
        let progress = Double(currentStreak - previous)
        return range > 0 ? min(progress / range, 1.0) : 1.0
    }
}
