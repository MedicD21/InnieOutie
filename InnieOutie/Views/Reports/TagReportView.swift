//
//  TagReportView.swift
//  ProfitLens
//
//  Tag-based project/client reporting
//  Perfect for freelancers tracking multiple projects
//

import SwiftUI

struct TagReportView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var paywallService: PaywallService
    @StateObject private var viewModel = TagReportViewModel()

    @State private var selectedTagId: String = ""
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var showShareSheet = false
    @State private var shareURL: URL?
    @State private var isExporting = false

    var body: some View {
        NavigationView {
            Form {
                // Tag selection
                Section {
                    Picker("Project/Client Tag", selection: $selectedTagId) {
                        Text("Select a tag").tag("")
                        ForEach(viewModel.tags) { tag in
                            Label {
                                Text(tag.name)
                            } icon: {
                                Image(systemName: tag.color.icon)
                                    .foregroundColor(tag.color.color)
                            }
                            .tag(tag.id)
                        }
                    }
                } header: {
                    Text("Tag Selection")
                } footer: {
                    Text("Choose the project or client tag to generate a report for")
                }

                // Date range
                Section {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)

                    // Quick date range buttons
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            QuickDateButton(title: "This Month") {
                                let calendar = Calendar.current
                                startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
                                endDate = Date()
                            }
                            QuickDateButton(title: "Last 3 Months") {
                                startDate = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
                                endDate = Date()
                            }
                        }

                        HStack(spacing: 8) {
                            QuickDateButton(title: "Last 6 Months") {
                                startDate = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
                                endDate = Date()
                            }
                            QuickDateButton(title: "This Year") {
                                let calendar = Calendar.current
                                let year = calendar.component(.year, from: Date())
                                startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
                                endDate = Date()
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Date Range")
                } footer: {
                    Text("Select the date range for the report")
                }

                // Preview section
                if let selectedTag = viewModel.tags.first(where: { $0.id == selectedTagId }),
                   !selectedTagId.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: selectedTag.color.icon)
                                    .foregroundColor(selectedTag.color.color)
                                Text(selectedTag.name)
                                    .font(.headline)
                                Spacer()
                            }

                            HStack {
                                Text("Period:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(startDate.formatted(date: .abbreviated, time: .omitted)) - \(endDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.callout)
                            }

                            if let stats = viewModel.getTagStats(
                                tagId: selectedTagId,
                                startDate: startDate,
                                endDate: endDate
                            ) {
                                Divider()
                                    .padding(.vertical, 4)

                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Income")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(formatCurrency(stats.income))
                                            .font(.title3.bold())
                                            .foregroundColor(.green)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Expenses")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(formatCurrency(stats.expenses))
                                            .font(.title3.bold())
                                            .foregroundColor(.red)
                                    }
                                }

                                Divider()
                                    .padding(.vertical, 4)

                                HStack {
                                    Text("Net Profit")
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    Text(formatCurrency(stats.profit))
                                        .font(.title3.bold())
                                        .foregroundColor(stats.profit >= 0 ? .green : .red)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    } header: {
                        Text("Report Preview")
                    }
                }

                // Export button
                Section {
                    Button(action: exportReport) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Generate Report")
                                    .foregroundColor(.primary)

                                Text("Export detailed CSV report with all transactions")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if !paywallService.isPro {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                    .disabled(selectedTagId.isEmpty || isExporting)
                } footer: {
                    if !paywallService.isPro {
                        Text("Tag reports are a Pro feature")
                    }
                }
            }
            .navigationTitle("Project Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = shareURL {
                    ShareSheet(items: [url])
                }
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }

    private func exportReport() {
        guard paywallService.requestAccess(to: .csvExport, trigger: .exportCSV) else {
            return
        }

        guard let tag = viewModel.tags.first(where: { $0.id == selectedTagId }) else {
            return
        }

        isExporting = true

        Task {
            let csv = ExportService.exportByTag(
                tag: tag,
                dateRange: startDate...endDate,
                allExpenses: viewModel.allExpenses,
                allIncome: viewModel.allIncome,
                categories: viewModel.categories
            )

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let startStr = dateFormatter.string(from: startDate)
            let endStr = dateFormatter.string(from: endDate)

            let safeName = tag.name.replacingOccurrences(of: " ", with: "_")

            if let url = ExportService.saveCSVToFile(
                csv: csv,
                filename: "project_\(safeName)_\(startStr)_to_\(endStr).csv"
            ) {
                shareURL = url
                showShareSheet = true
            }

            isExporting = false
        }
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
}

// MARK: - Quick Date Button

struct QuickDateButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - ViewModel

@MainActor
class TagReportViewModel: ObservableObject {
    @Published var tags: [Tag] = []
    @Published var allExpenses: [Expense] = []
    @Published var allIncome: [Income] = []
    @Published var categories: [Category] = []

    private let dataService = DataService()

    func loadData() {
        tags = dataService.tags
        allExpenses = dataService.allExpenses
        allIncome = dataService.allIncome
        categories = dataService.categories
    }

    struct TagStats {
        let income: Decimal
        let expenses: Decimal
        let profit: Decimal
    }

    func getTagStats(tagId: String, startDate: Date, endDate: Date) -> TagStats? {
        let dateRange = startDate...endDate

        let taggedExpenses = allExpenses.filter {
            $0.tagIds.contains(tagId) && dateRange.contains($0.date)
        }
        let taggedIncome = allIncome.filter {
            $0.tagIds.contains(tagId) && dateRange.contains($0.date)
        }

        let income = taggedIncome.reduce(Decimal(0)) { $0 + $1.amount }
        let expenses = taggedExpenses.reduce(Decimal(0)) { $0 + $1.amount }
        let profit = income - expenses

        return TagStats(income: income, expenses: expenses, profit: profit)
    }
}

// MARK: - Preview

#Preview {
    TagReportView()
        .environmentObject(PaywallService())
}
