//
//  DistillIdeasApp.swift
//  DistillIdeas
//
//  Main app entry point - Distill: Ideas That Stick
//

import SwiftUI
import SwiftData

@main
struct DistillIdeasApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let modelContainer: ModelContainer
    @State private var appState = AppStateManager()
    @State private var premiumManager = PremiumManager()
    @State private var storeKitManager = StoreKitManager()

    init() {
        do {
            let schema = Schema([
                Idea.self,
                IdeaCard.self,
                IdeaCollection.self,
                ReadingStreak.self,
                DailyActivity.self,
                SpacedRepetitionSchedule.self,
                ReviewRecord.self,
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        ReviewManager.shared.recordAppLaunch()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(premiumManager)
                .environment(storeKitManager)
                .onAppear {
                    Task {
                        await premiumManager.refreshPremiumStatus()
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        #if DEBUG
        print("[AppDelegate] Distill launched")
        #endif

        Task { @MainActor in
            AnalyticsService.shared.initialize()
            AnalyticsService.shared.track(.appOpen)
        }

        Task { @MainActor in
            _ = await ATTService.shared.requestIfNeeded()
            await AttributionManager.shared.requestAttributionIfNeeded()
        }

        return true
    }
}

// MARK: - App State Manager

@MainActor
@Observable
class AppStateManager {
    var hasCompletedOnboarding: Bool = false
    var isAuthenticated: Bool = false

    private let onboardingKey = "com.appfactory.distillideas.hasCompletedOnboarding"

    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }
}
