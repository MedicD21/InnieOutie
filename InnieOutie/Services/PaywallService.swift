//
//  PaywallService.swift
//  ProfitLens
//
//  Handles Pro subscription and feature gating
//  Freemium → Pro conversion strategy
//

import Foundation
import StoreKit
import SwiftUI

enum ProFeature {
    case unlimitedHistory      // View data beyond current month
    case csvExport            // Export to CSV
    case pdfExport            // Export to PDF
    case receiptStorage       // Attach receipt photos
    case cloudSync            // iCloud sync (future)
}

enum PaywallTrigger: String {
    case exportCSV = "export_csv"
    case exportPDF = "export_pdf"
    case viewHistoricalMonth = "view_historical_month"
    case uploadReceipt = "upload_receipt"
    case enable30DaysTracked = "30_days_tracked"
    case manualUpgrade = "manual_upgrade"
    case settingsUpgrade = "settings_upgrade"
}

@MainActor
class PaywallService: ObservableObject {

    // MARK: - Published Properties

    @Published var isPro: Bool = false
    @Published var showPaywall: Bool = false
    @Published var currentTrigger: PaywallTrigger = .manualUpgrade

    // StoreKit products
    @Published var monthlyProduct: Product?
    @Published var annualProduct: Product?
    @Published var isLoading: Bool = false

    // MARK: - Constants

    // IMPORTANT: These product IDs must match App Store Connect configuration
    static let monthlyProductID = "com.innieoutie.pro.monthly"
    static let annualProductID = "com.innieoutie.pro.annual"

    private let proStatusKey = "user_is_pro"
    private let proExpirationKey = "pro_expiration_date"

    // MARK: - Initialization

    init() {
        self.isPro = UserDefaults.standard.bool(forKey: proStatusKey)

        // Check if Pro subscription is still valid
        if isPro {
            checkProExpiration()
        }
    }

    // MARK: - Feature Access

    /// Check if user can access a Pro feature
    func canAccess(_ feature: ProFeature) -> Bool {
        return isPro
    }

    /// Request access to Pro feature (shows paywall if needed)
    func requestAccess(to feature: ProFeature, trigger: PaywallTrigger) -> Bool {
        if canAccess(feature) {
            return true
        } else {
            showPaywall(with: trigger)
            return false
        }
    }

    /// Show paywall with specific trigger
    func showPaywall(with trigger: PaywallTrigger) {
        currentTrigger = trigger
        logPaywallTrigger(trigger)
        showPaywall = true
    }

    // MARK: - StoreKit Integration

    /// Load available products from App Store
    func loadProducts() async {
        isLoading = true

        do {
            let products = try await Product.products(
                for: [Self.monthlyProductID, Self.annualProductID]
            )

            for product in products {
                switch product.id {
                case Self.monthlyProductID:
                    monthlyProduct = product
                case Self.annualProductID:
                    annualProduct = product
                default:
                    break
                }
            }
        } catch {
            print("Failed to load products: \(error)")
        }

        isLoading = false
    }

    /// Purchase Pro subscription
    func purchasePro(product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            // Verify the transaction
            switch verification {
            case .verified(let transaction):
                // Grant Pro access
                await unlockPro(transaction: transaction)
                await transaction.finish()

            case .unverified(_, let error):
                throw PaywallError.verificationFailed(error)
            }

        case .userCancelled:
            throw PaywallError.userCancelled

        case .pending:
            throw PaywallError.pending

        @unknown default:
            throw PaywallError.unknown
        }
    }

    /// Restore previous purchases
    func restorePurchases() async throws {
        var restoredTransaction: StoreKit.Transaction?

        // Check for active subscriptions
        for await result in StoreKit.Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productID == Self.monthlyProductID ||
                   transaction.productID == Self.annualProductID {
                    restoredTransaction = transaction
                    break
                }

            case .unverified(_, let error):
                print("Unverified transaction: \(error)")
            }
        }

        if let transaction = restoredTransaction {
            await unlockPro(transaction: transaction)
        } else {
            throw PaywallError.noPurchaseToRestore
        }
    }

    /// Check current subscription status
    func checkSubscriptionStatus() async {
        // Check for active entitlements
        for await result in StoreKit.Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productID == Self.monthlyProductID ||
                   transaction.productID == Self.annualProductID {
                    await unlockPro(transaction: transaction)
                    return
                }

            case .unverified:
                continue
            }
        }

        // No active subscription found
        if isPro {
            await revokePro()
        }
    }

    // MARK: - Private Helpers

    private func unlockPro(transaction: StoreKit.Transaction) async {
        isPro = true
        UserDefaults.standard.set(true, forKey: proStatusKey)

        // Store expiration date if available
        if let expirationDate = transaction.expirationDate {
            UserDefaults.standard.set(expirationDate, forKey: proExpirationKey)
        }

        // Close paywall
        showPaywall = false

        print("Pro unlocked successfully")
    }

    private func revokePro() async {
        isPro = false
        UserDefaults.standard.set(false, forKey: proStatusKey)
        UserDefaults.standard.removeObject(forKey: proExpirationKey)
        print("Pro access revoked")
    }

    private func checkProExpiration() {
        if let expirationDate = UserDefaults.standard.object(forKey: proExpirationKey) as? Date {
            if expirationDate < Date() {
                // Subscription expired
                Task {
                    await revokePro()
                }
            }
        }
    }

    private func logPaywallTrigger(_ trigger: PaywallTrigger) {
        // Analytics tracking for conversion optimization
        print("📊 Paywall triggered: \(trigger.rawValue)")

        // TODO: Add analytics service (TelemetryDeck, etc.)
        // Analytics.track("paywall_shown", properties: ["trigger": trigger.rawValue])
    }

    // MARK: - Pricing Display

    /// Get formatted monthly price
    var monthlyPrice: String {
        monthlyProduct?.displayPrice ?? "$8.00"
    }

    /// Get formatted annual price
    var annualPrice: String {
        annualProduct?.displayPrice ?? "$49.00"
    }

    /// Calculate savings percentage for annual plan
    var annualSavings: String {
        guard let monthly = monthlyProduct,
              let annual = annualProduct else {
            return "Save 49%"
        }

        let monthlyYearly = monthly.price * 12
        let savings = (monthlyYearly - annual.price) / monthlyYearly * 100

        return "Save \(NSDecimalNumber(decimal: savings).intValue)%"
    }
}

// MARK: - Errors

enum PaywallError: LocalizedError {
    case productNotFound
    case verificationFailed(Error)
    case userCancelled
    case pending
    case noPurchaseToRestore
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found"
        case .verificationFailed(let error):
            return "Verification failed: \(error.localizedDescription)"
        case .userCancelled:
            return "Purchase cancelled"
        case .pending:
            return "Purchase is pending approval"
        case .noPurchaseToRestore:
            return "No previous purchase found"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
