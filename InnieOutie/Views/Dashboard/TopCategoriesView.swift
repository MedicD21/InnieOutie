//
//  TopCategoriesView.swift
//  ProfitLens
//
//  Shows top 3 expense categories - answers "Where is my money going?"
//

import SwiftUI

struct TopCategoriesView: View {
    let categories: [(category: Category, amount: Decimal)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Expenses")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                ForEach(Array(categories.prefix(3).enumerated()), id: \.element.category.id) { index, item in
                    CategoryRow(
                        category: item.category,
                        amount: item.amount,
                        rank: index + 1
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

struct CategoryRow: View {
    let category: Category
    let amount: Decimal
    let rank: Int

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.15))
                    .frame(width: 32, height: 32)

                Text("\(rank)")
                    .font(.caption.bold())
                    .foregroundColor(rankColor)
            }

            // Category icon and name
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                Text(category.name)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            Spacer()

            // Amount
            Text(amount.formatted(.currency(code: "USD")))
                .font(.subheadline.bold())
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        default: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    TopCategoriesView(
        categories: [
            (Category(name: "Software & Tools", icon: "laptopcomputer"), 450),
            (Category(name: "Marketing & Ads", icon: "megaphone"), 320),
            (Category(name: "Platform Fees", icon: "percent"), 180)
        ]
    )
    .padding()
}
