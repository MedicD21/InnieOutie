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
    @StateObject private var viewModel = AddIncomeViewModel()

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

                    TextField("Client or Source", text: $viewModel.source)
                        .autocapitalization(.words)

                    TextField("Note (optional)", text: $viewModel.note, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Details")
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
            }
            .navigationTitle("Add Income")
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
    AddIncomeView()
}
