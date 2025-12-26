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
            // Header with icon
            HStack(spacing: 8) {
                Image(systemName: snapshot.isProfit ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .font(.title3)
                    .foregroundColor(snapshot.isProfit ? .green : .red)

                Text("Net Profit")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(1)
            }

            // THE BIG NUMBER - hero element with gradient
            Text(snapshot.formattedProfit)
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: snapshot.isProfit ?
                            [.green, .green.opacity(0.8)] :
                            [.red, .red.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .shadow(color: (snapshot.isProfit ? Color.green : Color.red).opacity(0.3), radius: 8, x: 0, y: 4)

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
        .padding(28)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.secondarySystemBackground))

                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                (snapshot.isProfit ? Color.green : Color.red).opacity(0.3),
                                (snapshot.isProfit ? Color.green : Color.red).opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            }
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
            .shadow(color: (snapshot.isProfit ? Color.green : Color.red).opacity(0.1), radius: 20, x: 0, y: 10)
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
