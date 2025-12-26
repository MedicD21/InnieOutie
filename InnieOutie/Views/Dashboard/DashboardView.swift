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

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
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

                        // Quick stats
                        if !viewModel.currentSnapshot.topCategories.isEmpty ||
                           !viewModel.currentSnapshot.incomeBySource.isEmpty {

                            VStack(spacing: 20) {
                                // Top expense categories
                                if !viewModel.currentSnapshot.topCategories.isEmpty {
                                    TopCategoriesView(
                                        categories: viewModel.currentSnapshot.topCategories
                                    )
                                    .padding(.horizontal)
                                }

                                // Income sources
                                if !viewModel.currentSnapshot.incomeBySource.isEmpty {
                                    IncomeSourcesView(
                                        sources: viewModel.currentSnapshot.incomeBySource
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        } else {
                            // Empty state
                            EmptyDashboardView()
                                .padding(.top, 40)
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
            .navigationTitle("InnieOutie")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { viewModel.refresh() }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }

                        Button(action: { viewModel.showExportOptions = true }) {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showExportOptions) {
                ExportOptionsView(snapshot: viewModel.currentSnapshot)
                    .environmentObject(paywallService)
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
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                .font(.system(size: 64))
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                Text("No Data Yet")
                    .font(.title2.bold())

                Text("Start tracking your income and expenses to see your profit")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Text("Tap the buttons below to get started")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .environmentObject(PaywallService())
}
