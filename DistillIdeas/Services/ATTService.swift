//
//  ATTService.swift
//  DistillIdeas
//
//  App Tracking Transparency permission handling
//

import Foundation
import AppTrackingTransparency
import AdServices

// MARK: - ATT Service
@MainActor
final class ATTService {
    static let shared = ATTService()

    private init() {}

    var trackingStatus: ATTrackingManager.AuthorizationStatus {
        ATTrackingManager.trackingAuthorizationStatus
    }

    var isTrackingAllowed: Bool {
        ATTrackingManager.trackingAuthorizationStatus == .authorized
    }

    func requestIfNeeded() async -> ATTrackingManager.AuthorizationStatus {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            return ATTrackingManager.trackingAuthorizationStatus
        }

        // Brief delay to allow app to fully launch
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        let status = await ATTrackingManager.requestTrackingAuthorization()

        #if DEBUG
        print("[ATT] Authorization status: \(status.rawValue)")
        #endif

        return status
    }
}

// MARK: - Attribution Manager
final class AttributionManager {
    static let shared = AttributionManager()
    private var hasRequested = false

    private init() {}

    func requestAttributionIfNeeded() async {
        guard !hasRequested else { return }
        hasRequested = true

        do {
            let token = try AAAttribution.attributionToken()
            #if DEBUG
            print("[Attribution] Token obtained: \(token.prefix(20))...")
            #endif
            // Send token to your attribution backend or RevenueCat
        } catch {
            #if DEBUG
            print("[Attribution] Error: \(error.localizedDescription)")
            #endif
        }
    }
}
