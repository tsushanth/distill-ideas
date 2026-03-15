//
//  IdeaCardView.swift
//  DistillIdeas
//
//  Displays a saved IdeaCard in the library
//

import SwiftUI

struct IdeaCardView: View {
    let card: IdeaCard
    let onTap: (() -> Void)?
    let onDelete: (() -> Void)?
    let onFavorite: (() -> Void)?

    init(
        card: IdeaCard,
        onTap: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        onFavorite: (() -> Void)? = nil
    ) {
        self.card = card
        self.onTap = onTap
        self.onDelete = onDelete
        self.onFavorite = onFavorite
    }

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack {
                    Text(card.topicCategoryEnum.emoji)
                        .font(.subheadline)
                    Text(card.topicCategoryEnum.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(hex: card.colorAccentHex))
                    Spacer()
                    Button(action: { onFavorite?() }) {
                        Image(systemName: card.isFavorite ? "heart.fill" : "heart")
                            .font(.subheadline)
                            .foregroundStyle(card.isFavorite ? .red : .secondary)
                    }
                    .buttonStyle(.plain)
                }

                // Quote
                Text("\"\(card.highlightedText)\"")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)

                // Note if any
                if !card.userNote.isEmpty {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(card.userNote)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Divider()

                // Footer
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        if !card.authorName.isEmpty {
                            Text(card.authorName)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.primary)
                        }
                        if !card.sourceName.isEmpty {
                            Text(card.sourceName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text(card.dateCreated.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(hex: card.colorAccentHex).opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            if let onFavorite {
                Button(card.isFavorite ? "Unfavorite" : "Favorite", systemImage: card.isFavorite ? "heart.slash" : "heart") {
                    onFavorite()
                }
            }
            if let onDelete {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    onDelete()
                }
            }
        }
    }
}

// MARK: - Idea Detail View

struct IdeaDetailView: View {
    let idea: Idea
    @Bindable var libraryViewModel: LibraryViewModel
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showSaveConfirmation = false
    @State private var highlightedText = ""
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Category + source
                    HStack {
                        Label(idea.topicCategoryEnum.rawValue, systemImage: "")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(hex: idea.topicCategoryEnum.colorHex))
                        Text(idea.topicCategoryEnum.emoji)
                        Spacer()
                        Label(idea.sourceTypeEnum.rawValue, systemImage: idea.sourceTypeEnum.icon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Title
                    Text(idea.title)
                        .font(.title.weight(.bold))

                    // Reading time
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(idea.readingTimeLabel)
                            .font(.caption)
                        Spacer()
                    }
                    .foregroundStyle(.secondary)

                    Divider()

                    // Full content
                    Text(idea.content)
                        .font(.body)
                        .lineSpacing(6)

                    Divider()

                    // Attribution
                    VStack(alignment: .leading, spacing: 4) {
                        if !idea.authorName.isEmpty {
                            Text("— \(idea.authorName)")
                                .font(.subheadline.weight(.medium))
                        }
                        if !idea.sourceName.isEmpty {
                            Text(idea.sourceName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Tags
                    if !idea.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(idea.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(.systemGray6))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showShareSheet = true
                        AnalyticsService.shared.track(.ideaShared(ideaID: idea.id.uuidString))
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }

                    Button {
                        _ = libraryViewModel.saveCard(
                            from: idea,
                            context: modelContext,
                            premiumManager: premiumManager
                        )
                        showSaveConfirmation = true
                    } label: {
                        Image(systemName: idea.isSaved ? "bookmark.fill" : "bookmark")
                            .foregroundStyle(idea.isSaved ? Color.accentColor : .primary)
                    }
                }
            }
            .alert("Saved!", isPresented: $showSaveConfirmation) {
                Button("OK") {}
            } message: {
                Text("Idea added to your library.")
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(text: "\"\(idea.title)\"\n\n\(idea.content)\n\n— \(idea.authorName), \(idea.sourceName)\n\nDistilled with Distill: Ideas That Stick")
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
