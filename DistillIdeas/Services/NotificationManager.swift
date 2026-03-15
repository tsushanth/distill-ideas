//
//  NotificationManager.swift
//  DistillIdeas
//
//  Manages local notifications for daily ideas and review reminders
//

import Foundation
import UserNotifications

// MARK: - Notification Type
enum NotificationType: String, CaseIterable {
    case dailyIdea = "daily_idea"
    case reviewReminder = "review_reminder"
    case streakReminder = "streak_reminder"
    case weeklyDigest = "weekly_digest"

    var title: String {
        switch self {
        case .dailyIdea: return "Daily Idea"
        case .reviewReminder: return "Review Reminder"
        case .streakReminder: return "Streak Reminder"
        case .weeklyDigest: return "Weekly Digest"
        }
    }
}

// MARK: - Notification Manager
@MainActor
@Observable
final class NotificationManager {
    static let shared = NotificationManager()

    private(set) var isAuthorized: Bool = false
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    // Settings
    var dailyIdeaEnabled: Bool = true {
        didSet { if dailyIdeaEnabled { scheduleDailyIdea() } else { cancelNotifications(of: .dailyIdea) } }
    }
    var dailyIdeaTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date() {
        didSet { if dailyIdeaEnabled { scheduleDailyIdea() } }
    }
    var reviewReminderEnabled: Bool = true {
        didSet { if reviewReminderEnabled { scheduleReviewReminder() } else { cancelNotifications(of: .reviewReminder) } }
    }
    var streakReminderEnabled: Bool = true {
        didSet { if streakReminderEnabled { scheduleStreakReminder() } else { cancelNotifications(of: .streakReminder) } }
    }

    private init() {
        Task { await checkAuthorizationStatus() }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            isAuthorized = granted
            if granted { scheduleAll() }
            return granted
        } catch {
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Schedule All

    func scheduleAll() {
        if dailyIdeaEnabled { scheduleDailyIdea() }
        if reviewReminderEnabled { scheduleReviewReminder() }
        if streakReminderEnabled { scheduleStreakReminder() }
    }

    // MARK: - Daily Idea Notification

    func scheduleDailyIdea() {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Your daily idea is ready"
        content.body = "Spend 60 seconds on something worth remembering."
        content.sound = .default
        content.badge = 1

        var components = Calendar.current.dateComponents([.hour, .minute], from: dailyIdeaTime)
        components.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationType.dailyIdea.rawValue,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Review Reminder

    func scheduleReviewReminder(dueCount: Int = 0) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = dueCount > 0 ? "\(dueCount) ideas ready for review" : "Time to review your ideas"
        content.body = "Reinforce what you've learned with a quick review session."
        content.sound = .default

        var components = DateComponents()
        components.hour = 18
        components.minute = 0
        components.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationType.reviewReminder.rawValue,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Streak Reminder

    func scheduleStreakReminder() {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Don't break your streak!"
        content.body = "You haven't read your daily idea yet. Keep your streak alive!"
        content.sound = .default

        var components = DateComponents()
        components.hour = 21
        components.minute = 0
        components.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationType.streakReminder.rawValue,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Cancel

    func cancelNotifications(of type: NotificationType) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [type.rawValue]
        )
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Badge

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}
