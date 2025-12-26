//
//  TransactionsListView.swift
//  InnieOutie
//
//  Detailed list of all transactions for a given month with edit capability
//

import SwiftUI

struct TransactionsListView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var paywallService: PaywallService
    @StateObject private var dataService = DataService()

    let selectedMonth: Date
    var onTransactionUpdated: () -> Void

    @State private var expenses: [Expense] = []
    @State private var income: [Income] = []
    @State private var selectedExpense: Expense?
    @State private var selectedIncome: Income?
    @State private var showEditExpense = false
    @State private var showEditIncome = false
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            List {
                // Income Section
                if !filteredIncome.isEmpty {
                    Section {
                        ForEach(filteredIncome) { incomeItem in
                            Button(action: {
                                selectedIncome = incomeItem
                                showEditIncome = true
                            }) {
                                TransactionRow(
                                    amount: incomeItem.amount,
                                    title: incomeItem.source,
                                    subtitle: incomeItem.note,
                                    date: incomeItem.date,
                                    isIncome: true,
                                    tags: getTags(for: incomeItem.tagIds)
                                )
                            }
                        }
                    } header: {
                        HStack {
                            Text("Income")
                            Spacer()
                            Text(totalIncome.formatted(.currency(code: "USD")))
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                        }
                    }
                }

                // Expenses Section
                if !filteredExpenses.isEmpty {
                    Section {
                        ForEach(filteredExpenses) { expense in
                            Button(action: {
                                selectedExpense = expense
                                showEditExpense = true
                            }) {
                                TransactionRow(
                                    amount: expense.amount,
                                    title: getCategory(for: expense.categoryId)?.name ?? "Unknown",
                                    subtitle: expense.note,
                                    date: expense.date,
                                    isIncome: false,
                                    tags: getTags(for: expense.tagIds),
                                    categoryIcon: getCategory(for: expense.categoryId)?.icon
                                )
                            }
                        }
                    } header: {
                        HStack {
                            Text("Expenses")
                            Spacer()
                            Text(totalExpenses.formatted(.currency(code: "USD")))
                                .foregroundColor(.red)
                                .fontWeight(.semibold)
                        }
                    }
                }

                // Empty state
                if filteredIncome.isEmpty && filteredExpenses.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: searchText.isEmpty ? "tray" : "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)

                            Text(searchText.isEmpty ? "No transactions this month" : "No matching transactions")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
            }
            .navigationTitle(monthTitle)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search transactions")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showEditExpense) {
                if let expense = selectedExpense {
                    AddExpenseView(expense: expense) {
                        loadTransactions()
                        onTransactionUpdated()
                    }
                    .environmentObject(paywallService)
                }
            }
            .sheet(isPresented: $showEditIncome) {
                if let income = selectedIncome {
                    AddIncomeView(income: income) {
                        loadTransactions()
                        onTransactionUpdated()
                    }
                }
            }
            .onAppear {
                loadTransactions()
            }
        }
    }

    // MARK: - Computed Properties

    private var monthTitle: String {
        selectedMonth.formatted(.dateTime.month(.wide).year())
    }

    private var filteredIncome: [Income] {
        if searchText.isEmpty {
            return income.sorted { $0.date > $1.date }
        }
        return income.filter {
            $0.source.localizedCaseInsensitiveContains(searchText) ||
            ($0.note?.localizedCaseInsensitiveContains(searchText) ?? false)
        }.sorted { $0.date > $1.date }
    }

    private var filteredExpenses: [Expense] {
        if searchText.isEmpty {
            return expenses.sorted { $0.date > $1.date }
        }
        return expenses.filter {
            (getCategory(for: $0.categoryId)?.name.localizedCaseInsensitiveContains(searchText) ?? false) ||
            ($0.note?.localizedCaseInsensitiveContains(searchText) ?? false)
        }.sorted { $0.date > $1.date }
    }

    private var totalIncome: Decimal {
        filteredIncome.reduce(0) { $0 + $1.amount }
    }

    private var totalExpenses: Decimal {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Helper Methods

    private func loadTransactions() {
        let (loadedExpenses, loadedIncome) = dataService.loadMonthData(month: selectedMonth)
        expenses = loadedExpenses
        income = loadedIncome
    }

    private func getCategory(for id: String) -> Category? {
        dataService.categories.first { $0.id == id }
    }

    private func getTags(for ids: [String]) -> [Tag] {
        dataService.tags.filter { ids.contains($0.id) }
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let amount: Decimal
    let title: String
    let subtitle: String?
    let date: Date
    let isIncome: Bool
    let tags: [Tag]
    var categoryIcon: String?

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            if let icon = categoryIcon {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 32)
            } else {
                Image(systemName: isIncome ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .font(.title3)
                    .foregroundColor(isIncome ? .green : .red)
                    .frame(width: 32)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                if let subtitle = subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Tags
                if !tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(tags) { tag in
                                HStack(spacing: 4) {
                                    Image(systemName: "tag.fill")
                                        .font(.system(size: 8))
                                    Text(tag.name)
                                        .font(.caption2)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(tag.color.color.opacity(0.15))
                                .foregroundColor(tag.color.color)
                                .cornerRadius(4)
                            }
                        }
                    }
                }
            }

            Spacer()

            // Amount and Date
            VStack(alignment: .trailing, spacing: 4) {
                Text(amount.formatted(.currency(code: "USD")))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(isIncome ? .green : .red)

                Text(date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    TransactionsListView(selectedMonth: Date()) {
        // Preview callback
    }
    .environmentObject(PaywallService())
}
