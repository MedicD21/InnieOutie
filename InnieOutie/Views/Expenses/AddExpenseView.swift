//
//  AddExpenseView.swift
//  ProfitLens
//
//  Quick expense entry form - designed for SPEED
//  Minimal friction, maximum clarity
//

import SwiftUI
import PhotosUI

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: AddExpenseViewModel
    @EnvironmentObject var paywallService: PaywallService

    @State private var showDeleteAlert = false
    @State private var showAddCategory = false
    var onSave: (() -> Void)?

    init(expense: Expense? = nil, onSave: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: AddExpenseViewModel(expense: expense))
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            Form {
                // Amount section
                Section {
                    HStack(spacing: 8) {
                        Text("$")
                            .font(.title)
                            .foregroundColor(.secondary)

                        TextField("0.00", text: $viewModel.amountString)
                            .keyboardType(.decimalPad)
                            .font(.title)
                            .foregroundColor(.primary)
                    }
                } header: {
                    Text("Amount")
                }

                // Details section
                Section {
                    DatePicker(
                        "Date",
                        selection: $viewModel.date,
                        displayedComponents: .date
                    )

                    Picker("Category", selection: $viewModel.selectedCategoryId) {
                        ForEach(viewModel.categories) { category in
                            Label(category.name, systemImage: category.icon)
                                .tag(category.id)
                        }
                    }

                    Button(action: { showAddCategory = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("Add New Category")
                                .foregroundColor(.blue)
                        }
                    }

                    TextField("Note (optional)", text: $viewModel.note, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Details")
                }

                // Tags section
                if !viewModel.tags.isEmpty {
                    Section {
                        ForEach(viewModel.tags) { tag in
                            Button(action: {
                                viewModel.toggleTag(tag.id)
                            }) {
                                HStack {
                                    Image(systemName: tag.color.icon)
                                        .foregroundColor(tag.color.color)

                                    Text(tag.name)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    if viewModel.selectedTagIds.contains(tag.id) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Tags (Optional)")
                    } footer: {
                        Text("Tag by project or client")
                    }
                }

                // Receipt section (Pro feature)
                Section {
                    if paywallService.isPro {
                        PhotosPicker(
                            selection: $viewModel.selectedPhoto,
                            matching: .images
                        ) {
                            Label("Add Receipt Photo", systemImage: "camera")
                        }

                        if let receiptImage = viewModel.receiptImage {
                            Image(uiImage: receiptImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(8)
                        }
                    } else {
                        Button(action: {
                            paywallService.showPaywall(with: .uploadReceipt)
                        }) {
                            HStack {
                                Label("Add Receipt Photo", systemImage: "camera")
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Receipt")
                } footer: {
                    if !paywallService.isPro {
                        Text("Receipt storage is a Pro feature")
                    }
                }

                // Delete button (only in edit mode)
                if viewModel.isEditMode {
                    Section {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Delete Expense", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(viewModel.isEditMode ? "Edit Expense" : "Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.save()
                        }
                        onSave?()
                        dismiss()
                    }
                    .disabled(!viewModel.isValid)
                    .fontWeight(.semibold)
                }
            }
            .alert("Delete Expense", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.delete()
                    onSave?()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this expense? This action cannot be undone.")
            }
            .sheet(isPresented: $showAddCategory) {
                QuickAddCategorySheet(onCategoryAdded: {
                    Task {
                        await viewModel.loadCategories()
                    }
                })
            }
        }
    }
}

// MARK: - Quick Add Category Sheet

struct QuickAddCategorySheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var categoryName = ""
    @State private var selectedIcon = "tag.fill"
    var onCategoryAdded: () -> Void

    private let availableIcons = [
        "tag.fill", "cart.fill", "house.fill", "car.fill",
        "fork.knife", "cup.and.saucer.fill", "airplane",
        "bag.fill", "creditcard.fill", "paperplane.fill",
        "gift.fill", "heart.fill", "star.fill", "bolt.fill",
        "wrench.fill"
    ]

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Category Name", text: $categoryName)
                        .autocapitalization(.words)
                } header: {
                    Text("Name")
                }

                Section {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(selectedIcon == icon ? Color.blue.opacity(0.2) : Color(.systemGray6))
                                        .frame(width: 50, height: 50)

                                    Image(systemName: icon)
                                        .font(.title3)
                                        .foregroundColor(selectedIcon == icon ? .blue : .primary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Icon")
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let dataService = DataService()
                        let category = Category(
                            id: UUID().uuidString,
                            name: categoryName.trimmingCharacters(in: .whitespaces),
                            icon: selectedIcon,
                            isDefault: false,
                            sortOrder: 999
                        )
                        dataService.saveCategory(category)
                        onCategoryAdded()
                        dismiss()
                    }
                    .disabled(categoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AddExpenseView()
        .environmentObject(PaywallService())
}
