//
//  OnboardingView.swift
//  ProfitLens
//
//  Initial onboarding flow - sets expectations
//  Emphasizes SPEED and CLARITY
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("has_onboarded") private var hasOnboarded = false
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            TabView(selection: $currentPage) {
                OnboardingPageView(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .blue,
                    title: "Know Your Profit",
                    description: "See instantly if you're actually making money this month. No accounting degree required."
                )
                .tag(0)

                OnboardingPageView(
                    icon: "briefcase.fill",
                    iconColor: .purple,
                    title: "Built for Freelancers",
                    description: "Track client payments, platform fees, and business expenses in one place."
                )
                .tag(1)

                OnboardingPageView(
                    icon: "bolt.fill",
                    iconColor: .orange,
                    title: "Fast & Simple",
                    description: "Add expenses in seconds. We handle the math, you handle the hustle.",
                    showButton: true,
                    buttonAction: {
                        hasOnboarded = true
                    }
                )
                .tag(2)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // Skip button
            if currentPage < 2 {
                VStack {
                    HStack {
                        Spacer()
                        Button("Skip") {
                            hasOnboarded = true
                        }
                        .foregroundColor(.secondary)
                        .padding()
                    }
                    Spacer()
                }
            }
        }
    }
}

struct OnboardingPageView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    var showButton: Bool = false
    var buttonAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Icon
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [iconColor, iconColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Content
            VStack(spacing: 16) {
                Text(title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            // Get Started button (only on last page)
            if showButton, let action = buttonAction {
                Button(action: action) {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            } else {
                Spacer()
                    .frame(height: 96)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
}
