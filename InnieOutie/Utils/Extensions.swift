//
//  Extensions.swift
//  ProfitLens
//
//  Helpful extensions and utilities
//

import Foundation
import SwiftUI

// MARK: - Decimal Extensions

extension Decimal {
    /// Format as USD currency
    var currencyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: self as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Date Extensions

extension Date {
    /// Check if date is in current month
    var isCurrentMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }

    /// Get start of month
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }

    /// Get end of month
    var endOfMonth: Date {
        let calendar = Calendar.current
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) {
            return calendar.date(byAdding: .day, value: -1, to: nextMonth) ?? self
        }
        return self
    }

    /// Format as "Month Year"
    var monthYearString: String {
        formatted(.dateTime.month(.wide).year())
    }
}

// MARK: - Color Extensions

extension Color {
    /// App theme colors
    static let profitGreen = Color.green
    static let expenseRed = Color.red
    static let neutralGray = Color.gray

    /// Dynamic color for profit/loss
    static func profitColor(for amount: Decimal) -> Color {
        amount >= 0 ? .profitGreen : .expenseRed
    }
}

// MARK: - String Extensions

extension String {
    /// Validate decimal input
    var isValidDecimal: Bool {
        return Decimal(string: self) != nil
    }

    /// Clean decimal string (remove invalid characters)
    var cleanedDecimal: String {
        let allowed = CharacterSet(charactersIn: "0123456789.")
        return self.filter { String($0).rangeOfCharacter(from: allowed) != nil }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply card style
    func cardStyle(padding: CGFloat = 16, cornerRadius: CGFloat = 12) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(.secondarySystemBackground))
            )
    }

    /// Conditional modifier
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
