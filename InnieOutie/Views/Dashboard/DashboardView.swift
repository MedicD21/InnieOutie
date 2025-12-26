//
//  DashboardView.swift
//  ProfitLens
//
//  Main dashboard - answers "Am I making money?" in under 5 seconds
//  This is the PRIMARY value proposition of the entire app
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var paywallService: PaywallService
    @State private var showTransactionsList = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Branded header card
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                (Text("Innie")
                                    .foregroundColor(.green)
                                + Text("Outie")
                                    .foregroundColor(.red))
                                    .font(.system(size: 36, weight: .heavy))
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                                Text("Finances Made Easy")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button(action: { showTransactionsList = true }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: "list.bullet.rectangle")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // Month selector
                        MonthPickerView(
                            selectedMonth: $viewModel.selectedMonth,
                            onMonthChange: { newMonth in
                                viewModel.loadMonth(newMonth)
                            }
                        )

                        // Main profit card - THE HERO
                        ProfitCardView(snapshot: viewModel.currentSnapshot)
                            .padding(.horizontal)
                            .transition(.scale.combined(with: .opacity))

                        // Quick stats
                        if !viewModel.currentSnapshot.topCategories.isEmpty ||
                           !viewModel.currentSnapshot.incomeBySource.isEmpty {

                            VStack(spacing: 16) {
                                // Top expense categories
                                if !viewModel.currentSnapshot.topCategories.isEmpty {
                                    TopCategoriesView(
                                        categories: viewModel.currentSnapshot.topCategories
                                    )
                                    .padding(.horizontal)
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                                }

                                // Income sources
                                if !viewModel.currentSnapshot.incomeBySource.isEmpty {
                                    IncomeSourcesView(
                                        sources: viewModel.currentSnapshot.incomeBySource
                                    )
                                    .padding(.horizontal)
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                                }
                            }
                        } else {
                            // Empty state
                            EmptyDashboardView()
                                .padding(.top, 40)
                                .transition(.scale.combined(with: .opacity))
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.top)
                }

                // Quick add bar at bottom
                VStack {
                    Spacer()
                    QuickAddBar(
                        onExpenseAdded: { viewModel.refresh() },
                        onIncomeAdded: { viewModel.refresh() }
                    )
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showExportOptions) {
                ExportOptionsView(snapshot: viewModel.currentSnapshot)
                    .environmentObject(paywallService)
            }
            .sheet(isPresented: $showTransactionsList) {
                TransactionsListView(
                    selectedMonth: viewModel.selectedMonth,
                    onTransactionUpdated: {
                        viewModel.refresh()
                    }
                )
            }
        }
        .onAppear {
            viewModel.loadCurrentMonth()
        }
    }
}

// MARK: - Empty State

struct EmptyDashboardView: View {
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 12) {
                Text("No Data Yet")
                    .font(.title2.bold())
                    .foregroundColor(.primary)

                Text("Start tracking your income and expenses to see your profit")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                    Text("Add Income")
                        .font(.callout.weight(.medium))
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 12) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                    Text("Track Expenses")
                        .font(.callout.weight(.medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 8)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .environmentObject(PaywallService())
}

