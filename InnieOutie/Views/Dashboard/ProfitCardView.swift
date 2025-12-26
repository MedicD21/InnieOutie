//
//  ProfitCardView.swift
//  ProfitLens
//
//  THE MOST IMPORTANT UI COMPONENT IN THE ENTIRE APP
//  Answers "Am I making money?" at a glance
//

import SwiftUI

struct ProfitCardView: View {
    let snapshot: MonthlySnapshot

    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("Net Profit")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(1)

            // THE BIG NUMBER - hero element
            Text(snapshot.formattedProfit)
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundColor(snapshot.isProfit ? .green : .red)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            // Profit margin
            if snapshot.totalIncome > 0 {
                HStack(spacing: 4) {
                    Text("\(Int(snapshot.profitMargin))% margin")
                        .font(.callout)
                        .foregroundColor(.secondary)

                    // Month-over-month indicator
                    if let momChange = snapshot.momChange {
                        Divider()
                            .frame(height: 12)

                        HStack(spacing: 4) {
                            Image(systemName: momChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption)
                            Text(String(format: "%.1f%%", abs(momChange)))
                                .font(.callout.bold())
                        }
                        .foregroundColor(momChange >= 0 ? .green : .red)
                    }
                }
            }

            Divider()
                .padding(.vertical, 4)

            // Income vs Expenses breakdown
            HStack(spacing: 0) {
                // Income
                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("Income")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(snapshot.formattedIncome)
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 44)

                // Expenses
                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "minus.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text("Expenses")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(snapshot.formattedExpenses)
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}

// MARK: - Preview

#Preview("Profitable Month") {
    ProfitCardView(
        snapshot: MonthlySnapshot(
            month: Date(),
            totalIncome: 8500,
            totalExpenses: 3200,
            netProfit: 5300,
            topCategories: [],
            incomeBySource: [],
            momChange: 15.5
        )
    )
    .padding()
}

#Preview("Unprofitable Month") {
    ProfitCardView(
        snapshot: MonthlySnapshot(
            month: Date(),
            totalIncome: 2000,
            totalExpenses: 3500,
            netProfit: -1500,
            topCategories: [],
            incomeBySource: [],
            momChange: -8.2
        )
    )
    .padding()
}

#Preview("Empty") {
    ProfitCardView(snapshot: .empty)
        .padding()
}
