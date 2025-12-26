//
//  QuickAddBar.swift
//  ProfitLens
//
//  Quick action buttons for adding expenses/income
//  Designed for SPEED - the core user experience
//

import SwiftUI

struct QuickAddBar: View {
    @State private var showAddExpense = false
    @State private var showAddIncome = false

    var onExpenseAdded: (() -> Void)?
    var onIncomeAdded: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Add Expense
            Button(action: { showAddExpense = true }) {
                Label("Expense", systemImage: "minus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.1))
                    )
                    .foregroundColor(.red)
            }

            // Add Income
            Button(action: { showAddIncome = true }) {
                Label("Income", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                    )
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .sheet(isPresented: $showAddExpense) {
            AddExpenseView(onSave: {
                onExpenseAdded?()
            })
        }
        .sheet(isPresented: $showAddIncome) {
            AddIncomeView(onSave: {
                onIncomeAdded?()
            })
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        QuickAddBar()
    }
}
