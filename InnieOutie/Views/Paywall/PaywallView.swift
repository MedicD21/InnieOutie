//
//  PaywallView.swift
//  ProfitLens
//
//  Pro subscription paywall
//  Conversion-optimized for freelancers
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var paywallService: PaywallService
    @Environment(\.dismiss) var dismiss

    @State private var selectedProductID: String = PaywallService.annualProductID
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Unlock Pro")
                            .font(.largeTitle.bold())

                        Text("Get the full ProfitLens experience")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)

                    // Features
                    VStack(alignment: .leading, spacing: 20) {
                        FeatureRow(
                            icon: "calendar",
                            title: "Unlimited History",
                            description: "Access all your financial data, not just this month"
                        )

                        FeatureRow(
                            icon: "arrow.down.doc.fill",
                            title: "CSV & PDF Exports",
                            description: "Export your data for taxes or clients"
                        )

                        FeatureRow(
                            icon: "camera.fill",
                            title: "Receipt Storage",
                            description: "Attach photos to your expenses"
                        )

                        FeatureRow(
                            icon: "icloud.fill",
                            title: "Cloud Sync",
                            description: "Access your data across all devices"
                        )

                        FeatureRow(
                            icon: "sparkles",
                            title: "Priority Support",
                            description: "Get help when you need it"
                        )
                    }
                    .padding(.horizontal, 24)

                    // Pricing cards
                    VStack(spacing: 12) {
                        // Annual (recommended)
                        PricingCard(
                            title: "Annual",
                            price: paywallService.annualPrice,
                            period: "per year",
                            savings: paywallService.annualSavings,
                            isSelected: selectedProductID == PaywallService.annualProductID,
                            isRecommended: true
                        ) {
                            selectedProductID = PaywallService.annualProductID
                        }

                        // Monthly
                        PricingCard(
                            title: "Monthly",
                            price: paywallService.monthlyPrice,
                            period: "per month",
                            savings: nil,
                            isSelected: selectedProductID == PaywallService.monthlyProductID,
                            isRecommended: false
                        ) {
                            selectedProductID = PaywallService.monthlyProductID
                        }
                    }
                    .padding(.horizontal, 24)

                    // Purchase button
                    Button(action: purchase) {
                        if isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Start Pro")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 24)
                    .disabled(isPurchasing)

                    // Restore & Terms
                    HStack(spacing: 20) {
                        Button("Restore Purchase") {
                            restorePurchases()
                        }
                        .font(.footnote)
                        .foregroundColor(.blue)

                        Text("•")
                            .foregroundColor(.secondary)

                        Link("Terms & Privacy", destination: URL(string: "https://profitlens.app/privacy")!)
                            .font(.footnote)
                            .foregroundColor(.blue)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
        .task {
            await paywallService.loadProducts()
        }
    }

    private func purchase() {
        isPurchasing = true

        Task {
            do {
                let product: Product?
                if selectedProductID == PaywallService.annualProductID {
                    product = paywallService.annualProduct
                } else {
                    product = paywallService.monthlyProduct
                }

                guard let product = product else {
                    throw PaywallError.productNotFound
                }

                try await paywallService.purchasePro(product: product)
                dismiss()

            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }

            isPurchasing = false
        }
    }

    private func restorePurchases() {
        isPurchasing = true

        Task {
            do {
                try await paywallService.restorePurchases()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }

            isPurchasing = false
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }
}

// MARK: - Pricing Card

struct PricingCard: View {
    let title: String
    let price: String
    let period: String
    let savings: String?
    let isSelected: Bool
    let isRecommended: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)

                        if isRecommended {
                            Text("BEST VALUE")
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.green.opacity(0.2))
                                )
                                .foregroundColor(.green)
                        }
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(price)
                            .font(.title2.bold())

                        Text(period)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let savings = savings {
                        Text(savings)
                            .font(.caption.bold())
                            .foregroundColor(.green)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray.opacity(0.3))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? Color.blue : Color.gray.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isSelected ? Color.blue.opacity(0.05) : Color.clear)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
        .environmentObject(PaywallService())
}
