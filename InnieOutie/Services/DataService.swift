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
    @Published var tags: [Tag] = []

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
        loadTags()
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
            tag_ids TEXT,
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
            tag_ids TEXT,
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

        // Tags table
        let createTagsTable = """
        CREATE TABLE IF NOT EXISTS tags (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            color TEXT NOT NULL,
            created_at INTEGER NOT NULL
        );
        """

        executeSQL(createExpensesTable)
        executeSQL(createIncomeTable)
        executeSQL(createCategoriesTable)
        executeSQL(createTagsTable)

        // Create indices
        executeSQL("CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date DESC);")
        executeSQL("CREATE INDEX IF NOT EXISTS idx_income_date ON income(date DESC);")

        // Migration: Add tag_ids column to existing tables if it doesn't exist
        executeSQL("ALTER TABLE expenses ADD COLUMN tag_ids TEXT DEFAULT '';")
        executeSQL("ALTER TABLE income ADD COLUMN tag_ids TEXT DEFAULT '';")
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
                loadCategories()
            }
        }
        sqlite3_finalize(statement)
    }

    func deleteCategory(_ category: Category) {
        guard !category.isDefault else { return }  // Prevent deleting default categories

        let deleteSQL = "DELETE FROM categories WHERE id = ?"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (category.id as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_DONE {
                loadCategories()
            }
        }
        sqlite3_finalize(statement)
    }

    // MARK: - Tags

    func loadTags() {
        var result: [Tag] = []
        let query = "SELECT * FROM tags ORDER BY name"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let name = String(cString: sqlite3_column_text(statement, 1))
                let colorRaw = String(cString: sqlite3_column_text(statement, 2))
                let color = TagColor(rawValue: colorRaw) ?? .blue
                let createdAt = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_int64(statement, 3)))

                result.append(Tag(
                    id: id,
                    name: name,
                    color: color,
                    createdAt: createdAt
                ))
            }
        }
        sqlite3_finalize(statement)

        DispatchQueue.main.async {
            self.tags = result
        }
    }

    func saveTag(_ tag: Tag) {
        let insertSQL = """
        INSERT OR REPLACE INTO tags (id, name, color, created_at)
        VALUES (?, ?, ?, ?);
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (tag.id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (tag.name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (tag.color.rawValue as NSString).utf8String, -1, nil)
            sqlite3_bind_int64(statement, 4, Int64(tag.createdAt.timeIntervalSince1970))

            if sqlite3_step(statement) == SQLITE_DONE {
                print("Tag saved successfully")
                loadTags()
            }
        }
        sqlite3_finalize(statement)
    }

    func deleteTag(_ tag: Tag) {
        let deleteSQL = "DELETE FROM tags WHERE id = ?"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (tag.id as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_DONE {
                loadTags()
            }
        }
        sqlite3_finalize(statement)
    }

    // MARK: - Expenses

    func saveExpense(_ expense: Expense) {
        let insertSQL = """
        INSERT OR REPLACE INTO expenses (id, amount, date, category_id, note, receipt_path, tag_ids, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?);
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

            // Store tag IDs as comma-separated string
            let tagIdsString = expense.tagIds.joined(separator: ",")
            sqlite3_bind_text(statement, 7, (tagIdsString as NSString).utf8String, -1, nil)

            sqlite3_bind_int64(statement, 8, Int64(expense.createdAt.timeIntervalSince1970))

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

                let tagIdsString: String = if let tagText = sqlite3_column_text(statement, 6) {
                    String(cString: tagText)
                } else {
                    ""
                }
                let tagIds = tagIdsString.isEmpty ? [] : tagIdsString.split(separator: ",").map(String.init)

                let createdAt = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_int64(statement, 7)))

                result.append(Expense(
                    id: id,
                    amount: amount,
                    date: date,
                    categoryId: categoryId,
                    note: note,
                    receiptPath: receiptPath,
                    tagIds: tagIds,
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
        INSERT OR REPLACE INTO income (id, amount, date, source, note, tag_ids, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?);
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

            // Store tag IDs as comma-separated string
            let tagIdsString = income.tagIds.joined(separator: ",")
            sqlite3_bind_text(statement, 6, (tagIdsString as NSString).utf8String, -1, nil)

            sqlite3_bind_int64(statement, 7, Int64(income.createdAt.timeIntervalSince1970))

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

                let tagIdsString: String = if let tagText = sqlite3_column_text(statement, 5) {
                    String(cString: tagText)
                } else {
                    ""
                }
                let tagIds = tagIdsString.isEmpty ? [] : tagIdsString.split(separator: ",").map(String.init)

                let createdAt = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_int64(statement, 6)))

                result.append(Income(
                    id: id,
                    amount: amount,
                    date: date,
                    source: source,
                    note: note,
                    tagIds: tagIds,
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

    /// Load all expenses (for reports)
    func loadAllExpenses() -> [Expense] {
        var result: [Expense] = []
        let query = "SELECT * FROM expenses ORDER BY date DESC"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let amount = Decimal(sqlite3_column_double(statement, 1))
                let dateInterval = sqlite3_column_double(statement, 2)
                let categoryId = String(cString: sqlite3_column_text(statement, 3))
                let noteText = sqlite3_column_text(statement, 4)
                let note = noteText != nil ? String(cString: noteText!) : nil
                let receiptPathText = sqlite3_column_text(statement, 5)
                let receiptPath = receiptPathText != nil ? String(cString: receiptPathText!) : nil
                let tagIdsText = sqlite3_column_text(statement, 6)
                let tagIds = tagIdsText != nil ? String(cString: tagIdsText!).components(separatedBy: ",").filter { !$0.isEmpty } : []
                let createdAtInterval = sqlite3_column_double(statement, 7)

                let expense = Expense(
                    id: id,
                    amount: amount,
                    date: Date(timeIntervalSince1970: dateInterval),
                    categoryId: categoryId,
                    note: note,
                    receiptPath: receiptPath,
                    tagIds: tagIds,
                    createdAt: Date(timeIntervalSince1970: createdAtInterval)
                )
                result.append(expense)
            }
        }

        sqlite3_finalize(statement)
        return result
    }

    /// Load all income (for reports)
    func loadAllIncome() -> [Income] {
        var result: [Income] = []
        let query = "SELECT * FROM income ORDER BY date DESC"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let amount = Decimal(sqlite3_column_double(statement, 1))
                let dateInterval = sqlite3_column_double(statement, 2)
                let source = String(cString: sqlite3_column_text(statement, 3))
                let noteText = sqlite3_column_text(statement, 4)
                let note = noteText != nil ? String(cString: noteText!) : nil
                let tagIdsText = sqlite3_column_text(statement, 5)
                let tagIds = tagIdsText != nil ? String(cString: tagIdsText!).components(separatedBy: ",").filter { !$0.isEmpty } : []
                let createdAtInterval = sqlite3_column_double(statement, 6)

                let income = Income(
                    id: id,
                    amount: amount,
                    date: Date(timeIntervalSince1970: dateInterval),
                    source: source,
                    note: note,
                    tagIds: tagIds,
                    createdAt: Date(timeIntervalSince1970: createdAtInterval)
                )
                result.append(income)
            }
        }

        sqlite3_finalize(statement)
        return result
    }
}
