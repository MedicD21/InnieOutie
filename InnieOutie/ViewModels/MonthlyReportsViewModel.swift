//
//  MonthlyReportsViewModel.swift
//  ProfitLens
//
//  ViewModel for monthly reports list
//

import Foundation
import SwiftUI

@MainActor
class MonthlyReportsViewModel: ObservableObject {
    @Published var months: [Date] = []
    @Published var snapshots: [Date: MonthlySnapshot] = [:]
    @Published var showExportOptions = false

    private let dataService = DataService()

    var hasMoreMonths: Bool {
        // Free users only see current month
        // If we have older data, show upgrade prompt
        return months.count > 1
    }

    var currentMonthSnapshot: MonthlySnapshot {
        guard let currentMonth = months.first else { return .empty }
        return snapshots[currentMonth] ?? .empty
    }

    func loadMonths() {
        let calendar = Calendar.current
        let now = Date()

        // Generate last 12 months
        var monthsList: [Date] = []
        for i in 0..<12 {
            if let month = calendar.date(byAdding: .month, value: -i, to: now) {
                monthsList.append(month)
            }
        }

        months = monthsList

        // Load snapshots for each month
        for month in monthsList {
            let (expenses, income) = dataService.loadMonthData(month: month)
            let snapshot = CalculationService.calculateMonthlySnapshot(
                expenses: expenses,
                income: income,
                categories: dataService.categories,
                for: month
            )
            snapshots[month] = snapshot
        }
    }
}
