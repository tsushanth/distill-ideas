//
//  CollectionView.swift
//  DistillIdeas
//
//  Browse topic collections
//

import SwiftUI
import SwiftData

struct CollectionBrowserView: View {
    @Environment(PremiumManager.self) private var premiumManager
    @State private var showPaywall = false
    @State private var selectedCategory: TopicCategory?
    @State private var showCategoryIdeas = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(TopicCategory.allCases, id: \.self) { category in
                        TopicCollectionCard(
                            category: category,
                            isLocked: category.isPremium && !premiumManager.isPremium
                        ) {
                            if category.isPremium && !premiumManager.isPremium {
                                showPaywall = true
                            } else {
                                selectedCategory = category
                                showCategoryIdeas = true
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Collections")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .navigationDestination(isPresented: $showCategoryIdeas) {
                if let category = selectedCategory {
                    CategoryIdeasView(category: category)
                }
            }
        }
    }
}

// MARK: - Topic Collection Card

struct TopicCollectionCard: View {
    let category: TopicCategory
    let isLocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(category.emoji)
                        .font(.system(size: 32))
                    Spacer()
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                            .opacity(0)
                    }
                }

                Text(category.rawValue)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(category.descriptionText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: category.colorHex).opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: category.colorHex).opacity(0.3), lineWidth: 1)
                    )
            )
            .opacity(isLocked ? 0.65 : 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Ideas View

struct CategoryIdeasView: View {
    let category: TopicCategory
    @State private var ideas: [Idea] = []
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(ideas, id: \.id) { idea in
                    NavigationLink {
                        // Idea detail
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: category.colorHex))
                                .frame(width: 4)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(idea.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(idea.summary)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                HStack {
                                    Text(idea.authorName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(idea.readingTimeLabel)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
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
            .padding()
        }
        .navigationTitle(category.emoji + " " + category.rawValue)
        .onAppear {
            ideas = ContentService.shared.ideasForCategory(category)
        }
    }
}

// MARK: - TopicCategory Description Extension

extension TopicCategory {
    var descriptionText: String {
        switch self {
        case .psychology: return "Understand the human mind"
        case .productivity: return "Work smarter, achieve more"
        case .science: return "Fascinating discoveries"
        case .philosophy: return "Deep wisdom for modern life"
        case .business: return "Insights from leaders"
        case .health: return "Science-backed wellbeing"
        case .technology: return "Tech trends & thinking"
        case .creativity: return "Unlock creative potential"
        case .relationships: return "Connect more deeply"
        case .finance: return "Build wealth wisely"
        }
    }
}
