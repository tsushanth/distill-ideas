//
//  ProfileView.swift
//  DistillIdeas
//
//  User profile, stats, and settings
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(StoreKitManager.self) private var storeKit
    @Environment(\.modelContext) private var modelContext

    @Query private var savedCards: [IdeaCard]
    @Query private var streak: [ReadingStreak]

    @State private var showPaywall = false
    @State private var showSettings = false

    var currentStreak: ReadingStreak? { streak.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile header
                    profileHeader

                    // Stats grid
                    statsSection

                    // Premium banner (if not premium)
                    if !premiumManager.isPremium {
                        premiumBanner
                    } else {
                        premiumStatusCard
                    }

                    // Quick actions
                    quickActionsSection

                    // App info
                    appInfoSection
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(hex: "#7B61FF"), Color(hex: "#5AC8FA")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                Text("D")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 4) {
                Text("Knowledge Seeker")
                    .font(.title2.weight(.bold))
                if premiumManager.isPremium {
                    Label("Premium Member", systemImage: "crown.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.yellow)
                }
            }

            // Streak display
            if let s = currentStreak, s.currentStreak > 0 {
                HStack(spacing: 6) {
                    Text(s.streakEmoji)
                    Text("\(s.currentStreak) day streak")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.orange)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }

    // MARK: - Stats

    private var statsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ProfileStatCell(
                value: "\(savedCards.count)",
                label: "Saved",
                icon: "bookmark.fill",
                color: .purple
            )
            ProfileStatCell(
                value: "\(currentStreak?.currentStreak ?? 0)",
                label: "Streak",
                icon: "flame.fill",
                color: .orange
            )
            ProfileStatCell(
                value: "\(currentStreak?.totalIdeasRead ?? 0)",
                label: "Read",
                icon: "eye.fill",
                color: .blue
            )
            ProfileStatCell(
                value: "\(currentStreak?.longestStreak ?? 0)",
                label: "Best Streak",
                icon: "trophy.fill",
                color: .yellow
            )
            ProfileStatCell(
                value: "\(currentStreak?.totalReviewsCompleted ?? 0)",
                label: "Reviewed",
                icon: "brain.head.profile",
                color: .green
            )
            ProfileStatCell(
                value: "\(savedCards.filter { $0.isFavorite }.count)",
                label: "Favorites",
                icon: "heart.fill",
                color: .red
            )
        }
    }

    // MARK: - Premium Banner

    private var premiumBanner: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundStyle(.yellow)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Upgrade to Premium")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                    Text("Unlock all topics, unlimited saves & more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 8)
            )
        }
        .buttonStyle(.plain)
    }

    private var premiumStatusCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.2))
                    .frame(width: 48, height: 48)
                Image(systemName: "crown.fill")
                    .font(.title3)
                    .foregroundStyle(.yellow)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Premium Active")
                    .font(.subheadline.weight(.bold))
                Text("Thank you for supporting Distill!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.yellow.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(spacing: 1) {
            ForEach([
                ("Notification Settings", "bell.fill", Color.blue),
                ("Appearance", "paintbrush.fill", Color.purple),
                ("Rate Distill", "star.fill", Color.yellow),
                ("Share with Friends", "square.and.arrow.up.fill", Color.green),
                ("Help & Feedback", "questionmark.circle.fill", Color.gray),
            ], id: \.0) { item in
                Button {
                    // Action
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(item.2.opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: item.1)
                                .font(.caption)
                                .foregroundStyle(item.2)
                        }
                        Text(item.0)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                }
                .buttonStyle(.plain)

                if item.0 != "Help & Feedback" {
                    Divider()
                        .padding(.leading, 56)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 6)
    }

    // MARK: - App Info

    private var appInfoSection: some View {
        VStack(spacing: 4) {
            Text("Distill: Ideas That Stick")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Version 1.0.0")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }
}

// MARK: - Profile Stat Cell

struct ProfileStatCell: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.weight(.bold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 4)
        )
    }
}
