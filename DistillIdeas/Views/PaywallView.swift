//
//  PaywallView.swift
//  DistillIdeas
//
//  Premium upgrade paywall
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(StoreKitManager.self) private var storeKit
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isRestoring = false

    let features: [PremiumFeature] = PremiumFeature.allCases

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Hero
                    heroSection

                    // Features
                    featuresSection

                    // Plans
                    plansSection

                    // CTA
                    ctaSection

                    // Legal
                    legalSection
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .alert("Purchase Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .task {
                if storeKit.allProducts.isEmpty {
                    await storeKit.loadProducts()
                }
                // Default select yearly
                selectedProduct = storeKit.yearlyProduct ?? storeKit.allProducts.first
            }
        }
        .onAppear {
            AnalyticsService.shared.track(.paywallShown(source: "paywall_view"))
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(hex: "#7B61FF"), Color(hex: "#5AC8FA")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }
            .padding(.top, 8)

            Text("Distill Premium")
                .font(.title.weight(.bold))

            Text("Unlock your full learning potential with unlimited access to every idea, topic, and feature.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: 12) {
            ForEach(features, id: \.self) { feature in
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: feature.icon)
                            .font(.subheadline)
                            .foregroundStyle(Color.accentColor)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.subheadline.weight(.semibold))
                        Text(feature.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGroupedBackground))
        )
    }

    // MARK: - Plans

    private var plansSection: some View {
        VStack(spacing: 10) {
            Text("Choose Your Plan")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            if storeKit.isLoading {
                ProgressView()
                    .frame(height: 120)
            } else if storeKit.allProducts.isEmpty {
                plansPlaceholder
            } else {
                ForEach(storeKit.subscriptions, id: \.id) { product in
                    PlanCard(
                        product: product,
                        isSelected: selectedProduct?.id == product.id,
                        onSelect: { selectedProduct = product }
                    )
                }

                if let lifetime = storeKit.lifetimeProduct {
                    PlanCard(
                        product: lifetime,
                        isSelected: selectedProduct?.id == lifetime.id,
                        onSelect: { selectedProduct = lifetime }
                    )
                }
            }
        }
    }

    private var plansPlaceholder: some View {
        VStack(spacing: 10) {
            ForEach(["Weekly · $1.99/week", "Monthly · $5.99/month", "Yearly · $29.99/year · Save 60%"], id: \.self) { plan in
                Text(plan)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4))
                    )
            }
        }
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 12) {
            Button {
                guard let product = selectedProduct else { return }
                purchase(product)
            } label: {
                Group {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(selectedProduct != nil ? "Start Premium" : "Select a Plan")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedProduct != nil ? Color.accentColor : Color(.systemGray4))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(selectedProduct == nil || isPurchasing)

            Button {
                restore()
            } label: {
                Text(isRestoring ? "Restoring..." : "Restore Purchases")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .disabled(isRestoring)
        }
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(spacing: 6) {
            Text("Subscription auto-renews unless cancelled. Cancel anytime in App Store settings.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                Link("Terms of Use", destination: URL(string: "https://example.com/terms")!)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

    private func purchase(_ product: Product) {
        isPurchasing = true
        AnalyticsService.shared.track(.purchaseStarted(productID: product.id))

        Task {
            do {
                _ = try await storeKit.purchase(product)
                await premiumManager.refreshPremiumStatus()
                AnalyticsService.shared.track(.purchaseCompleted(productID: product.id, price: Double(truncating: product.price as NSDecimalNumber)))
                dismiss()
            } catch StoreKitError.userCancelled {
                // No-op
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                AnalyticsService.shared.track(.purchaseFailed(productID: product.id, error: error.localizedDescription))
            }
            isPurchasing = false
        }
    }

    private func restore() {
        isRestoring = true
        Task {
            await storeKit.restorePurchases()
            await premiumManager.refreshPremiumStatus()
            AnalyticsService.shared.track(.restorePurchases(success: premiumManager.isPremium))
            if premiumManager.isPremium { dismiss() }
            isRestoring = false
        }
    }
}

// MARK: - Plan Card

struct PlanCard: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(product.displayName)
                            .font(.subheadline.weight(.semibold))
                        if let badge = product.savingsLabel {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.yellow.opacity(0.2))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                        }
                    }
                    Text(product.periodLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.headline)
                    .foregroundStyle(isSelected ? Color.accentColor : .primary)

                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.accentColor : Color(.systemGray4), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 12, height: 12)
                    }
                }
                .padding(.leading, 4)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.accentColor : Color(.systemGray5), lineWidth: isSelected ? 2 : 1)
                    )
                    .shadow(color: isSelected ? Color.accentColor.opacity(0.15) : .clear, radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
