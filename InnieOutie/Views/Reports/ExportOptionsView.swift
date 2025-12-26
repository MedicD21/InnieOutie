//
//  ExportOptionsView.swift
//  ProfitLens
//
//  Export options sheet - CSV and PDF (Pro features)
//

import SwiftUI

struct ExportOptionsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var paywallService: PaywallService

    let snapshot: MonthlySnapshot

    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var shareURL: URL?

    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: exportCSV) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.green)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Export to CSV")
                                    .foregroundColor(.primary)

                                Text("Spreadsheet format for Excel or Google Sheets")
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
                    .disabled(isExporting)

                    Button(action: exportPDF) {
                        HStack {
                            Image(systemName: "doc.richtext")
                                .foregroundColor(.red)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Export to PDF")
                                    .foregroundColor(.primary)

                                Text("Professional report for taxes or clients")
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
                    .disabled(isExporting)

                } header: {
                    Text("Export Options")
                } footer: {
                    if !paywallService.isPro {
                        Text("Export features are available with Pro")
                    }
                }
            }
            .navigationTitle("Export Data")
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
    }

    private func exportCSV() {
        // Check Pro access
        guard paywallService.requestAccess(to: .csvExport, trigger: .exportCSV) else {
            return
        }

        isExporting = true

        Task {
            let dataService = DataService()
            let (expenses, income) = dataService.loadMonthData(month: snapshot.month)

            let csv = ExportService.exportToCSV(
                snapshot: snapshot,
                expenses: expenses,
                income: income,
                categories: dataService.categories
            )

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM"
            let dateString = dateFormatter.string(from: snapshot.month)

            if let url = ExportService.saveCSVToFile(
                csv: csv,
                filename: "innieoutie_\(dateString).csv"
            ) {
                shareURL = url
                showShareSheet = true
            }

            isExporting = false
        }
    }

    private func exportPDF() {
        // Check Pro access
        guard paywallService.requestAccess(to: .pdfExport, trigger: .exportPDF) else {
            return
        }

        isExporting = true

        Task {
            let dataService = DataService()
            let (expenses, income) = dataService.loadMonthData(month: snapshot.month)

            if let pdfData = ExportService.exportToPDF(
                snapshot: snapshot,
                expenses: expenses,
                income: income,
                categories: dataService.categories
            ) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM"
                let dateString = dateFormatter.string(from: snapshot.month)

                if let url = ExportService.savePDFToFile(
                    pdfData: pdfData,
                    filename: "innieoutie_\(dateString).pdf"
                ) {
                    shareURL = url
                    showShareSheet = true
                }
            }

            isExporting = false
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    ExportOptionsView(
        snapshot: MonthlySnapshot(
            month: Date(),
            totalIncome: 5000,
            totalExpenses: 2000,
            netProfit: 3000,
            topCategories: [],
            incomeBySource: []
        )
    )
    .environmentObject(PaywallService())
}
