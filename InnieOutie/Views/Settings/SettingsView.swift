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

    @State private var showSignOutAlert = false

    var body: some View {
        NavigationView {
            List {
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

// MARK: - Manage Categories (Stub)

struct ManageCategoriesView: View {
    var body: some View {
        List {
            Text("Category management coming soon")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(AuthenticationService())
        .environmentObject(PaywallService())
}
