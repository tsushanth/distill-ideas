//
//  AnalyticsService.swift
//  DistillIdeas
//
//  Firebase Analytics and event tracking
//

import Foundation

// MARK: - Analytics Event
enum AnalyticsEvent {
    case appOpen
    case onboardingCompleted
    case ideaViewed(ideaID: String, category: String)
    case ideaSaved(ideaID: String)
    case ideaShared(ideaID: String)
    case cardCreated(cardID: String)
    case reviewCompleted(sessionID: String, count: Int, accuracy: Double)
    case reviewItemRated(ideaID: String, quality: Int)
    case collectionOpened(collectionName: String)
    case paywallShown(source: String)
    case purchaseStarted(productID: String)
    case purchaseCompleted(productID: String, price: Double)
    case purchaseFailed(productID: String, error: String)
    case restorePurchases(success: Bool)
    case streakUpdated(days: Int)
    case searchPerformed(query: String)
    case settingsChanged(setting: String)
    case signUp(method: String)
    case signIn(method: String)
    case signOut

    var name: String {
        switch self {
        case .appOpen: return "app_open"
        case .onboardingCompleted: return "onboarding_completed"
        case .ideaViewed: return "idea_viewed"
        case .ideaSaved: return "idea_saved"
        case .ideaShared: return "idea_shared"
        case .cardCreated: return "card_created"
        case .reviewCompleted: return "review_completed"
        case .reviewItemRated: return "review_item_rated"
        case .collectionOpened: return "collection_opened"
        case .paywallShown: return "paywall_shown"
        case .purchaseStarted: return "purchase_started"
        case .purchaseCompleted: return "purchase_completed"
        case .purchaseFailed: return "purchase_failed"
        case .restorePurchases: return "restore_purchases"
        case .streakUpdated: return "streak_updated"
        case .searchPerformed: return "search_performed"
        case .settingsChanged: return "settings_changed"
        case .signUp: return "sign_up"
        case .signIn: return "login"
        case .signOut: return "sign_out"
        }
    }

    var parameters: [String: Any] {
        switch self {
        case .appOpen: return [:]
        case .onboardingCompleted: return [:]
        case .ideaViewed(let id, let cat): return ["idea_id": id, "category": cat]
        case .ideaSaved(let id): return ["idea_id": id]
        case .ideaShared(let id): return ["idea_id": id]
        case .cardCreated(let id): return ["card_id": id]
        case .reviewCompleted(let sid, let count, let acc):
            return ["session_id": sid, "count": count, "accuracy": acc]
        case .reviewItemRated(let id, let q): return ["idea_id": id, "quality": q]
        case .collectionOpened(let name): return ["collection_name": name]
        case .paywallShown(let src): return ["source": src]
        case .purchaseStarted(let id): return ["product_id": id]
        case .purchaseCompleted(let id, let p): return ["product_id": id, "price": p]
        case .purchaseFailed(let id, let err): return ["product_id": id, "error": err]
        case .restorePurchases(let ok): return ["success": ok]
        case .streakUpdated(let days): return ["days": days]
        case .searchPerformed(let q): return ["query": q]
        case .settingsChanged(let s): return ["setting": s]
        case .signUp(let m): return ["method": m]
        case .signIn(let m): return ["method": m]
        case .signOut: return [:]
        }
    }
}

// MARK: - Analytics Service
final class AnalyticsService {
    static let shared = AnalyticsService()

    private var isInitialized = false

    private init() {}

    func initialize() {
        // Firebase.configure() would go here
        // FirebaseApp.configure()
        isInitialized = true
        #if DEBUG
        print("[Analytics] Initialized")
        #endif
    }

    func track(_ event: AnalyticsEvent) {
        guard isInitialized else { return }

        #if DEBUG
        print("[Analytics] \(event.name): \(event.parameters)")
        #endif

        // Firebase Analytics would be called here:
        // Analytics.logEvent(event.name, parameters: event.parameters)
    }

    func setUserProperty(_ value: String?, forName name: String) {
        #if DEBUG
        print("[Analytics] User property \(name) = \(value ?? "nil")")
        #endif
        // Analytics.setUserProperty(value, forName: name)
    }

    func setUserID(_ userID: String?) {
        // Analytics.setUserID(userID)
    }
}
