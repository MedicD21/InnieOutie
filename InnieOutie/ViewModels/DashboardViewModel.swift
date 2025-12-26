//
//  DashboardViewModel.swift
//  ProfitLens
//
//  ViewModel for Dashboard - handles data loading and calculations
//

import Foundation
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var currentSnapshot: MonthlySnapshot = .empty
    @Published var selectedMonth: Date = Date()
    @Published var showExportOptions = false

    private let dataService = DataService()

    init() {
        loadCurrentMonth()
    }

    /// Load current month data
    func loadCurrentMonth() {
        selectedMonth = Date()
        loadMonth(selectedMonth)
    }

    /// Load specific month data
    func loadMonth(_ month: Date) {
        selectedMonth = month

        // Get month data
        let (expenses, income) = dataService.loadMonthData(month: month)

        // Calculate snapshot
        currentSnapshot = CalculationService.calculateMonthlySnapshot(
            expenses: expenses,
            income: income,
            categories: dataService.categories,
            for: month
        )

        // Calculate MoM change if viewing current month
        if Calendar.current.isDate(month, equalTo: Date(), toGranularity: .month) {
            calculateMoMChange()
        }
    }

    /// Refresh current view
    func refresh() {
        dataService.loadCurrentMonthData()
        loadMonth(selectedMonth)
    }

    /// Calculate month-over-month change
    private func calculateMoMChange() {
        guard let previousMonth = CalculationService.previousMonth(from: selectedMonth) else {
            return
        }

        let (prevExpenses, prevIncome) = dataService.loadMonthData(month: previousMonth)
        let prevSnapshot = CalculationService.calculateMonthlySnapshot(
            expenses: prevExpenses,
            income: prevIncome,
            categories: dataService.categories,
            for: previousMonth
        )

        let change = CalculationService.calculateMoMChange(
            current: currentSnapshot,
            previous: prevSnapshot
        )

        // Update snapshot with MoM change
        var updatedSnapshot = currentSnapshot
        updatedSnapshot.momChange = change
        currentSnapshot = updatedSnapshot
    }
}
