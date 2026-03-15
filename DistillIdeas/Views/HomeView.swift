//
//  HomeView.swift
//  DistillIdeas
//
//  Main tab container view
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(StoreKitManager.self) private var storeKitManager

    @State private var selectedTab: Tab = .feed
    @State private var feedViewModel = FeedViewModel()
    @State private var libraryViewModel = LibraryViewModel()
    @State private var reviewViewModel = ReviewViewModel()

    @Query private var savedCards: [IdeaCard]
    @Query private var collections: [IdeaCollection]
    @Query private var streak: [ReadingStreak]

    enum Tab: String, CaseIterable {
        case feed = "For You"
        case library = "Library"
        case review = "Review"
        case profile = "Profile"

        var icon: String {
            switch self {
            case .feed: return "sparkles"
            case .library: return "books.vertical.fill"
            case .review: return "brain.head.profile"
            case .profile: return "person.circle.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            IdeaFeedView(
                viewModel: feedViewModel,
                libraryViewModel: libraryViewModel
            )
            .tabItem {
                Label("For You", systemImage: "sparkles")
            }
            .tag(Tab.feed)

            LibraryView(viewModel: libraryViewModel)
                .tabItem {
                    Label("Library", systemImage: "books.vertical.fill")
                }
                .tag(Tab.library)

            ReviewView(viewModel: reviewViewModel, libraryViewModel: libraryViewModel)
                .tabItem {
                    Label("Review", systemImage: "brain.head.profile")
                }
                .badge(reviewViewModel.dueCount > 0 ? reviewViewModel.dueCount : 0)
                .tag(Tab.review)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(Tab.profile)
        }
        .tint(Color("AccentColor"))
        .sheet(isPresented: Binding(
            get: { feedViewModel.showPaywall || libraryViewModel.showPaywall },
            set: { if !$0 {
                feedViewModel.showPaywall = false
                libraryViewModel.showPaywall = false
            }}
        )) {
            PaywallView()
        }
        .task {
            await feedViewModel.loadFeed(premiumManager: premiumManager)
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .review {
                reviewViewModel.updateDueCount(
                    savedCards: savedCards,
                    ideas: feedViewModel.ideas
                )
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(PremiumManager())
        .environment(StoreKitManager())
}
