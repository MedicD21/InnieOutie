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
    @StateObject private var viewModel = AddExpenseViewModel()
    @EnvironmentObject var paywallService: PaywallService

    var onSave: (() -> Void)?

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

                    TextField("Note (optional)", text: $viewModel.note, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Details")
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
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save()
                        onSave?()
                        dismiss()
                    }
                    .disabled(!viewModel.isValid)
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
