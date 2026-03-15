//
//  SettingsView.swift
//  DistillIdeas
//
//  App settings and preferences
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(\.dismiss) private var dismiss

    @State private var dailyReminderEnabled = true
    @State private var reviewReminderEnabled = true
    @State private var streakReminderEnabled = true
    @State private var dailyReminderTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var hapticFeedback = true
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                // Notifications
                Section("Notifications") {
                    Toggle("Daily Idea Reminder", isOn: $dailyReminderEnabled)
                        .onChange(of: dailyReminderEnabled) { _, enabled in
                            if enabled {
                                NotificationManager.shared.scheduleDailyIdea()
                            } else {
                                NotificationManager.shared.cancelNotifications(of: .dailyIdea)
                            }
                        }

                    if dailyReminderEnabled {
                        DatePicker("Reminder Time", selection: $dailyReminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: dailyReminderTime) { _, newTime in
                                NotificationManager.shared.dailyIdeaTime = newTime
                            }
                    }

                    Toggle("Review Reminder", isOn: $reviewReminderEnabled)
                        .onChange(of: reviewReminderEnabled) { _, enabled in
                            if enabled {
                                NotificationManager.shared.scheduleReviewReminder()
                            } else {
                                NotificationManager.shared.cancelNotifications(of: .reviewReminder)
                            }
                        }

                    Toggle("Streak Reminder", isOn: $streakReminderEnabled)
                        .onChange(of: streakReminderEnabled) { _, enabled in
                            if enabled {
                                NotificationManager.shared.scheduleStreakReminder()
                            } else {
                                NotificationManager.shared.cancelNotifications(of: .streakReminder)
                            }
                        }
                }

                // Appearance
                Section("Experience") {
                    Toggle("Haptic Feedback", isOn: $hapticFeedback)
                        .onChange(of: hapticFeedback) { _, value in
                            AnalyticsService.shared.track(.settingsChanged(setting: "haptic_\(value)"))
                        }
                }

                // Premium
                Section("Premium") {
                    if premiumManager.isPremium {
                        HStack {
                            Label("Premium Active", systemImage: "crown.fill")
                                .foregroundStyle(.yellow)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("Upgrade to Premium", systemImage: "crown.fill")
                                .foregroundStyle(.yellow)
                        }
                    }
                }

                // Account
                Section("Account") {
                    Button(role: .destructive) {
                        // Reset progress
                    } label: {
                        Label("Reset Progress", systemImage: "arrow.counterclockwise")
                    }
                }

                // Legal
                Section("Legal & Support") {
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        Label("Terms of Use", systemImage: "doc.text.fill")
                    }
                    Button {
                        // Contact support
                    } label: {
                        Label("Contact Support", systemImage: "envelope.fill")
                    }
                }

                // App info
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Bundle ID")
                        Spacer()
                        Text("com.appfactory.distillideas")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .onAppear {
                dailyReminderEnabled = NotificationManager.shared.dailyIdeaEnabled
                reviewReminderEnabled = NotificationManager.shared.reviewReminderEnabled
                streakReminderEnabled = NotificationManager.shared.streakReminderEnabled
            }
        }
    }
}
