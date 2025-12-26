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
            kCGPDFContextTitle: "Monthly Financial Report",
            kCGPDFContextAuthor: "InnieOutie App"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            var yOffset: CGFloat = 40

            // Gradient Header Bar
            drawGradientHeader(rect: CGRect(x: 0, y: 0, width: 612, height: 100))

            // Title with gradient effect (simulated with blue)
            yOffset = 45
            yOffset = drawText(
                "InnieOutie",
                at: CGPoint(x: 50, y: yOffset),
                font: .systemFont(ofSize: 38, weight: .bold),
                color: UIColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1.0)
            )

            yOffset = drawText(
                "Finances Made Easy",
                at: CGPoint(x: 50, y: yOffset),
                font: .systemFont(ofSize: 13),
                color: .white
            )

            // Date on the right side of header
            drawText(
                Date().formatted(date: .long, time: .omitted),
                at: CGPoint(x: 400, y: 55),
                font: .systemFont(ofSize: 11),
                color: .white
            )

            yOffset = 120

            // Month title with underline
            yOffset = drawText(
                snapshot.monthName.uppercased(),
                at: CGPoint(x: 50, y: yOffset),
                font: .systemFont(ofSize: 24, weight: .semibold),
                color: .black
            )
            drawLine(from: CGPoint(x: 50, y: yOffset + 5), to: CGPoint(x: 250, y: yOffset + 5), color: UIColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1.0), width: 2)

            yOffset += 25

            // Main Summary Cards
            let cardWidth: CGFloat = 160
            let cardHeight: CGFloat = 100
            let cardSpacing: CGFloat = 20

            // Income Card
            let incomeCardRect = CGRect(x: 50, y: yOffset, width: cardWidth, height: cardHeight)
            drawCard(
                rect: incomeCardRect,
                title: "TOTAL INCOME",
                value: snapshot.formattedIncome,
                color: UIColor.systemGreen,
                isPositive: true
            )

            // Expenses Card
            let expensesCardRect = CGRect(x: 50 + cardWidth + cardSpacing, y: yOffset, width: cardWidth, height: cardHeight)
            drawCard(
                rect: expensesCardRect,
                title: "TOTAL EXPENSES",
                value: snapshot.formattedExpenses,
                color: UIColor.systemRed,
                isPositive: false
            )

            // Net Profit Card (larger, more prominent)
            let profitCardRect = CGRect(x: 50 + (cardWidth + cardSpacing) * 2, y: yOffset, width: cardWidth, height: cardHeight)
            drawCard(
                rect: profitCardRect,
                title: "NET PROFIT",
                value: snapshot.formattedProfit,
                color: snapshot.isProfit ? UIColor.systemGreen : UIColor.systemRed,
                isPositive: snapshot.isProfit,
                isPrimary: true
            )

            yOffset += cardHeight + 35

            // Expense Categories Section
            if !snapshot.topCategories.isEmpty {
                yOffset = drawSectionHeader(title: "Expense Breakdown", at: yOffset)
                yOffset += 15

                // Table header
                drawTableHeader(at: yOffset, leftText: "Category", rightText: "Amount")
                yOffset += 25

                for (index, (category, amount)) in snapshot.topCategories.prefix(7).enumerated() {
                    let percentage = snapshot.totalExpenses > 0 ?
                        Double(truncating: (amount / snapshot.totalExpenses * 100) as NSNumber) : 0

                    let bgColor = index % 2 == 0 ? UIColor.systemGray6 : UIColor.white
                    let rowRect = CGRect(x: 50, y: yOffset - 5, width: 512, height: 28)
                    drawBox(rect: rowRect, fillColor: bgColor, borderColor: .clear)

                    yOffset = drawText(
                        category.name,
                        at: CGPoint(x: 65, y: yOffset),
                        font: .systemFont(ofSize: 13)
                    )

                    let amountText = "\(amount.formatted(.currency(code: "USD")))  (\(String(format: "%.0f%%", percentage)))"
                    drawText(
                        amountText,
                        at: CGPoint(x: 410, y: yOffset - 13),
                        font: .systemFont(ofSize: 13, weight: .medium)
                    )

                    yOffset += 8
                }

                yOffset += 20
            }

            // Income Sources Section
            if !snapshot.incomeBySource.isEmpty {
                yOffset = drawSectionHeader(title: "Income Sources", at: yOffset)
                yOffset += 15

                // Table header
                drawTableHeader(at: yOffset, leftText: "Source", rightText: "Amount")
                yOffset += 25

                for (index, (source, amount)) in snapshot.incomeBySource.prefix(7).enumerated() {
                    let percentage = snapshot.totalIncome > 0 ?
                        Double(truncating: (amount / snapshot.totalIncome * 100) as NSNumber) : 0

                    let bgColor = index % 2 == 0 ? UIColor.systemGray6 : UIColor.white
                    let rowRect = CGRect(x: 50, y: yOffset - 5, width: 512, height: 28)
                    drawBox(rect: rowRect, fillColor: bgColor, borderColor: .clear)

                    yOffset = drawText(
                        source,
                        at: CGPoint(x: 65, y: yOffset),
                        font: .systemFont(ofSize: 13)
                    )

                    let amountText = "\(amount.formatted(.currency(code: "USD")))  (\(String(format: "%.0f%%", percentage)))"
                    drawText(
                        amountText,
                        at: CGPoint(x: 410, y: yOffset - 13),
                        font: .systemFont(ofSize: 13, weight: .medium)
                    )

                    yOffset += 8
                }
            }

            // Footer
            let footerY: CGFloat = 760
            drawLine(from: CGPoint(x: 50, y: footerY - 10), to: CGPoint(x: 562, y: footerY - 10), color: .lightGray, width: 1)
            drawText(
                "Generated by InnieOutie  |  \(Date().formatted(date: .abbreviated, time: .shortened))",
                at: CGPoint(x: 50, y: footerY),
                font: .systemFont(ofSize: 9),
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

    private static func drawLine(from: CGPoint, to: CGPoint, color: UIColor, width: CGFloat) {
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(color.cgColor)
        context?.setLineWidth(width)
        context?.move(to: from)
        context?.addLine(to: to)
        context?.strokePath()
    }

    private static func drawGradientHeader(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()

        // Create a gradient from blue to purple
        let colors = [
            UIColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1.0).cgColor,
            UIColor(red: 0.5, green: 0.3, blue: 0.8, alpha: 1.0).cgColor
        ] as CFArray

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0])!

        context?.saveGState()
        context?.addRect(rect)
        context?.clip()
        context?.drawLinearGradient(
            gradient,
            start: CGPoint(x: rect.minX, y: rect.minY),
            end: CGPoint(x: rect.maxX, y: rect.minY),
            options: []
        )
        context?.restoreGState()
    }

    private static func drawCard(rect: CGRect, title: String, value: String, color: UIColor, isPositive: Bool, isPrimary: Bool = false) {
        // Card background with subtle shadow effect
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()

        // Shadow
        context?.setShadow(offset: CGSize(width: 0, height: 2), blur: 4, color: UIColor.black.withAlphaComponent(0.1).cgColor)

        // Card background
        let borderColor = isPrimary ? color : UIColor.systemGray4
        drawBox(rect: rect, fillColor: .white, borderColor: borderColor)

        context?.restoreGState()

        // Color accent bar at top
        let accentRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 4)
        drawBox(rect: accentRect, fillColor: color, borderColor: color)

        // Title
        drawText(
            title,
            at: CGPoint(x: rect.minX + 12, y: rect.minY + 18),
            font: .systemFont(ofSize: 10, weight: .semibold),
            color: .gray
        )

        // Value
        drawText(
            value,
            at: CGPoint(x: rect.minX + 12, y: rect.minY + 35),
            font: .systemFont(ofSize: isPrimary ? 26 : 22, weight: .bold),
            color: color
        )
    }

    @discardableResult
    private static func drawSectionHeader(title: String, at yOffset: CGFloat) -> CGFloat {
        drawBox(
            rect: CGRect(x: 50, y: yOffset - 8, width: 512, height: 32),
            fillColor: UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0),
            borderColor: .clear
        )

        return drawText(
            title,
            at: CGPoint(x: 60, y: yOffset),
            font: .systemFont(ofSize: 16, weight: .semibold),
            color: UIColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1.0)
        )
    }

    private static func drawTableHeader(at yOffset: CGFloat, leftText: String, rightText: String) {
        drawText(
            leftText.uppercased(),
            at: CGPoint(x: 65, y: yOffset),
            font: .systemFont(ofSize: 10, weight: .semibold),
            color: .gray
        )

        drawText(
            rightText.uppercased(),
            at: CGPoint(x: 410, y: yOffset),
            font: .systemFont(ofSize: 10, weight: .semibold),
            color: .gray
        )
    }
}
