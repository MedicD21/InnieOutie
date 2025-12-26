//
//  Expense.swift
//  ProfitLens
//
//  Core expense model for freelancer expense tracking
//

import Foundation

struct Expense: Identifiable, Codable, Hashable {
    let id: String
    var amount: Decimal
    var date: Date
    var categoryId: String
    var note: String?
    var receiptPath: String?  // Pro only - stores local file path
    var tagIds: [String]  // Tags for project/client tracking
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        amount: Decimal,
        date: Date = Date(),
        categoryId: String,
        note: String? = nil,
        receiptPath: String? = nil,
        tagIds: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.date = date
        self.categoryId = categoryId
        self.note = note
        self.receiptPath = receiptPath
        self.tagIds = tagIds
        self.createdAt = createdAt
    }

    // Formatted amount for display
    var formattedAmount: String {
        amount.formatted(.currency(code: "USD"))
    }
}

// MARK: - Extensions

extension Expense {
    /// Check if expense is from current month
    var isCurrentMonth: Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)
    }

    /// Get month/year components
    var monthYear: (month: Int, year: Int) {
        let components = Calendar.current.dateComponents([.month, .year], from: date)
        return (components.month ?? 1, components.year ?? 2025)
    }
}
