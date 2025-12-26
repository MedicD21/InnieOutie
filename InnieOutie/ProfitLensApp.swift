//
//  InnieOutieApp.swift
//  InnieOutie
//
//  Created on 2025-12-26.
//  Finances Made Easy - Production-ready expense tracker for freelancers
//

import SwiftUI

@main
struct InnieOutieApp: App {
    @StateObject private var authService = AuthenticationService()
    @StateObject private var paywallService = PaywallService()
    @StateObject private var appearanceManager = AppearanceManager()
    @AppStorage("has_onboarded") private var hasOnboarded = false

    var body: some Scene {
        WindowGroup {
            Group {
                if !hasOnboarded {
                    OnboardingView()
                } else if authService.isAuthenticated || authService.isGuestMode {
                    MainTabView()
                        .environmentObject(authService)
                        .environmentObject(paywallService)
                        .environmentObject(appearanceManager)
                } else {
                    AuthenticationView()
                        .environmentObject(authService)
                }
            }
            .preferredColorScheme(appearanceManager.selectedMode.colorScheme)
            .onAppear {
                // Initialize services
                Task {
                    await paywallService.checkSubscriptionStatus()
                }
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var paywallService: PaywallService

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                }

            MonthlyReportsView()
                .tabItem {
                    Label("Reports", systemImage: "doc.text")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .sheet(isPresented: $paywallService.showPaywall) {
            PaywallView()
                .environmentObject(paywallService)
        }
    }
}
