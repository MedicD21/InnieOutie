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

    // MARK: - Tax Export

    /// Export year-to-date tax summary
    /// Pro feature - IRS-friendly format for Schedule C filers
    static func exportTaxSummaryCSV(
        year: Int,
        allExpenses: [Expense],
        allIncome: [Income],
        categories: [Category]
    ) -> String {
        var csv = ""

        // Filter for the tax year
        let calendar = Calendar.current
        let yearExpenses = allExpenses.filter { calendar.component(.year, from: $0.date) == year }
        let yearIncome = allIncome.filter { calendar.component(.year, from: $0.date) == year }

        // Calculate totals
        let totalIncome = yearIncome.reduce(Decimal(0)) { $0 + $1.amount }
        let totalExpenses = yearExpenses.reduce(Decimal(0)) { $0 + $1.amount }
        let netProfit = totalIncome - totalExpenses

        // Header
        csv += "InnieOutie Tax Summary\n"
        csv += "Year: \(year)\n"
        csv += "Generated: \(Date().formatted(date: .long, time: .standard))\n"
        csv += "**For informational purposes only - consult a tax professional**\n"
        csv += "\n"

        // Summary
        csv += "ANNUAL SUMMARY\n"
        csv += "Total Income,\(totalIncome)\n"
        csv += "Total Deductible Expenses,\(totalExpenses)\n"
        csv += "Net Profit (Schedule C Line 31),\(netProfit)\n"
        csv += "\n"

        // Income by source
        csv += "INCOME BY SOURCE\n"
        csv += "Source,Total Amount,Number of Transactions\n"
        let incomeBySource = Dictionary(grouping: yearIncome) { $0.source }
        for (source, incomes) in incomeBySource.sorted(by: { $0.key < $1.key }) {
            let total = incomes.reduce(Decimal(0)) { $0 + $1.amount }
            csv += "\(source),\(total),\(incomes.count)\n"
        }
        csv += "\n"

        // Expenses by category (Schedule C categories)
        csv += "DEDUCTIBLE EXPENSES BY CATEGORY\n"
        csv += "Category,Total Amount,Number of Transactions,Avg Amount\n"

        let expensesByCategory = Dictionary(grouping: yearExpenses) { $0.categoryId }
        for (categoryId, expenses) in expensesByCategory.sorted(by: { (kv1, kv2) in
            let cat1 = categories.first(where: { $0.id == kv1.key })?.name ?? ""
            let cat2 = categories.first(where: { $0.id == kv2.key })?.name ?? ""
            return cat1 < cat2
        }) {
            let categoryName = categories.first(where: { $0.id == categoryId })?.name ?? "Unknown"
            let total = expenses.reduce(Decimal(0)) { $0 + $1.amount }
            let avg = total / Decimal(expenses.count)
            csv += "\(categoryName),\(total),\(expenses.count),\(avg)\n"
        }
        csv += "\n"

        // Monthly breakdown
        csv += "MONTHLY BREAKDOWN\n"
        csv += "Month,Income,Expenses,Net Profit\n"

        for month in 1...12 {
            let monthIncome = yearIncome.filter { calendar.component(.month, from: $0.date) == month }
            let monthExpenses = yearExpenses.filter { calendar.component(.month, from: $0.date) == month }

            let monthIncomeTotal = monthIncome.reduce(Decimal(0)) { $0 + $1.amount }
            let monthExpensesTotal = monthExpenses.reduce(Decimal(0)) { $0 + $1.amount }
            let monthNet = monthIncomeTotal - monthExpensesTotal

            let monthName = calendar.monthSymbols[month - 1]
            csv += "\(monthName),\(monthIncomeTotal),\(monthExpensesTotal),\(monthNet)\n"
        }
        csv += "\n"

        // Detailed expense transactions
        csv += "DETAILED EXPENSE TRANSACTIONS\n"
        csv += "Date,Category,Amount,Note\n"
        for expense in yearExpenses.sorted(by: { $0.date < $1.date }) {
            let dateStr = expense.date.formatted(date: .numeric, time: .omitted)
            let categoryName = categories.first(where: { $0.id == expense.categoryId })?.name ?? "Unknown"
            let note = expense.note?.replacingOccurrences(of: ",", with: ";") ?? ""
            csv += "\(dateStr),\(categoryName),\(expense.amount),\(note)\n"
        }
        csv += "\n"

        // Detailed income transactions
        csv += "DETAILED INCOME TRANSACTIONS\n"
        csv += "Date,Source,Amount,Note\n"
        for inc in yearIncome.sorted(by: { $0.date < $1.date }) {
            let dateStr = inc.date.formatted(date: .numeric, time: .omitted)
            let note = inc.note?.replacingOccurrences(of: ",", with: ";") ?? ""
            csv += "\(dateStr),\(inc.source),\(inc.amount),\(note)\n"
        }

        return csv
    }

    /// Export transactions grouped by tag for project/client tracking
    /// Perfect for freelancers tracking multiple projects or clients
    static func exportByTag(
        tag: Tag,
        dateRange: ClosedRange<Date>,
        allExpenses: [Expense],
        allIncome: [Income],
        categories: [Category]
    ) -> String {
        var csv = ""

        // Header
        csv += "PROJECT/CLIENT REPORT: \(tag.name.uppercased())\n"
        csv += "Report Period: \(dateRange.lowerBound.formatted(date: .abbreviated, time: .omitted)) - \(dateRange.upperBound.formatted(date: .abbreviated, time: .omitted))\n"
        csv += "Generated: \(Date().formatted(date: .long, time: .omitted))\n\n"

        // Filter transactions for this tag and date range
        let taggedExpenses = allExpenses.filter {
            $0.tagIds.contains(tag.id) && dateRange.contains($0.date)
        }
        let taggedIncome = allIncome.filter {
            $0.tagIds.contains(tag.id) && dateRange.contains($0.date)
        }

        // Calculate totals
        let totalIncome = taggedIncome.reduce(Decimal(0)) { $0 + $1.amount }
        let totalExpenses = taggedExpenses.reduce(Decimal(0)) { $0 + $1.amount }
        let netProfit = totalIncome - totalExpenses
        let profitMargin = totalIncome > 0 ? (netProfit / totalIncome) * 100 : 0

        // Summary
        csv += "SUMMARY\n"
        csv += "Total Income,\(totalIncome)\n"
        csv += "Total Expenses,\(totalExpenses)\n"
        csv += "Net Profit,\(netProfit)\n"
        csv += "Profit Margin,\(String(format: "%.1f", NSDecimalNumber(decimal: profitMargin).doubleValue))%\n\n"

        // Income breakdown by source
        csv += "INCOME BY SOURCE\n"
        csv += "Source,Amount,Count,Avg Amount\n"
        let incomeBySource = Dictionary(grouping: taggedIncome) { $0.source }
        for (source, incomes) in incomeBySource.sorted(by: { $0.key < $1.key }) {
            let total = incomes.reduce(Decimal(0)) { $0 + $1.amount }
            let avg = total / Decimal(incomes.count)
            csv += "\(source),\(total),\(incomes.count),\(avg)\n"
        }
        csv += "\n"

        // Expense breakdown by category
        csv += "EXPENSES BY CATEGORY\n"
        csv += "Category,Amount,Count,Avg Amount,% of Total\n"
        let expensesByCategory = Dictionary(grouping: taggedExpenses) { $0.categoryId }
        for (categoryId, expenses) in expensesByCategory.sorted(by: { (kv1, kv2) in
            let cat1 = categories.first(where: { $0.id == kv1.key })?.name ?? ""
            let cat2 = categories.first(where: { $0.id == kv2.key })?.name ?? ""
            return cat1 < cat2
        }) {
            let categoryName = categories.first(where: { $0.id == categoryId })?.name ?? "Unknown"
            let total = expenses.reduce(Decimal(0)) { $0 + $1.amount }
            let avg = total / Decimal(expenses.count)
            let percentage = totalExpenses > 0 ? (total / totalExpenses) * 100 : 0
            csv += "\(categoryName),\(total),\(expenses.count),\(avg),\(String(format: "%.1f", NSDecimalNumber(decimal: percentage).doubleValue))%\n"
        }
        csv += "\n"

        // Monthly breakdown
        csv += "MONTHLY BREAKDOWN\n"
        csv += "Month,Income,Expenses,Net Profit,Margin\n"

        let calendar = Calendar.current
        let allTransactionDates = (taggedExpenses.map { $0.date } + taggedIncome.map { $0.date })

        if !allTransactionDates.isEmpty {
            let monthsSet = Set(allTransactionDates.map {
                calendar.dateComponents([.year, .month], from: $0)
            })

            let sortedMonths = monthsSet.sorted { (comp1, comp2) in
                if comp1.year != comp2.year {
                    return comp1.year ?? 0 < comp2.year ?? 0
                }
                return comp1.month ?? 0 < comp2.month ?? 0
            }

            for monthComp in sortedMonths {
                guard let year = monthComp.year, let month = monthComp.month else { continue }

                let monthExpenses = taggedExpenses.filter {
                    let comp = calendar.dateComponents([.year, .month], from: $0.date)
                    return comp.year == year && comp.month == month
                }
                let monthIncome = taggedIncome.filter {
                    let comp = calendar.dateComponents([.year, .month], from: $0.date)
                    return comp.year == year && comp.month == month
                }

                let income = monthIncome.reduce(Decimal(0)) { $0 + $1.amount }
                let expenses = monthExpenses.reduce(Decimal(0)) { $0 + $1.amount }
                let profit = income - expenses
                let margin = income > 0 ? (profit / income) * 100 : 0

                let monthName = DateFormatter().monthSymbols[month - 1]
                csv += "\(monthName) \(year),\(income),\(expenses),\(profit),\(String(format: "%.1f", NSDecimalNumber(decimal: margin).doubleValue))%\n"
            }
        }
        csv += "\n"

        // Detailed income transactions
        csv += "DETAILED INCOME TRANSACTIONS\n"
        csv += "Date,Source,Amount,Note\n"
        for inc in taggedIncome.sorted(by: { $0.date > $1.date }) {
            let dateStr = inc.date.formatted(date: .abbreviated, time: .omitted)
            let note = inc.note?.replacingOccurrences(of: ",", with: ";") ?? ""
            csv += "\(dateStr),\(inc.source),\(inc.amount),\(note)\n"
        }
        csv += "\n"

        // Detailed expense transactions
        csv += "DETAILED EXPENSE TRANSACTIONS\n"
        csv += "Date,Category,Amount,Note\n"
        for exp in taggedExpenses.sorted(by: { $0.date > $1.date }) {
            let dateStr = exp.date.formatted(date: .abbreviated, time: .omitted)
            let categoryName = categories.first(where: { $0.id == exp.categoryId })?.name ?? "Unknown"
            let note = exp.note?.replacingOccurrences(of: ",", with: ";") ?? ""
            csv += "\(dateStr),\(categoryName),\(exp.amount),\(note)\n"
        }

        return csv
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

            // Professional Header with clean white background
            let headerRect = CGRect(x: 0, y: 0, width: 612, height: 120)
            drawCleanHeader(rect: headerRect)

            // Logo
            if let logo = UIImage(named: "splash") {
                let logoSize: CGFloat = 80
                let logoRect = CGRect(x: 50, y: 20, width: logoSize, height: logoSize)
                logo.draw(in: logoRect)

                // Company name and report title next to logo
                yOffset = 30
                yOffset = drawText(
                    "InnieOutie",
                    at: CGPoint(x: 145, y: yOffset),
                    font: .systemFont(ofSize: 28, weight: .bold),
                    color: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
                )

                drawText(
                    "Financial Report",
                    at: CGPoint(x: 145, y: yOffset - 6),
                    font: .systemFont(ofSize: 13, weight: .medium),
                    color: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
                )
            } else {
                // Fallback if logo not found
                yOffset = 40
                yOffset = drawText(
                    "InnieOutie",
                    at: CGPoint(x: 50, y: yOffset),
                    font: .systemFont(ofSize: 32, weight: .bold),
                    color: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
                )

                drawText(
                    "Financial Report",
                    at: CGPoint(x: 50, y: yOffset - 6),
                    font: .systemFont(ofSize: 14, weight: .medium),
                    color: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
                )
            }

            // Date on the right side of header
            drawText(
                Date().formatted(date: .long, time: .omitted),
                at: CGPoint(x: 430, y: 50),
                font: .systemFont(ofSize: 10, weight: .medium),
                color: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
            )

            yOffset = 135

            // Month title with green accent (matching logo)
            yOffset = drawText(
                snapshot.monthName.uppercased(),
                at: CGPoint(x: 50, y: yOffset),
                font: .systemFont(ofSize: 20, weight: .bold),
                color: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
            )
            // Green accent line (matching InnieOutie green)
            drawLine(
                from: CGPoint(x: 50, y: yOffset + 2),
                to: CGPoint(x: 200, y: yOffset + 2),
                color: UIColor(red: 0.0, green: 0.7, blue: 0.3, alpha: 1.0),
                width: 3
            )

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

                    // Professional alternating row colors
                    let bgColor = index % 2 == 0 ? UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0) : UIColor.white
                    let rowRect = CGRect(x: 50, y: yOffset - 4, width: 512, height: 30)
                    drawBox(rect: rowRect, fillColor: bgColor, borderColor: .clear)

                    // Category name
                    yOffset = drawText(
                        category.name,
                        at: CGPoint(x: 60, y: yOffset + 2),
                        font: .systemFont(ofSize: 12),
                        color: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
                    )

                    // Amount and percentage aligned to right
                    let amountText = "\(amount.formatted(.currency(code: "USD")))"
                    let percentText = "(\(String(format: "%.0f%%", percentage)))"

                    drawText(
                        amountText,
                        at: CGPoint(x: 430, y: yOffset - 16),
                        font: .systemFont(ofSize: 12, weight: .semibold),
                        color: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
                    )

                    drawText(
                        percentText,
                        at: CGPoint(x: 520, y: yOffset - 16),
                        font: .systemFont(ofSize: 11),
                        color: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
                    )

                    yOffset += 12
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

                    // Professional alternating row colors
                    let bgColor = index % 2 == 0 ? UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0) : UIColor.white
                    let rowRect = CGRect(x: 50, y: yOffset - 4, width: 512, height: 30)
                    drawBox(rect: rowRect, fillColor: bgColor, borderColor: .clear)

                    // Source name
                    yOffset = drawText(
                        source,
                        at: CGPoint(x: 60, y: yOffset + 2),
                        font: .systemFont(ofSize: 12),
                        color: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
                    )

                    // Amount and percentage aligned to right
                    let amountText = "\(amount.formatted(.currency(code: "USD")))"
                    let percentText = "(\(String(format: "%.0f%%", percentage)))"

                    drawText(
                        amountText,
                        at: CGPoint(x: 430, y: yOffset - 16),
                        font: .systemFont(ofSize: 12, weight: .semibold),
                        color: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
                    )

                    drawText(
                        percentText,
                        at: CGPoint(x: 520, y: yOffset - 16),
                        font: .systemFont(ofSize: 11),
                        color: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
                    )

                    yOffset += 12
                }
            }

            // Footer with green accent
            let footerY: CGFloat = 760
            drawLine(
                from: CGPoint(x: 50, y: footerY - 10),
                to: CGPoint(x: 562, y: footerY - 10),
                color: UIColor(red: 0.0, green: 0.7, blue: 0.3, alpha: 0.15),
                width: 1
            )
            drawText(
                "Generated by InnieOutie  |  \(Date().formatted(date: .abbreviated, time: .shortened))",
                at: CGPoint(x: 50, y: footerY),
                font: .systemFont(ofSize: 9),
                color: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
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

    private static func drawCleanHeader(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()

        // Clean white background
        context?.setFillColor(UIColor.white.cgColor)
        context?.fill(rect)

        // Subtle bottom border in green
        context?.setStrokeColor(UIColor(red: 0.0, green: 0.7, blue: 0.3, alpha: 0.2).cgColor)
        context?.setLineWidth(2)
        context?.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        context?.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        context?.strokePath()
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
        // Clean section header with green accent
        let headerRect = CGRect(x: 50, y: yOffset - 8, width: 512, height: 32)

        // White background
        drawBox(
            rect: headerRect,
            fillColor: UIColor.white,
            borderColor: .clear
        )

        // Green accent line at left edge
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor(red: 0.0, green: 0.7, blue: 0.3, alpha: 1.0).cgColor)
        context?.fill(CGRect(x: 50, y: yOffset - 8, width: 4, height: 32))

        // Bottom border
        context?.setStrokeColor(UIColor(red: 0.0, green: 0.7, blue: 0.3, alpha: 0.15).cgColor)
        context?.setLineWidth(1)
        context?.move(to: CGPoint(x: 50, y: headerRect.maxY))
        context?.addLine(to: CGPoint(x: 562, y: headerRect.maxY))
        context?.strokePath()

        return drawText(
            title,
            at: CGPoint(x: 64, y: yOffset),
            font: .systemFont(ofSize: 15, weight: .semibold),
            color: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        )
    }

    private static func drawTableHeader(at yOffset: CGFloat, leftText: String, rightText: String) {
        // Professional table headers with better spacing
        drawText(
            leftText.uppercased(),
            at: CGPoint(x: 60, y: yOffset),
            font: .systemFont(ofSize: 9, weight: .bold),
            color: UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        )

        drawText(
            rightText.uppercased(),
            at: CGPoint(x: 430, y: yOffset),
            font: .systemFont(ofSize: 9, weight: .bold),
            color: UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        )
    }
}
