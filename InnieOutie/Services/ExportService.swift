//
//  ExportService.swift
//  ProfitLens
//
//  CSV and PDF export functionality (Pro feature)
//  Tax-friendly formatting for freelancers
//

import Foundation
import UIKit
import PDFKit

class ExportService {

    // MARK: - CSV Export

    /// Export monthly data to CSV format
    /// Pro feature - tax-friendly format
    static func exportToCSV(
        snapshot: MonthlySnapshot,
        expenses: [Expense],
        income: [Income],
        categories: [Category]
    ) -> String {
        var csv = ""

        // Header with month info
        csv += "InnieOutie Monthly Report\n"
        csv += "Finances Made Easy\n"
        csv += "Month: \(snapshot.monthName)\n"
        csv += "Generated: \(Date().formatted(date: .long, time: .standard))\n"
        csv += "\n"

        // Summary section
        csv += "SUMMARY\n"
        csv += "Total Income,\(snapshot.totalIncome)\n"
        csv += "Total Expenses,\(snapshot.totalExpenses)\n"
        csv += "Net Profit,\(snapshot.netProfit)\n"
        csv += "Profit Margin,\(String(format: "%.1f%%", snapshot.profitMargin))\n"
        csv += "\n"

        // Income detail
        csv += "INCOME DETAIL\n"
        csv += "Date,Source,Amount,Note\n"

        for inc in income.sorted(by: { $0.date > $1.date }) {
            let dateStr = inc.date.formatted(date: .numeric, time: .omitted)
            let note = inc.note?.replacingOccurrences(of: ",", with: ";") ?? ""
            csv += "\(dateStr),\(inc.source),\(inc.amount),\(note)\n"
        }

        csv += "\n"

        // Expense detail
        csv += "EXPENSE DETAIL\n"
        csv += "Date,Category,Amount,Note\n"

        for exp in expenses.sorted(by: { $0.date > $1.date }) {
            let dateStr = exp.date.formatted(date: .numeric, time: .omitted)
            let categoryName = categories.first(where: { $0.id == exp.categoryId })?.name ?? "Unknown"
            let note = exp.note?.replacingOccurrences(of: ",", with: ";") ?? ""
            csv += "\(dateStr),\(categoryName),\(exp.amount),\(note)\n"
        }

        csv += "\n"

        // Category breakdown
        csv += "EXPENSE BY CATEGORY\n"
        csv += "Category,Amount,Percentage\n"

        for (category, amount) in snapshot.topCategories {
            let percentage = snapshot.totalExpenses > 0 ?
                Double(truncating: (amount / snapshot.totalExpenses * 100) as NSNumber) : 0
            csv += "\(category.name),\(amount),\(String(format: "%.1f%%", percentage))\n"
        }

        return csv
    }

