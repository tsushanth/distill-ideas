//
//  ReviewManager.swift
//  DistillIdeas
//
//  App Store review prompt manager
//

import Foundation
import StoreKit

final class ReviewManager {
    static let shared = ReviewManager()

    private let launchCountKey = "com.appfactory.distillideas.launchCount"
    private let lastReviewVersionKey = "com.appfactory.distillideas.lastReviewVersion"
    private let significantEventCountKey = "com.appfactory.distillideas.significantEvents"

    private init() {}

    func recordAppLaunch() {
        let count = UserDefaults.standard.integer(forKey: launchCountKey) + 1
        UserDefaults.standard.set(count, forKey: launchCountKey)
        checkAndRequestReview()
    }

    func recordSignificantEvent() {
        let count = UserDefaults.standard.integer(forKey: significantEventCountKey) + 1
        UserDefaults.standard.set(count, forKey: significantEventCountKey)

        if count == 5 || count == 20 || count % 50 == 0 {
            requestReviewIfAppropriate()
        }
    }

    private func checkAndRequestReview() {
        let launchCount = UserDefaults.standard.integer(forKey: launchCountKey)
        if launchCount == 10 || launchCount == 50 || launchCount == 100 {
            requestReviewIfAppropriate()
        }
    }

    private func requestReviewIfAppropriate() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let lastReviewVersion = UserDefaults.standard.string(forKey: lastReviewVersionKey) ?? ""

        guard currentVersion != lastReviewVersion else { return }

        Task { @MainActor in
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            AppStore.requestReview(in: scene)
            UserDefaults.standard.set(currentVersion, forKey: lastReviewVersionKey)
        }
    }
}
