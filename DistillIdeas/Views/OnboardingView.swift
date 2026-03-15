//
//  OnboardingView.swift
//  DistillIdeas
//
//  First-run onboarding experience
//

import SwiftUI

// MARK: - Onboarding Page
struct OnboardingPage {
    let id: Int
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let gradient: [Color]
}

struct OnboardingView: View {
    @Environment(AppStateManager.self) private var appState
    @State private var currentPage = 0
    @State private var selectedTopics: Set<TopicCategory> = []
    @State private var showNotificationRequest = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            title: "Ideas That Stick",
            subtitle: "Learn smarter, not harder",
            description: "Distill turns the best ideas from books, podcasts, and articles into 60-second reads you'll actually remember.",
            icon: "lightbulb.fill",
            gradient: [Color(hex: "#7B61FF"), Color(hex: "#5AC8FA")]
        ),
        OnboardingPage(
            id: 1,
            title: "Build Your Library",
            subtitle: "Save what matters",
            description: "Highlight insights that resonate with you and build a personal library of knowledge you can revisit anytime.",
            icon: "books.vertical.fill",
            gradient: [Color(hex: "#FF9500"), Color(hex: "#FF2D55")]
        ),
        OnboardingPage(
            id: 2,
            title: "Never Forget",
            subtitle: "Spaced repetition review",
            description: "Our intelligent review system resurfaces ideas at the perfect moment so knowledge moves from short-term memory to long-term.",
            icon: "brain.head.profile",
            gradient: [Color(hex: "#34C759"), Color(hex: "#30D158")]
        ),
        OnboardingPage(
            id: 3,
            title: "Build a Streak",
            subtitle: "Daily learning habit",
            description: "Just 5 minutes a day. Read one idea, save one insight. Watch your knowledge compound over time.",
            icon: "flame.fill",
            gradient: [Color(hex: "#FF3B30"), Color(hex: "#FF9500")]
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            if currentPage < pages.count {
                pageView(pages[currentPage])
            } else if currentPage == pages.count {
                topicSelectionView
            } else {
                notificationView
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentPage)
    }

    // MARK: - Page View

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 0) {
            // Illustration area
            ZStack {
                LinearGradient(
                    colors: page.gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(edges: .top)

                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: page.icon)
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.2), radius: 10)

                    // Page dots
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            Circle()
                                .fill(i == currentPage ? Color.white : Color.white.opacity(0.4))
                                .frame(width: i == currentPage ? 10 : 6, height: i == currentPage ? 10 : 6)
                        }
                    }
                    Spacer()
                }
            }
            .frame(height: 340)

            // Content
            VStack(alignment: .leading, spacing: 16) {
                Text(page.title)
                    .font(.title.weight(.bold))
                    .padding(.top, 24)

                Text(page.subtitle)
                    .font(.headline)
                    .foregroundStyle(page.gradient[0])

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)

                Spacer()

                Button {
                    withAnimation {
                        currentPage += 1
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(page.gradient[0])
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 28)
        }
    }

    // MARK: - Topic Selection

    private var topicSelectionView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What interests you?")
                    .font(.title.weight(.bold))
                    .padding(.top, 60)
                Text("Choose topics to personalize your feed. You can change this anytime.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(TopicCategory.allCases, id: \.self) { category in
                        Button {
                            if selectedTopics.contains(category) {
                                selectedTopics.remove(category)
                            } else {
                                selectedTopics.insert(category)
                            }
                        } label: {
                            VStack(spacing: 8) {
                                Text(category.emoji)
                                    .font(.title2)
                                Text(category.rawValue)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                                if category.isPremium {
                                    Text("Premium")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(selectedTopics.contains(category)
                                          ? Color(hex: category.colorHex).opacity(0.2)
                                          : Color(.systemGroupedBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(
                                                selectedTopics.contains(category)
                                                    ? Color(hex: category.colorHex)
                                                    : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }

            Button {
                withAnimation { currentPage += 1 }
            } label: {
                Text(selectedTopics.isEmpty ? "Skip" : "Continue (\(selectedTopics.count) selected)")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Notification View

    private var notificationView: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.accentColor)

            VStack(spacing: 8) {
                Text("Stay on track")
                    .font(.title.weight(.bold))
                Text("Get a daily reminder to read your idea and keep your learning streak alive.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 12) {
                Button {
                    Task {
                        _ = await NotificationManager.shared.requestAuthorization()
                        completeOnboarding()
                    }
                } label: {
                    Text("Allow Notifications")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    completeOnboarding()
                } label: {
                    Text("Not now")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
    }

    private func completeOnboarding() {
        appState.completeOnboarding()
        AnalyticsService.shared.track(.onboardingCompleted)
    }
}
