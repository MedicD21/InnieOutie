//
//  DataService.swift
//  ProfitLens
//
//  Local-first data persistence using SQLite
//  Uses simple file-based storage for MVP (can upgrade to GRDB later)
//

import Foundation
import SQLite3

class DataService: ObservableObject {
    private var db: OpaquePointer?
    private let dbPath: String

    @Published var expenses: [Expense] = []
    @Published var income: [Income] = []
    @Published var categories: [Category] = []

    init() {
        // Set up database path
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        dbPath = documentsPath.appendingPathComponent("profitlens.db").path

        // Open database connection
        openDatabase()

        // Create tables if needed
        createTables()

        // Seed default categories
        seedDefaultCategories()

        // Load initial data
        loadCategories()
        loadCurrentMonthData()
    }

    deinit {
        sqlite3_close(db)
    }

    // MARK: - Database Setup

    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("Error opening database")
        }
    }

    private func createTables() {
        // Expenses table
        let createExpensesTable = """
        CREATE TABLE IF NOT EXISTS expenses (
            id TEXT PRIMARY KEY,
            amount REAL NOT NULL,
            date INTEGER NOT NULL,
            category_id TEXT NOT NULL,
            note TEXT,
            receipt_path TEXT,
            created_at INTEGER NOT NULL
        );
        """

        // Income table
        let createIncomeTable = """
        CREATE TABLE IF NOT EXISTS income (
            id TEXT PRIMARY KEY,
            amount REAL NOT NULL,
            date INTEGER NOT NULL,
            source TEXT NOT NULL,
            note TEXT,
            created_at INTEGER NOT NULL
        );
        """

        // Categories table
        let createCategoriesTable = """
        CREATE TABLE IF NOT EXISTS categories (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            icon TEXT NOT NULL,
            is_default INTEGER NOT NULL DEFAULT 0,
            sort_order INTEGER NOT NULL DEFAULT 0
        );
        """

        executeSQL(createExpensesTable)
        executeSQL(createIncomeTable)
        executeSQL(createCategoriesTable)

        // Create indices
        executeSQL("CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date DESC);")
        executeSQL("CREATE INDEX IF NOT EXISTS idx_income_date ON income(date DESC);")
    }

    private func executeSQL(_ sql: String) {
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error executing SQL: \(sql)")
            }
        }
        sqlite3_finalize(statement)
    }

    // MARK: - Categories

    private func seedDefaultCategories() {
        // Check if categories already exist
        let countQuery = "SELECT COUNT(*) FROM categories WHERE is_default = 1"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, countQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                let count = sqlite3_column_int(statement, 0)
                sqlite3_finalize(statement)

                if count > 0 {
                    return  // Categories already seeded
                }
            }
        }

        // Insert default categories
        for category in FreelancerCategory.defaultCategories {
            saveCategory(category)
        }
    }

    func loadCategories() {
        var result: [Category] = []
        let query = "SELECT * FROM categories ORDER BY sort_order"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let name = String(cString: sqlite3_column_text(statement, 1))
                let icon = String(cString: sqlite3_column_text(statement, 2))
                let isDefault = sqlite3_column_int(statement, 3) == 1
                let sortOrder = Int(sqlite3_column_int(statement, 4))

                result.append(Category(
                    id: id,
                    name: name,
                    icon: icon,
                    isDefault: isDefault,
                    sortOrder: sortOrder
                ))
            }
        }
        sqlite3_finalize(statement)

        DispatchQueue.main.async {
            self.categories = result
        }
    }

    func saveCategory(_ category: Category) {
        let insertSQL = """
        INSERT OR REPLACE INTO categories (id, name, icon, is_default, sort_order)
        VALUES (?, ?, ?, ?, ?);
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (category.id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (category.name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (category.icon as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 4, category.isDefault ? 1 : 0)
            sqlite3_bind_int(statement, 5, Int32(category.sortOrder))

            if sqlite3_step(statement) == SQLITE_DONE {
                print("Category saved successfully")
            }
        }
        sqlite3_finalize(statement)
    }

    // MARK: - Expenses

    func saveExpense(_ expense: Expense) {
        let insertSQL = """
        INSERT OR REPLACE INTO expenses (id, amount, date, category_id, note, receipt_path, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?);
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (expense.id as NSString).utf8String, -1, nil)
            sqlite3_bind_double(statement, 2, Double(truncating: expense.amount as NSNumber))
            sqlite3_bind_int64(statement, 3, Int64(expense.date.timeIntervalSince1970))
            sqlite3_bind_text(statement, 4, (expense.categoryId as NSString).utf8String, -1, nil)

            if let note = expense.note {
                sqlite3_bind_text(statement, 5, (note as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(statement, 5)
            }

            if let receiptPath = expense.receiptPath {
                sqlite3_bind_text(statement, 6, (receiptPath as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(statement, 6)
            }

            sqlite3_bind_int64(statement, 7, Int64(expense.createdAt.timeIntervalSince1970))

            if sqlite3_step(statement) == SQLITE_DONE {
                print("Expense saved successfully")
                loadCurrentMonthData()
            }
        }
        sqlite3_finalize(statement)
    }

    func loadExpenses(from startDate: Date, to endDate: Date) -> [Expense] {
        var result: [Expense] = []
        let query = "SELECT * FROM expenses WHERE date >= ? AND date <= ? ORDER BY date DESC"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int64(statement, 1, Int64(startDate.timeIntervalSince1970))
            sqlite3_bind_int64(statement, 2, Int64(endDate.timeIntervalSince1970))

            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let amount = Decimal(sqlite3_column_double(statement, 1))
                let date = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_int64(statement, 2)))
                let categoryId = String(cString: sqlite3_column_text(statement, 3))

                let note: String? = if let noteText = sqlite3_column_text(statement, 4) {
                    String(cString: noteText)
                } else {
                    nil
                }

                let receiptPath: String? = if let pathText = sqlite3_column_text(statement, 5) {
                    String(cString: pathText)
                } else {
                    nil
                }

                let createdAt = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_int64(statement, 6)))

                result.append(Expense(
                    id: id,
                    amount: amount,
                    date: date,
                    categoryId: categoryId,
                    note: note,
                    receiptPath: receiptPath,
                    createdAt: createdAt
                ))
            }
        }
        sqlite3_finalize(statement)
        return result
    }

    func deleteExpense(_ expense: Expense) {
        let deleteSQL = "DELETE FROM expenses WHERE id = ?"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (expense.id as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_DONE {
                loadCurrentMonthData()
            }
        }
        sqlite3_finalize(statement)
    }

    // MARK: - Income

    func saveIncome(_ income: Income) {
        let insertSQL = """
        INSERT OR REPLACE INTO income (id, amount, date, source, note, created_at)
        VALUES (?, ?, ?, ?, ?, ?);
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (income.id as NSString).utf8String, -1, nil)
            sqlite3_bind_double(statement, 2, Double(truncating: income.amount as NSNumber))
            sqlite3_bind_int64(statement, 3, Int64(income.date.timeIntervalSince1970))
            sqlite3_bind_text(statement, 4, (income.source as NSString).utf8String, -1, nil)

            if let note = income.note {
                sqlite3_bind_text(statement, 5, (note as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(statement, 5)
            }

            sqlite3_bind_int64(statement, 6, Int64(income.createdAt.timeIntervalSince1970))

            if sqlite3_step(statement) == SQLITE_DONE {
                print("Income saved successfully")
                loadCurrentMonthData()
            }
        }
        sqlite3_finalize(statement)
    }

    func loadIncome(from startDate: Date, to endDate: Date) -> [Income] {
        var result: [Income] = []
        let query = "SELECT * FROM income WHERE date >= ? AND date <= ? ORDER BY date DESC"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int64(statement, 1, Int64(startDate.timeIntervalSince1970))
            sqlite3_bind_int64(statement, 2, Int64(endDate.timeIntervalSince1970))

            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let amount = Decimal(sqlite3_column_double(statement, 1))
                let date = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_int64(statement, 2)))
                let source = String(cString: sqlite3_column_text(statement, 3))

                let note: String? = if let noteText = sqlite3_column_text(statement, 4) {
                    String(cString: noteText)
                } else {
                    nil
                }

                let createdAt = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_int64(statement, 5)))

                result.append(Income(
                    id: id,
                    amount: amount,
                    date: date,
                    source: source,
                    note: note,
                    createdAt: createdAt
                ))
            }
        }
        sqlite3_finalize(statement)
        return result
    }

    func deleteIncome(_ income: Income) {
        let deleteSQL = "DELETE FROM income WHERE id = ?"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (income.id as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_DONE {
                loadCurrentMonthData()
            }
        }
        sqlite3_finalize(statement)
    }

    // MARK: - Convenience Methods

    /// Load current month's expenses and income
    func loadCurrentMonthData() {
        let calendar = Calendar.current
        let now = Date()
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return
        }

        DispatchQueue.main.async {
            self.expenses = self.loadExpenses(from: startOfMonth, to: endOfMonth)
            self.income = self.loadIncome(from: startOfMonth, to: endOfMonth)
        }
    }

    /// Load data for specific month
    func loadMonthData(month: Date) -> (expenses: [Expense], income: [Income]) {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return ([], [])
        }

        return (
            loadExpenses(from: startOfMonth, to: endOfMonth),
            loadIncome(from: startOfMonth, to: endOfMonth)
        )
    }
}
