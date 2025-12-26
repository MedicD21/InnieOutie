//
//  AddIncomeView.swift
//  ProfitLens
//
//  Quick income entry form - designed for SPEED
//  Freelancers track payments from clients and platforms
//

import SwiftUI

struct AddIncomeView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: AddIncomeViewModel

    @State private var showDeleteAlert = false
    var onSave: (() -> Void)?

    init(income: Income? = nil, onSave: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: AddIncomeViewModel(income: income))
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

                    TextField("Client or Source", text: $viewModel.source)
                        .autocapitalization(.words)

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

                // Recent sources for quick selection
                if !viewModel.recentSources.isEmpty {
                    Section {
                        ForEach(viewModel.recentSources, id: \.self) { source in
                            Button(action: {
                                viewModel.source = source
                            }) {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundColor(.secondary)
                                    Text(source)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if viewModel.source == source {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Recent Sources")
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
                                Label("Delete Income", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(viewModel.isEditMode ? "Edit Income" : "Add Income")
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
            .alert("Delete Income", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.delete()
                    onSave?()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this income? This action cannot be undone.")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AddIncomeView()
}
