//
//  MonthlySnapshot.swift
//  ProfitLens
//
//  Monthly financial summary - the core value proposition
//

import Foundation

struct MonthlySnapshot {
    let month: Date
    let totalIncome: Decimal
    let totalExpenses: Decimal
    let netProfit: Decimal
    let topCategories: [(category: Category, amount: Decimal)]
    let incomeBySource: [(source: String, amount: Decimal)]
    var momChange: Double?  // Month-over-month change percentage

    /// Is this month profitable?
    var isProfit: Bool {
        netProfit > 0
    }

    /// Profit margin percentage
    var profitMargin: Double {
        guard totalIncome > 0 else { return 0 }
        return Double(truncating: (netProfit / totalIncome * 100) as NSNumber)
    }

    /// Formatted values for display
    var formattedIncome: String {
        totalIncome.formatted(.currency(code: "USD"))
    }

    var formattedExpenses: String {
        totalExpenses.formatted(.currency(code: "USD"))
    }

    var formattedProfit: String {
        netProfit.formatted(.currency(code: "USD"))
    }

    /// Month name for display
    var monthName: String {
        month.formatted(.dateTime.month(.wide).year())
    }

    /// Empty state
    static var empty: MonthlySnapshot {
        MonthlySnapshot(
            month: Date(),
            totalIncome: 0,
            totalExpenses: 0,
            netProfit: 0,
            topCategories: [],
            incomeBySource: [],
            momChange: nil
        )
    }
}

// MARK: - User Model for Authentication

struct User: Codable {
    let id: String
    var email: String?
    var fullName: String?
    var isGuest: Bool
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        email: String? = nil,
        fullName: String? = nil,
        isGuest: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.isGuest = isGuest
        self.createdAt = createdAt
    }
}
