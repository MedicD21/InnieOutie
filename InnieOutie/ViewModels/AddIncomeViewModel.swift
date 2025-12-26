//
//  AddIncomeViewModel.swift
//  ProfitLens
//
//  ViewModel for income entry
//

import Foundation
import SwiftUI

@MainActor
class AddIncomeViewModel: ObservableObject {
    @Published var amountString: String = ""
    @Published var date: Date = Date()
    @Published var source: String = ""
    @Published var note: String = ""
    @Published var recentSources: [String] = []

    private let dataService = DataService()
    private let recentSourcesKey = "recent_income_sources"

    init() {
        loadRecentSources()
    }

    var isValid: Bool {
        guard let amount = Decimal(string: amountString), amount > 0 else {
            return false
        }
        return !source.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func save() {
        guard let amount = Decimal(string: amountString) else { return }

        let income = Income(
            amount: amount,
            date: date,
            source: source.trimmingCharacters(in: .whitespaces),
            note: note.isEmpty ? nil : note
        )

        dataService.saveIncome(income)

        // Update recent sources
        saveToRecentSources(source)
    }

    private func loadRecentSources() {
        if let sources = UserDefaults.standard.stringArray(forKey: recentSourcesKey) {
            recentSources = Array(sources.prefix(5))
        }
    }

    private func saveToRecentSources(_ source: String) {
        var sources = UserDefaults.standard.stringArray(forKey: recentSourcesKey) ?? []

        // Remove if already exists
        sources.removeAll { $0 == source }

        // Add to beginning
        sources.insert(source, at: 0)

        // Keep only 5 most recent
        sources = Array(sources.prefix(5))

        UserDefaults.standard.set(sources, forKey: recentSourcesKey)
    }
}
