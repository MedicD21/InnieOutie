//
//  CalculationService.swift
//  ProfitLens
//
//  Core business logic for profit calculations
//  This is the heart of ProfitLens - answering "Am I making money?"
//

import Foundation

class CalculationService {

    /// Calculate monthly snapshot for given month
    /// This is the PRIMARY value proposition of the app
    static func calculateMonthlySnapshot(
        expenses: [Expense],
        income: [Income],
        categories: [Category],
        for month: Date
    ) -> MonthlySnapshot {

        let calendar = Calendar.current
        let monthComponents = calendar.dateComponents([.year, .month], from: month)

        // Filter to current month
        let monthExpenses = expenses.filter { expense in
            calendar.dateComponents([.year, .month], from: expense.date) == monthComponents
        }

        let monthIncome = income.filter { inc in
            calendar.dateComponents([.year, .month], from: inc.date) == monthComponents
        }

        // Calculate totals
        let totalIncome = monthIncome.reduce(Decimal(0)) { $0 + $1.amount }
        let totalExpenses = monthExpenses.reduce(Decimal(0)) { $0 + $1.amount }
        let netProfit = totalIncome - totalExpenses

        // Top 3 expense categories
        let categoryMap = Dictionary(grouping: monthExpenses) { $0.categoryId }
        let categorySums = categoryMap.map { (categoryId, expenses) -> (Category, Decimal) in
            let category = categories.first(where: { $0.id == categoryId }) ??
                           Category(id: categoryId, name: "Unknown", icon: "questionmark.circle")
            let sum = expenses.reduce(Decimal(0)) { $0 + $1.amount }
            return (category, sum)
        }
        .sorted { $0.1 > $1.1 }
        .prefix(3)

        // Income by source
        let sourceMap = Dictionary(grouping: monthIncome) { $0.source }
        let sourceSums = sourceMap.map { (source, incomes) -> (String, Decimal) in
            let sum = incomes.reduce(Decimal(0)) { $0 + $1.amount }
            return (source, sum)
        }
        .sorted { $0.1 > $1.1 }

        return MonthlySnapshot(
            month: month,
            totalIncome: totalIncome,
            totalExpenses: totalExpenses,
            netProfit: netProfit,
            topCategories: Array(categorySums),
            incomeBySource: Array(sourceSums),
            momChange: nil
        )
    }

    /// Calculate month-over-month change percentage
    static func calculateMoMChange(current: MonthlySnapshot, previous: MonthlySnapshot) -> Double {
        guard previous.netProfit != 0 else {
            // If previous month was zero, show change based on current
            return current.netProfit > 0 ? 100 : 0
        }

        let change = current.netProfit - previous.netProfit
        return Double(truncating: (change / previous.netProfit * 100) as NSNumber)
    }

    /// Get month start and end dates
    static func monthRange(for date: Date) -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return nil
        }
        return (startOfMonth, endOfMonth)
    }

    /// Get previous month date
    static func previousMonth(from date: Date) -> Date? {
        Calendar.current.date(byAdding: .month, value: -1, to: date)
    }

    /// Get next month date
    static func nextMonth(from date: Date) -> Date? {
        Calendar.current.date(byAdding: .month, value: 1, to: date)
    }

    /// Check if user is in free tier limits (current month only for free users)
    static func isWithinFreeTierLimit(date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date, equalTo: Date(), toGranularity: .month)
    }
}
