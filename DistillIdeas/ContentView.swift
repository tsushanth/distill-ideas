//
//  ContentView.swift
//  DistillIdeas
//
//  Root view that handles onboarding vs main app routing
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppStateManager.self) private var appState
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(StoreKitManager.self) private var storeKit

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                HomeView()
            } else {
                OnboardingView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.hasCompletedOnboarding)
    }
}

#Preview {
    ContentView()
        .environment(AppStateManager())
        .environment(PremiumManager())
        .environment(StoreKitManager())
}
