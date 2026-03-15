//
//  IdeaFeedView.swift
//  DistillIdeas
//
//  Main scrollable feed of daily ideas
//

import SwiftUI
import SwiftData

struct IdeaFeedView: View {
    @Bindable var viewModel: FeedViewModel
    @Bindable var libraryViewModel: LibraryViewModel
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(\.modelContext) private var modelContext

    @Query private var streak: [ReadingStreak]

    @State private var showIdeaDetail: Idea?

    var currentStreak: ReadingStreak? { streak.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header streak bar
                    if let s = currentStreak, s.currentStreak > 0 {
                        streakBanner(streak: s)
                    }

                    // Category chips
                    categoryScrollView

                    // Featured idea
                    if let featured = viewModel.featuredIdea, viewModel.selectedCategory == nil, viewModel.searchQuery.isEmpty {
                        featuredIdeaCard(featured)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }

                    // Ideas list
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.filteredIdeas.isEmpty {
                        emptyStateView
                    } else {
                        ideasList
                    }
                }
            }
            .navigationTitle("Distill")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $viewModel.searchQuery, prompt: "Search ideas, authors, topics...")
            .refreshable {
                await viewModel.refreshFeed(premiumManager: premiumManager)
            }
            .sheet(item: $showIdeaDetail) { idea in
                IdeaDetailView(
                    idea: idea,
                    libraryViewModel: libraryViewModel
                )
            }
        }
    }

    // MARK: - Subviews

    private func streakBanner(streak: ReadingStreak) -> some View {
        HStack {
            Text(streak.streakEmoji)
            Text("\(streak.currentStreak) day streak")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Text(streak.streakTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }

    private var categoryScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(
                    label: "All",
                    emoji: "✨",
                    isSelected: viewModel.selectedCategory == nil,
                    isPremium: false
                ) {
                    viewModel.selectCategory(nil, premiumManager: premiumManager)
                }

                ForEach(TopicCategory.allCases, id: \.self) { cat in
                    CategoryChip(
                        label: cat.rawValue,
                        emoji: cat.emoji,
                        isSelected: viewModel.selectedCategory == cat,
                        isPremium: cat.isPremium && !premiumManager.isPremium
                    ) {
                        viewModel.selectCategory(cat, premiumManager: premiumManager)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func featuredIdeaCard(_ idea: Idea) -> some View {
        Button {
            viewModel.markViewed(idea)
            showIdeaDetail = idea
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Featured Today", systemImage: "star.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.yellow)
                    Spacer()
                    Text(idea.topicCategoryEnum.emoji)
                }

                Text(idea.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                Text(idea.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                HStack {
                    Text(idea.authorName)
                        .font(.caption.weight(.medium))
                    Text("·")
                    Text(idea.sourceName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(idea.readingTimeLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }

    private var ideasList: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.filteredIdeas, id: \.id) { idea in
                IdeaRowView(
                    idea: idea,
                    onTap: {
                        viewModel.markViewed(idea)
                        showIdeaDetail = idea
                    },
                    onSave: {
                        _ = libraryViewModel.saveCard(
                            from: idea,
                            context: modelContext,
                            premiumManager: premiumManager
                        )
                    }
                )
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ForEach(0..<5, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(height: 100)
                    .shimmer()
            }
        }
        .padding()
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(viewModel.isSearching ? "No results found" : "No ideas yet")
                .font(.headline)
            Text(viewModel.isSearching ? "Try a different search term" : "Check back soon for new ideas")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let label: String
    let emoji: String
    let isSelected: Bool
    let isPremium: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(emoji)
                    .font(.caption)
                Text(label)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                if isPremium {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color(.systemGray6))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Idea Row View

struct IdeaRowView: View {
    let idea: Idea
    let onTap: () -> Void
    let onSave: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Category color stripe
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: idea.topicCategoryEnum.colorHex))
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(idea.topicCategoryEnum.emoji + " " + idea.topicCategoryEnum.rawValue)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color(hex: idea.topicCategoryEnum.colorHex))
                        Spacer()
                        Text(idea.readingTimeLabel)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if idea.isPremiumContent {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                        }
                    }

                    Text(idea.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    Text(idea.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    HStack {
                        Text(idea.authorName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if !idea.sourceName.isEmpty {
                            Text("· \(idea.sourceName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()

                        Button(action: onSave) {
                            Image(systemName: idea.isSaved ? "bookmark.fill" : "bookmark")
                                .font(.subheadline)
                                .foregroundStyle(idea.isSaved ? Color.accentColor : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shimmer Effect

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            .white.opacity(0.4),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: geo.size.width * phase)
                }
                .clipped()
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}
