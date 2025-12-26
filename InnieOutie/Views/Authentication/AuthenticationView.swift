//
//  AuthenticationView.swift
//  ProfitLens
//
//  Guest mode vs Sign in with Apple
//  Default to guest - signing in is optional
//

import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthenticationService

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo/Icon
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Title
            VStack(spacing: 12) {
                Text("InnieOutie")
                    .font(.largeTitle.bold())

                Text("Finances Made Easy")
                    .font(.title3)
                    .foregroundColor(.blue)

                Text("Track your freelance income and expenses")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Auth buttons
            VStack(spacing: 16) {
                // Start as Guest (PRIMARY action)
                Button(action: {
                    authService.startGuestMode()
                }) {
                    Text("Start Using InnieOutie")
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

                // Sign in with Apple (secondary)
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        // Handled by AuthenticationService delegate
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 56)
                .cornerRadius(16)

                Text("Sign in to sync your data across devices")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 32)

            Spacer()
                .frame(height: 60)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationService())
}