    /// Save CSV to temporary file and return URL
    static func saveCSVToFile(csv: String, filename: String = "innieoutie_export.csv") -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)

        do {
            // Ensure the file doesn't already exist
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }

            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error saving CSV: \(error)")
            return nil
        }
    }

    // MARK: - PDF Export

    /// Export monthly data to PDF format
    /// Pro feature - professional summary for clients or taxes
    static func exportToPDF(
        snapshot: MonthlySnapshot,
        expenses: [Expense],
        income: [Income],
        categories: [Category]
    ) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "InnieOutie",
            kCGPDFContextTitle: "Monthly Financial Summary",
            kCGPDFContextAuthor: "InnieOutie App"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            var yOffset: CGFloat = 40

            // Title
            yOffset = drawText(
                "InnieOutie",
                at: CGPoint(x: 50, y: yOffset),
                font: .systemFont(ofSize: 32, weight: .bold),
                color: .systemBlue
            )

            yOffset += 5
            yOffset = drawText(
                "Finances Made Easy",
                at: CGPoint(x: 50, y: yOffset),
                font: .systemFont(ofSize: 14),
                color: .systemBlue
            )

            yOffset += 10
            yOffset = drawText(
                "Monthly Financial Summary",
                at: CGPoint(x: 50, y: yOffset),
                font: .systemFont(ofSize: 18, weight: .medium)
            )

            yOffset += 5
            yOffset = drawText(
                snapshot.monthName,
                at: CGPoint(x: 50, y: yOffset),
                font: .systemFont(ofSize: 14),
                color: .gray
            )

            yOffset += 30

            // Summary box with border
            let summaryRect = CGRect(x: 50, y: yOffset, width: 512, height: 120)
            drawBox(rect: summaryRect, fillColor: .systemGray6, borderColor: .systemGray4)

            yOffset += 20

            // Net Profit (large and prominent)
            yOffset = drawText(
                "Net Profit",
                at: CGPoint(x: 70, y: yOffset),
                font: .systemFont(ofSize: 14),
                color: .gray
            )

            yOffset += 5
            yOffset = drawText(
                snapshot.formattedProfit,
                at: CGPoint(x: 70, y: yOffset),
                font: .systemFont(ofSize: 36, weight: .bold),
                color: snapshot.isProfit ? .systemGreen : .systemRed
            )

            // Income and Expenses side by side
            let leftX: CGFloat = 70
            let rightX: CGFloat = 320

            let savedY = yOffset
            yOffset += 10

            yOffset = drawText("Total Income", at: CGPoint(x: leftX, y: yOffset), font: .systemFont(ofSize: 12), color: .gray)
            yOffset = drawText(snapshot.formattedIncome, at: CGPoint(x: leftX, y: yOffset), font: .systemFont(ofSize: 18, weight: .semibold))

            yOffset = savedY + 10
            yOffset = drawText("Total Expenses", at: CGPoint(x: rightX, y: yOffset), font: .systemFont(ofSize: 12), color: .gray)
            yOffset = drawText(snapshot.formattedExpenses, at: CGPoint(x: rightX, y: yOffset), font: .systemFont(ofSize: 18, weight: .semibold))

            yOffset = max(yOffset, summaryRect.maxY + 30)

            // Top Expense Categories
            yOffset = drawText(
                "Top Expense Categories",
                at: CGPoint(x: 50, y: yOffset),
                font: .systemFont(ofSize: 18, weight: .semibold)
            )

            yOffset += 15

            for (category, amount) in snapshot.topCategories.prefix(5) {
                let percentage = snapshot.totalExpenses > 0 ?
                    Double(truncating: (amount / snapshot.totalExpenses * 100) as NSNumber) : 0

                let categoryText = "\(category.name)"
                let amountText = "\(amount.formatted(.currency(code: "USD"))) (\(String(format: "%.0f%%", percentage)))"

                yOffset = drawText(categoryText, at: CGPoint(x: 70, y: yOffset), font: .systemFont(ofSize: 14))
                drawText(amountText, at: CGPoint(x: 400, y: yOffset - 14), font: .systemFont(ofSize: 14, weight: .medium))

                yOffset += 5
            }

            yOffset += 20

            // Income Sources
            if !snapshot.incomeBySource.isEmpty {
                yOffset = drawText(
                    "Income by Source",
                    at: CGPoint(x: 50, y: yOffset),
                    font: .systemFont(ofSize: 18, weight: .semibold)
                )

                yOffset += 15

                for (source, amount) in snapshot.incomeBySource.prefix(5) {
                    let percentage = snapshot.totalIncome > 0 ?
                        Double(truncating: (amount / snapshot.totalIncome * 100) as NSNumber) : 0

                    let amountText = "\(amount.formatted(.currency(code: "USD"))) (\(String(format: "%.0f%%", percentage)))"

                    yOffset = drawText(source, at: CGPoint(x: 70, y: yOffset), font: .systemFont(ofSize: 14))
                    drawText(amountText, at: CGPoint(x: 400, y: yOffset - 14), font: .systemFont(ofSize: 14, weight: .medium))

                    yOffset += 5
                }
            }

            // Footer
            let footerY: CGFloat = 750
            drawText(
                "Generated by InnieOutie on \(Date().formatted(date: .long, time: .omitted))",
                at: CGPoint(x: 50, y: footerY),
                font: .systemFont(ofSize: 10),
                color: .gray
            )
        }

        return data
    }

    /// Save PDF to temporary file and return URL
    static func savePDFToFile(pdfData: Data, filename: String = "innieoutie_report.pdf") -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)

        do {
            // Ensure the file doesn't already exist
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }

            try pdfData.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            print("Error saving PDF: \(error)")
            return nil
        }
    }

    // MARK: - PDF Drawing Helpers

    @discardableResult
    private static func drawText(
        _ text: String,
        at point: CGPoint,
        font: UIFont,
        color: UIColor = .black
    ) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]

        let attributedText = NSAttributedString(string: text, attributes: attributes)
        attributedText.draw(at: point)

        return point.y + font.lineHeight + 2
    }

    private static func drawBox(rect: CGRect, fillColor: UIColor, borderColor: UIColor) {
        let context = UIGraphicsGetCurrentContext()

        context?.setFillColor(fillColor.cgColor)
        context?.fill(rect)

        context?.setStrokeColor(borderColor.cgColor)
        context?.setLineWidth(1)
        context?.stroke(rect)
    }
}
