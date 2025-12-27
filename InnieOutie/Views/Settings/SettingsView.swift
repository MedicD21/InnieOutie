//
//  SettingsView.swift
//  ProfitLens
//
//  App settings and account management
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var paywallService: PaywallService
    @EnvironmentObject var appearanceManager: AppearanceManager

    @State private var showSignOutAlert = false
    @State private var showTagReports = false

    var body: some View {
        NavigationView {
            List {
                // Appearance Section
                Section {
                    Picker("Theme", selection: $appearanceManager.selectedMode) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Choose your preferred color theme")
                }

                // Pro Status Section
                Section {
                    if paywallService.isPro {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("InnieOutie Pro")
                                    .font(.headline)

                                Text("Active")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    } else {
                        Button(action: {
                            paywallService.showPaywall(with: .settingsUpgrade)
                        }) {
                            HStack {
                                Image(systemName: "crown")
                                    .foregroundColor(.yellow)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Upgrade to Pro")
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Text("Unlock all features")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }

                // Account Section
                Section {
                    if let user = authService.currentUser {
                        if user.isGuest {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Guest Account")
                                    .font(.headline)

                                Text("Sign in to sync your data across devices")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Button(action: {
                                authService.upgradeGuestToSignIn()
                            }) {
                                HStack {
                                    Image(systemName: "person.crop.circle.badge.checkmark")
                                    Text("Sign in with Apple")
                                    Spacer()
                                }
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(user.fullName ?? "Signed In")
                                    .font(.headline)

                                if let email = user.email {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Button(role: .destructive, action: {
                                showSignOutAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Sign Out")
                                }
                            }
                        }
                    }
                } header: {
                    Text("Account")
                }

                // Data Section
                Section {
                    NavigationLink(destination: ManageCategoriesView()) {
                        Label("Manage Categories", systemImage: "tag")
                    }

                    Button(action: { showTagReports = true }) {
                        HStack {
                            Label("Project Reports", systemImage: "doc.text.magnifyingglass")
                                .foregroundColor(.primary)
                            Spacer()
                            if !paywallService.isPro {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }

                    Button(action: {}) {
                        Label("Backup Data", systemImage: "icloud.and.arrow.up")
                    }
                    .disabled(!paywallService.isPro)

                } header: {
                    Text("Data")
                } footer: {
                    if !paywallService.isPro {
                        Text("Cloud backup and project reports require Pro")
                    } else {
                        Text("Generate detailed reports for specific projects or clients")
                    }
                }

                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://profitlens.app/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://profitlens.app/terms")!) {
                        HStack {
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://profitlens.app/support")!) {
                        HStack {
                            Text("Support")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out? Your data will remain on this device.")
            }
            .sheet(isPresented: $showTagReports) {
                TagReportViewInline()
                    .environmentObject(paywallService)
            }
        }
    }
}

// MARK: - Tag Report View (Inline)

struct TagReportViewInline: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var paywallService: PaywallService
    @StateObject private var dataService = DataService()

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
                        ForEach(dataService.tags) { tag in
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
                if let selectedTag = dataService.tags.first(where: { $0.id == selectedTagId }),
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

                            if let stats = getTagStats(
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
    }

    private func exportReport() {
        guard paywallService.requestAccess(to: .csvExport, trigger: .exportCSV) else {
            return
        }

        guard let tag = dataService.tags.first(where: { $0.id == selectedTagId }) else {
            return
        }

        isExporting = true

        Task {
            let csv = ExportService.exportByTag(
                tag: tag,
                dateRange: startDate...endDate,
                allExpenses: dataService.loadAllExpenses(),
                allIncome: dataService.loadAllIncome(),
                categories: dataService.categories
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

    struct TagStats {
        let income: Decimal
        let expenses: Decimal
        let profit: Decimal
    }

    private func getTagStats(tagId: String, startDate: Date, endDate: Date) -> TagStats? {
        let dateRange = startDate...endDate

        let taggedExpenses = dataService.loadAllExpenses().filter {
            $0.tagIds.contains(tagId) && dateRange.contains($0.date)
        }
        let taggedIncome = dataService.loadAllIncome().filter {
            $0.tagIds.contains(tagId) && dateRange.contains($0.date)
        }

        let income = taggedIncome.reduce(Decimal(0)) { $0 + $1.amount }
        let expenses = taggedExpenses.reduce(Decimal(0)) { $0 + $1.amount }
        let profit = income - expenses

        return TagStats(income: income, expenses: expenses, profit: profit)
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

// MARK: - Manage Categories & Tags

struct ManageCategoriesView: View {
    @StateObject private var dataService = DataService()
    @State private var showAddCategory = false
    @State private var showAddTag = false
    @State private var newCategoryName = ""
    @State private var newCategoryIcon = "folder"
    @State private var newTagName = ""
    @State private var newTagColor: TagColor = .blue

    var body: some View {
        List {
            // Categories Section
            Section {
                ForEach(dataService.categories) { category in
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(.blue)
                            .frame(width: 30)

                        Text(category.name)

                        Spacer()

                        if category.isDefault {
                            Text("Default")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        let category = dataService.categories[index]
                        if !category.isDefault {
                            dataService.deleteCategory(category)
                        }
                    }
                }

                Button(action: { showAddCategory = true }) {
                    Label("Add Category", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("Expense Categories")
            } footer: {
                Text("Organize expenses by type (e.g., Software, Travel)")
            }

            // Tags Section
            Section {
                ForEach(dataService.tags) { tag in
                    HStack {
                        Image(systemName: tag.color.icon)
                            .foregroundColor(tag.color.color)
                            .frame(width: 30)

                        Text(tag.name)

                        Spacer()
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        let tag = dataService.tags[index]
                        dataService.deleteTag(tag)
                    }
                }

                Button(action: { showAddTag = true }) {
                    Label("Add Tag", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("Project/Client Tags")
            } footer: {
                Text("Track work by project or client")
            }
        }
        .navigationTitle("Categories & Tags")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddCategory) {
            AddCategorySheet(
                categoryName: $newCategoryName,
                categoryIcon: $newCategoryIcon,
                onSave: {
                    let category = Category(
                        name: newCategoryName,
                        icon: newCategoryIcon,
                        sortOrder: dataService.categories.count
                    )
                    dataService.saveCategory(category)
                    newCategoryName = ""
                    newCategoryIcon = "folder"
                    showAddCategory = false
                }
            )
        }
        .sheet(isPresented: $showAddTag) {
            AddTagSheet(
                tagName: $newTagName,
                tagColor: $newTagColor,
                onSave: {
                    let tag = Tag(name: newTagName, color: newTagColor)
                    dataService.saveTag(tag)
                    newTagName = ""
                    newTagColor = .blue
                    showAddTag = false
                }
            )
        }
    }
}

// MARK: - Add Category Sheet

struct AddCategorySheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var categoryName: String
    @Binding var categoryIcon: String
    var onSave: () -> Void

    let commonIcons = [
        "folder", "laptopcomputer", "cart", "airplane", "car",
        "fork.knife", "house", "heart", "star", "flag",
        "book", "briefcase", "creditcard", "dollarsign", "chart.bar"
    ]

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Category Name", text: $categoryName)
                        .autocapitalization(.words)
                } header: {
                    Text("Name")
                }

                Section {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
                        ForEach(commonIcons, id: \.self) { icon in
                            Button(action: {
                                categoryIcon = icon
                            }) {
                                VStack {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundColor(categoryIcon == icon ? .blue : .secondary)
                                        .frame(width: 50, height: 50)
                                        .background(categoryIcon == icon ? Color.blue.opacity(0.1) : Color.clear)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Icon")
                }
            }
            .navigationTitle("Add Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(categoryName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Add Tag Sheet

struct AddTagSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var tagName: String
    @Binding var tagColor: TagColor
    var onSave: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Tag Name", text: $tagName)
                        .autocapitalization(.words)
                } header: {
                    Text("Name")
                } footer: {
                    Text("e.g., Project Alpha, Client XYZ")
                }

                Section {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
                        ForEach(TagColor.allCases, id: \.self) { color in
                            Button(action: {
                                tagColor = color
                            }) {
                                VStack(spacing: 4) {
                                    ZStack {
                                        Circle()
                                            .fill(tagColor == color ? color.color.opacity(0.2) : Color(.systemGray6))
                                            .frame(width: 50, height: 50)

                                        Image(systemName: "tag.fill")
                                            .font(.title2)
                                            .foregroundColor(color.color)

                                        if tagColor == color {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                                .background(
                                                    Circle()
                                                        .fill(color.color)
                                                        .frame(width: 18, height: 18)
                                                )
                                                .offset(x: 15, y: -15)
                                        }
                                    }

                                    Text(color.rawValue)
                                        .font(.caption2)
                                        .foregroundColor(tagColor == color ? .primary : .secondary)
                                        .fontWeight(tagColor == color ? .semibold : .regular)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Color")
                }
            }
            .navigationTitle("Add Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(tagName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(AuthenticationService())
        .environmentObject(PaywallService())
        .environmentObject(AppearanceManager())
}
