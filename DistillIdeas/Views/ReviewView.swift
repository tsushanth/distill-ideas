//
//  ReviewView.swift
//  DistillIdeas
//
//  Spaced repetition review interface
//

import SwiftUI
import SwiftData

struct ReviewView: View {
    @Bindable var viewModel: ReviewViewModel
    @Bindable var libraryViewModel: LibraryViewModel
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(\.modelContext) private var modelContext

    @Query private var savedCards: [IdeaCard]

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isSessionActive {
                    activeSessionView
                } else if viewModel.showSessionComplete {
                    sessionCompleteView
                } else {
                    reviewLandingView
                }
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Landing View

    private var reviewLandingView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Due count card
                dueCountCard

                // Stats overview
                statsOverview

                // How it works
                howItWorksSection
            }
            .padding()
        }
    }

    private var dueCountCard: some View {
        VStack(spacing: 16) {
            if viewModel.dueCount > 0 {
                VStack(spacing: 8) {
                    Text("\(viewModel.dueCount)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.accentColor)
                    Text(viewModel.dueCount == 1 ? "idea ready to review" : "ideas ready to review")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.green)
                    Text("All caught up!")
                        .font(.title2.weight(.bold))
                    Text("Come back tomorrow for more reviews.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                viewModel.startSession(savedCards: savedCards, ideas: ContentService.shared.dailyIdeas)
            } label: {
                Label("Start Review", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.dueCount > 0 ? Color.accentColor : Color(.systemGray4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(viewModel.dueCount == 0)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }

    private var statsOverview: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "Cards Saved", value: "\(savedCards.count)", icon: "bookmark.fill", color: .purple)
            StatCard(title: "Reviewed", value: "\(savedCards.count)", icon: "checkmark.circle.fill", color: .green)
            StatCard(title: "Mastered", value: "\(savedCards.count)", icon: "star.fill", color: .yellow)
            StatCard(title: "Streak", value: "0", icon: "flame.fill", color: .orange)
        }
    }

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How Review Works")
                .font(.headline)

            ForEach([
                ("1", "See an idea from your library", "books.vertical"),
                ("2", "Try to recall what you know", "brain.head.profile"),
                ("3", "Rate how well you remembered", "star.leadinghalf.filled"),
                ("4", "The app schedules your next review", "calendar"),
            ], id: \.0) { step in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Text(step.0)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.accentColor)
                    }
                    Text(step.1)
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: step.2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGroupedBackground))
        )
    }

    // MARK: - Active Session View

    private var activeSessionView: some View {
        VStack(spacing: 0) {
            // Progress
            VStack(spacing: 4) {
                HStack {
                    Text("\(viewModel.currentIndex + 1) of \(viewModel.totalCount)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("End") {
                        viewModel.endSession()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                ProgressView(value: viewModel.progress)
                    .tint(Color.accentColor)
                    .padding(.horizontal)
            }
            .padding(.top)

            Spacer()

            if let idea = viewModel.currentIdea {
                flashCardView(idea: idea)
                    .padding(.horizontal)
            }

            Spacer()

            // Quality buttons (shown after flip)
            if viewModel.showQualityPicker {
                qualityButtonsView
                    .padding()
                    .background(.ultraThinMaterial)
            } else {
                // Tap to flip hint
                Button {
                    viewModel.flipCard()
                } label: {
                    Text("Tap to reveal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
        }
    }

    private func flashCardView(idea: Idea) -> some View {
        ZStack {
            // Back of card (full content)
            VStack(alignment: .leading, spacing: 16) {
                Text(idea.topicCategoryEnum.emoji + " " + idea.topicCategoryEnum.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: idea.topicCategoryEnum.colorHex))

                Text(idea.title)
                    .font(.title2.weight(.bold))

                ScrollView {
                    Text(idea.content)
                        .font(.body)
                        .lineSpacing(4)
                }

                HStack {
                    Text("— \(idea.authorName)")
                        .font(.caption.weight(.medium))
                    if !idea.sourceName.isEmpty {
                        Text("· \(idea.sourceName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: 420, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 6)
            )
            .opacity(viewModel.isFlipped ? 1 : 0)
            .rotation3DEffect(.degrees(viewModel.isFlipped ? 0 : 180), axis: (x: 0, y: 1, z: 0))

            // Front of card (title only)
            VStack(spacing: 16) {
                Text(idea.topicCategoryEnum.emoji)
                    .font(.system(size: 48))

                Text(idea.title)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)

                Text("Recall this idea before flipping")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 240)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: idea.topicCategoryEnum.colorHex).opacity(0.12))
                    .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
            )
            .opacity(viewModel.isFlipped ? 0 : 1)
            .rotation3DEffect(.degrees(viewModel.isFlipped ? -180 : 0), axis: (x: 0, y: 1, z: 0))
        }
        .onTapGesture {
            if !viewModel.isFlipped {
                viewModel.flipCard()
            }
        }
    }

    private var qualityButtonsView: some View {
        VStack(spacing: 10) {
            Text("How well did you remember?")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 8) {
                ForEach([ReviewQuality.blackout, .incorrect, .hardRecall, .correct, .good, .perfect], id: \.self) { quality in
                    Button {
                        viewModel.rateReview(quality)
                    } label: {
                        VStack(spacing: 4) {
                            Text(quality.emoji)
                                .font(.title3)
                            Text(quality.label)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(hex: quality.color).opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Session Complete

    private var sessionCompleteView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.accentColor)

            VStack(spacing: 8) {
                Text("Session Complete!")
                    .font(.title.weight(.bold))
                Text(viewModel.motivationalMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Stats
            HStack(spacing: 24) {
                VStack {
                    Text("\(viewModel.completedCount)")
                        .font(.title.weight(.bold))
                    Text("Reviewed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                VStack {
                    Text("\(Int(viewModel.accuracy * 100))%")
                        .font(.title.weight(.bold))
                    Text("Accuracy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                VStack {
                    Text(viewModel.sessionDurationLabel)
                        .font(.title.weight(.bold))
                    Text("Time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGroupedBackground))
            )

            Button {
                viewModel.showSessionComplete = false
                viewModel.updateDueCount(savedCards: savedCards, ideas: ContentService.shared.dailyIdeas)
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)

            Spacer()
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.weight(.bold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }
}
