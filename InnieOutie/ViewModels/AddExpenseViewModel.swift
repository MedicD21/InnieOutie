//
//  AddExpenseViewModel.swift
//  ProfitLens
//
//  ViewModel for expense entry
//

import Foundation
import SwiftUI
import PhotosUI

@MainActor
class AddExpenseViewModel: ObservableObject {
    @Published var amountString: String = ""
    @Published var date: Date = Date()
    @Published var selectedCategoryId: String = ""
    @Published var note: String = ""
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var receiptImage: UIImage?
    @Published var selectedTagIds: Set<String> = []

    @Published var categories: [Category] = []
    @Published var tags: [Tag] = []

    private let dataService = DataService()
    private var editingExpense: Expense?

    init(expense: Expense? = nil) {
        self.editingExpense = expense

        if let expense = expense {
            self.amountString = "\(expense.amount)"
            self.date = expense.date
            self.selectedCategoryId = expense.categoryId
            self.note = expense.note ?? ""
            self.selectedTagIds = Set(expense.tagIds)
            // Load receipt image if exists
            if let receiptPath = expense.receiptPath {
                loadReceiptImage(from: receiptPath)
            }
        }

        loadCategories()
        loadTags()
    }

    var isEditMode: Bool {
        editingExpense != nil
    }

    var isValid: Bool {
        guard let amount = Decimal(string: amountString), amount > 0 else {
            return false
        }
        return !selectedCategoryId.isEmpty
    }

    func loadCategories() {
        categories = dataService.categories

        // Select first category by default
        if selectedCategoryId.isEmpty, let firstCategory = categories.first {
            selectedCategoryId = firstCategory.id
        }
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

        var receiptPath: String? = editingExpense?.receiptPath

        // Save receipt image if provided (Pro feature)
        if let image = receiptImage {
            receiptPath = saveReceiptImage(image)
        }

        let expense = Expense(
            id: editingExpense?.id ?? UUID().uuidString,
            amount: amount,
            date: date,
            categoryId: selectedCategoryId,
            note: note.isEmpty ? nil : note,
            receiptPath: receiptPath,
            tagIds: Array(selectedTagIds),
            createdAt: editingExpense?.createdAt ?? Date()
        )

        dataService.saveExpense(expense)
    }

    func delete() {
        guard let expense = editingExpense else { return }
        dataService.deleteExpense(expense)
    }

    private func saveReceiptImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.7) else { return nil }

        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let receiptsPath = documentsPath.appendingPathComponent("receipts", isDirectory: true)

        // Create receipts directory if needed
        try? fileManager.createDirectory(at: receiptsPath, withIntermediateDirectories: true)

        let filename = "\(UUID().uuidString).jpg"
        let fileURL = receiptsPath.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            print("Error saving receipt: \(error)")
            return nil
        }
    }

    // Photo picker handling
    func loadImage() {
        Task {
            guard let selectedPhoto = selectedPhoto else { return }

            if let data = try? await selectedPhoto.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                self.receiptImage = image
            }
        }
    }

    private func loadReceiptImage(from path: String) {
        if let image = UIImage(contentsOfFile: path) {
            self.receiptImage = image
        }
    }
}
