//
//  IncomeSourcesView.swift
//  ProfitLens
//
//  Shows income by source - helps freelancers understand client revenue
//

import SwiftUI

struct IncomeSourcesView: View {
    let sources: [(source: String, amount: Decimal)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Income Sources")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                ForEach(Array(sources.prefix(5).enumerated()), id: \.offset) { index, item in
                    IncomeSourceRow(
                        source: item.source,
                        amount: item.amount
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct IncomeSourceRow: View {
    let source: String
    let amount: Decimal

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "dollarsign.circle.fill")
                .font(.title3)
                .foregroundColor(.green)

            // Source name
            Text(source)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            // Amount
            Text(amount.formatted(.currency(code: "USD")))
                .font(.subheadline.bold())
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    IncomeSourcesView(
        sources: [
            ("Client A", 3500),
            ("Upwork", 2000),
            ("Stripe Direct", 1200)
        ]
    )
    .padding()
}
