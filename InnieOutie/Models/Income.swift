//
//  Income.swift
//  ProfitLens
//
//  Core income model for freelancer revenue tracking
//

import Foundation

struct Income: Identifiable, Codable, Hashable {
    let id: String
    var amount: Decimal
    var date: Date
    var source: String  // "Client Name", "Upwork", "Stripe", etc.
    var note: String?
    var tagIds: [String]  // Tags for project/client tracking
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        amount: Decimal,
        date: Date = Date(),
        source: String,
        note: String? = nil,
        tagIds: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.date = date
        self.source = source
        self.note = note
        self.tagIds = tagIds
        self.createdAt = createdAt
    }

    // Formatted amount for display
    var formattedAmount: String {
        amount.formatted(.currency(code: "USD"))
    }
}

// MARK: - Extensions

extension Income {
    /// Check if income is from current month
    var isCurrentMonth: Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)
    }

    /// Get month/year components
    var monthYear: (month: Int, year: Int) {
        let components = Calendar.current.dateComponents([.month, .year], from: date)
        return (components.month ?? 1, components.year ?? 2025)
    }
}
