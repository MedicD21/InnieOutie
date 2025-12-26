//
//  MonthlyReportsView.swift
//  ProfitLens
//
//  Monthly reports tab - historical view
//

import SwiftUI

struct MonthlyReportsView: View {
    @StateObject private var viewModel = MonthlyReportsViewModel()
    @EnvironmentObject var paywallService: PaywallService

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.months, id: \.self) { month in
                    MonthRowView(
                        month: month,
                        snapshot: viewModel.snapshots[month] ?? .empty
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Navigate to month detail (future feature)
                    }
                }

                if !paywallService.isPro && viewModel.hasMoreMonths {
                    UpgradePromptRow()
                        .onTapGesture {
                            paywallService.showPaywall(with: .viewHistoricalMonth)
                        }
                }
            }
            .navigationTitle("Reports")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            viewModel.showExportOptions = true
                        }) {
                            Label("Export All Data", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showExportOptions) {
                // Export all data view
                ExportOptionsView(snapshot: viewModel.currentMonthSnapshot)
                    .environmentObject(paywallService)
            }
        }
        .onAppear {
            viewModel.loadMonths()
        }
    }
}

// MARK: - Month Row

struct MonthRowView: View {
    let month: Date
    let snapshot: MonthlySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Month name
            Text(month.formatted(.dateTime.month(.wide).year()))
                .font(.headline)

            // Profit indicator
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Net Profit")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(snapshot.formattedProfit)
                        .font(.title3.bold())
                        .foregroundColor(snapshot.isProfit ? .green : .red)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Margin")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(Int(snapshot.profitMargin))%")
                        .font(.title3.bold())
                        .foregroundColor(.secondary)
                }
            }

            // Income vs Expenses
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text(snapshot.formattedIncome)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text(snapshot.formattedExpenses)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Upgrade Prompt

struct UpgradePromptRow: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.blue)
                    Text("Unlock Historical Data")
                        .font(.headline)
                }

                Text("Upgrade to Pro to view all your past months")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Preview

#Preview {
    MonthlyReportsView()
        .environmentObject(PaywallService())
}
