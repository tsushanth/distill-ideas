//
//  LibraryView.swift
//  DistillIdeas
//
//  Personal library of saved ideas and collections
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    @Bindable var viewModel: LibraryViewModel
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(\.modelContext) private var modelContext

    @Query private var savedCards: [IdeaCard]
    @Query private var collections: [IdeaCollection]

    @State private var selectedCard: IdeaCard?
    @State private var viewMode: ViewMode = .cards
    @State private var showDeleteConfirmation = false
    @State private var cardToDelete: IdeaCard?

    enum ViewMode: String, CaseIterable {
        case cards = "Cards"
        case collections = "Collections"
    }

    var filteredCards: [IdeaCard] {
        viewModel.filteredCards(from: savedCards)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mode picker
                Picker("View", selection: $viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                if viewMode == .cards {
                    cardsView
                } else {
                    collectionsView
                }
            }
            .navigationTitle("Library")
            .searchable(text: $viewModel.searchQuery, prompt: "Search saved ideas...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort", selection: $viewModel.sortOption) {
                            ForEach(LibraryViewModel.SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
            .overlay {
                if !premiumManager.isPremium {
                    VStack {
                        Spacer()
                        saveLimitBar
                    }
                }
            }
        }
    }

    // MARK: - Cards View

    private var cardsView: some View {
        Group {
            if filteredCards.isEmpty {
                emptyLibraryView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredCards, id: \.id) { card in
                            IdeaCardView(
                                card: card,
                                onTap: { selectedCard = card },
                                onDelete: {
                                    cardToDelete = card
                                    showDeleteConfirmation = true
                                },
                                onFavorite: { viewModel.toggleFavorite(card) }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .padding(.bottom, premiumManager.isPremium ? 0 : 80)
                }
            }
        }
        .alert("Delete Card?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let card = cardToDelete {
                    viewModel.deleteCard(card, context: modelContext, premiumManager: premiumManager)
                }
            }
        } message: {
            Text("This will permanently delete this idea card.")
        }
        .sheet(item: $selectedCard) { card in
            CardDetailView(card: card, viewModel: viewModel)
        }
    }

    // MARK: - Collections View

    private var collectionsView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                // Create new collection button
                Button {
                    viewModel.showCreateCollection = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text("New Collection")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(.systemGray4), style: StrokeStyle(lineWidth: 1, dash: [6]))
                    )
                }
                .buttonStyle(.plain)

                ForEach(collections, id: \.id) { collection in
                    CollectionCardView(collection: collection, isPremiumLocked: collection.isPremiumCollection && !premiumManager.isPremium) {
                        if collection.isPremiumCollection && !premiumManager.isPremium {
                            viewModel.showPaywall = true
                        } else {
                            viewModel.selectedCollection = collection
                            viewMode = .cards
                        }
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $viewModel.showCreateCollection) {
            CreateCollectionView(viewModel: viewModel)
        }
    }

    // MARK: - Empty State

    private var emptyLibraryView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "books.vertical")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("Your library is empty")
                .font(.title2.weight(.semibold))
            Text("Save ideas from the feed to build your personal knowledge library.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    // MARK: - Save Limit Bar

    private var saveLimitBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(premiumManager.saveLimitLabel)
                    .font(.caption.weight(.semibold))
                Text("Upgrade for unlimited saves")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Upgrade") {
                viewModel.showPaywall = true
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Collection Card View

struct CollectionCardView: View {
    let collection: IdeaCollection
    let isPremiumLocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(collection.emoji)
                        .font(.title2)
                    Spacer()
                    if isPremiumLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(collection.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(collection.cardCountLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: collection.colorHex).opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(hex: collection.colorHex).opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .opacity(isPremiumLocked ? 0.6 : 1)
    }
}

// MARK: - Create Collection View

struct CreateCollectionView: View {
    @Bindable var viewModel: LibraryViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let emojis = ["📚", "🧠", "💡", "⚡", "🌱", "🎯", "🔬", "💼", "🎨", "❤️", "🌟", "📝"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Collection Name") {
                    TextField("e.g. Morning Reads", text: $viewModel.newCollectionName)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(emojis, id: \.self) { emoji in
                            Button {
                                viewModel.newCollectionEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.title2)
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(viewModel.newCollectionEmoji == emoji ? Color.accentColor.opacity(0.2) : Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        viewModel.createCollection(context: modelContext)
                        dismiss()
                    }
                    .disabled(viewModel.newCollectionName.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Card Detail View

struct CardDetailView: View {
    let card: IdeaCard
    @Bindable var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Category
                    HStack {
                        Text(card.topicCategoryEnum.emoji + " " + card.topicCategoryEnum.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(hex: card.colorAccentHex))
                        Spacer()
                    }

                    // Quote
                    Text("\"\(card.highlightedText)\"")
                        .font(.title3)
                        .lineSpacing(4)

                    // Attribution
                    if !card.authorName.isEmpty || !card.sourceName.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            if !card.authorName.isEmpty {
                                Text("— \(card.authorName)")
                                    .font(.subheadline.weight(.medium))
                            }
                            if !card.sourceName.isEmpty {
                                Text(card.sourceName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if !card.userNote.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 6) {
                            Label("My Note", systemImage: "note.text")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(card.userNote)
                                .font(.subheadline)
                        }
                    }

                    Divider()

                    Text("Saved \(card.dateCreated.formatted(date: .long, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle(card.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: viewModel.shareText(for: card)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}
