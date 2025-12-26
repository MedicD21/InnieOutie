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
    @Published var selectedTagIds: Set<String> = []
    @Published var tags: [Tag] = []

    private let dataService = DataService()
    private let recentSourcesKey = "recent_income_sources"
    private var editingIncome: Income?

    init(income: Income? = nil) {
        self.editingIncome = income

        if let income = income {
            self.amountString = "\(income.amount)"
            self.date = income.date
            self.source = income.source
            self.note = income.note ?? ""
            self.selectedTagIds = Set(income.tagIds)
        }

        loadRecentSources()
        loadTags()
    }

    var isEditMode: Bool {
        editingIncome != nil
    }

    var isValid: Bool {
        guard let amount = Decimal(string: amountString), amount > 0 else {
            return false
        }
        return !source.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func loadTags() {
        tags = dataService.tags
    }

    func toggleTag(_ tagId: String) {
        if selectedTagIds.contains(tagId) {
            selectedTagIds.remove(tagId)
        } else {
            selectedTagIds.insert(tagId)
        }
    }

    func save() {
        guard let amount = Decimal(string: amountString) else { return }

        let income = Income(
            id: editingIncome?.id ?? UUID().uuidString,
            amount: amount,
            date: date,
            source: source.trimmingCharacters(in: .whitespaces),
            note: note.isEmpty ? nil : note,
            tagIds: Array(selectedTagIds),
            createdAt: editingIncome?.createdAt ?? Date()
        )

        dataService.saveIncome(income)

        // Update recent sources
        saveToRecentSources(source)
    }

    func delete() {
        guard let income = editingIncome else { return }
        dataService.deleteIncome(income)
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
