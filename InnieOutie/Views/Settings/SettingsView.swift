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

                    Button(action: {}) {
                        Label("Backup Data", systemImage: "icloud.and.arrow.up")
                    }
                    .disabled(!paywallService.isPro)

                } header: {
                    Text("Data")
                } footer: {
                    if !paywallService.isPro {
                        Text("Cloud backup requires Pro")
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
        }
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
                                VStack {
                                    Image(systemName: "tag.fill")
                                        .font(.title2)
                                        .foregroundColor(color.color)
                                        .frame(width: 50, height: 50)
                                        .background(tagColor == color ? Color.gray.opacity(0.2) : Color.clear)
                                        .cornerRadius(8)

                                    Text(color.rawValue)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
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
