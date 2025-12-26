//
//  SampleData.swift
//  ProfitLens
//
//  Sample data for testing and previews
//

import Foundation

struct SampleData {

    /// Generate realistic sample expenses for freelancers
    static func generateSampleExpenses(categories: [Category], count: Int = 20) -> [Expense] {
        var expenses: [Expense] = []
        let calendar = Calendar.current
        let now = Date()

        let expenseNotes = [
            "Monthly subscription",
            "Client meeting lunch",
            "New equipment",
            "Adobe CC",
            "Zoom Pro",
            "Domain renewal",
            "Coffee with client",
            "Notion subscription",
            "LinkedIn Premium",
            "Canva Pro",
            "Figma license",
            "AWS hosting",
            nil, nil, nil  // Some without notes
        ]

        for i in 0..<count {
            // Random day in current month
            let daysAgo = Int.random(in: 0...25)
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else {
                continue
            }

            // Random category
            guard let category = categories.randomElement() else { continue }

            // Amount based on category (realistic ranges)
            let amount: Decimal
            switch category.name {
            case "Software & Tools":
                amount = Decimal([10, 15, 20, 30, 50, 99].randomElement()!)
            case "Equipment & Gear":
                amount = Decimal([100, 200, 500, 800, 1200].randomElement()!)
            case "Platform Fees":
                amount = Decimal([15, 25, 40, 60, 80].randomElement()!)
            case "Marketing & Ads":
                amount = Decimal([50, 100, 200, 300, 500].randomElement()!)
            case "Website & Hosting":
                amount = Decimal([10, 20, 50, 100].randomElement()!)
            case "Client Meals":
                amount = Decimal([25, 40, 65, 80].randomElement()!)
            default:
                amount = Decimal(Double.random(in: 10...300).rounded())
            }

            expenses.append(Expense(
                amount: amount,
                date: date,
                categoryId: category.id,
                note: expenseNotes.randomElement() ?? nil
            ))
        }

        return expenses
    }

    /// Generate realistic sample income for freelancers
    static func generateSampleIncome(count: Int = 8) -> [Income] {
        var incomes: [Income] = []
        let calendar = Calendar.current
        let now = Date()

        let clients = [
            "Acme Corp",
            "TechStart Inc",
            "Creative Agency",
            "Upwork",
            "Fiverr",
            "Direct Client",
            "Stripe Payment",
            "Consulting Gig"
        ]

        let projectNotes = [
            "Website redesign",
            "Logo design",
            "App development - milestone 2",
            "Monthly retainer",
            "Consulting session",
            "Content writing",
            nil, nil
        ]

        for i in 0..<count {
            // Random day in current month
            let daysAgo = Int.random(in: 0...28)
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else {
                continue
            }

            // Realistic freelance payment amounts
            let amounts: [Int] = [500, 750, 1000, 1500, 2000, 2500, 3000, 3500, 4000, 5000]
            let amount = Decimal(amounts.randomElement()!)

            incomes.append(Income(
                amount: amount,
                date: date,
                source: clients.randomElement()!,
                note: projectNotes.randomElement() ?? nil
            ))
        }

        return incomes.sorted(by: { $0.date > $1.date })
    }

    /// Generate sample data for a specific month
    static func generateMonthData(
        for month: Date,
        categories: [Category]
    ) -> (expenses: [Expense], income: [Income]) {
        let calendar = Calendar.current
        var expenses: [Expense] = []
        var incomes: [Income] = []

        // Get month range
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
            return ([], [])
        }

        // Generate 15-25 expenses for the month
        let expenseCount = Int.random(in: 15...25)
        for _ in 0..<expenseCount {
            let randomDay = Int.random(in: 0...calendar.component(.day, from: monthEnd))
            guard let date = calendar.date(byAdding: .day, value: randomDay, to: monthStart),
                  let category = categories.randomElement() else {
                continue
            }

            let amount = Decimal(Double.random(in: 10...500).rounded())
            expenses.append(Expense(
                amount: amount,
                date: date,
                categoryId: category.id
            ))
        }

        // Generate 5-10 income entries for the month
        let incomeCount = Int.random(in: 5...10)
        let clients = ["Client A", "Client B", "Upwork", "Fiverr", "Direct"]

        for _ in 0..<incomeCount {
            let randomDay = Int.random(in: 0...calendar.component(.day, from: monthEnd))
            guard let date = calendar.date(byAdding: .day, value: randomDay, to: monthStart) else {
                continue
            }

            let amount = Decimal([500, 1000, 1500, 2000, 2500, 3000].randomElement()!)
            incomes.append(Income(
                amount: amount,
                date: date,
                source: clients.randomElement()!
            ))
        }

        return (expenses, incomes)
    }

    /// Seed database with sample data (for testing)
    static func seedDatabase(dataService: DataService) {
        let expenses = generateSampleExpenses(categories: dataService.categories)
        let incomes = generateSampleIncome()

        for expense in expenses {
            dataService.saveExpense(expense)
        }

        for income in incomes {
            dataService.saveIncome(income)
        }

        print("✅ Sample data seeded: \(expenses.count) expenses, \(incomes.count) income entries")
    }
}
