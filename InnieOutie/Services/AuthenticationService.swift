//
//  AuthenticationService.swift
//  ProfitLens
//
//  Handles guest mode and Sign in with Apple authentication
//

import Foundation
import AuthenticationServices
import SwiftUI

@MainActor
class AuthenticationService: NSObject, ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isGuestMode = false
    @Published var authError: String?

    private let userKey = "current_user"
    private let guestModeKey = "is_guest_mode"

    override init() {
        super.init()
        loadSavedUser()
    }

    // MARK: - Guest Mode

    /// Start using app as guest (default behavior)
    func startGuestMode() {
        let guestUser = User(isGuest: true)
        self.currentUser = guestUser
        self.isGuestMode = true
        self.isAuthenticated = true
        saveUser(guestUser)
        UserDefaults.standard.set(true, forKey: guestModeKey)
    }

    // MARK: - Sign in with Apple

    /// Initiate Sign in with Apple flow
    func signInWithApple() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.performRequests()
    }

    /// Sign out current user
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        isGuestMode = false
        UserDefaults.standard.removeObject(forKey: userKey)
        UserDefaults.standard.removeObject(forKey: guestModeKey)
    }

    /// Upgrade from guest to authenticated account
    func upgradeGuestToSignIn() {
        // User wants to upgrade - trigger Sign in with Apple
        signInWithApple()
    }

    // MARK: - Private Helpers

    private func loadSavedUser() {
        if let userData = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isGuestMode = user.isGuest
            self.isAuthenticated = true
        }
    }

    private func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userKey)
        }
    }

    private func handleSuccessfulSignIn(userIdentifier: String, email: String?, fullName: PersonNameComponents?) {
        let user = User(
            id: userIdentifier,
            email: email,
            fullName: fullName?.formatted(),
            isGuest: false
        )

        self.currentUser = user
        self.isAuthenticated = true
        self.isGuestMode = false
        saveUser(user)
        UserDefaults.standard.set(false, forKey: guestModeKey)

        // If upgrading from guest, migrate data here
        // For MVP, we'll just switch to the new account
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthenticationService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userIdentifier = appleIDCredential.user
                let email = appleIDCredential.email
                let fullName = appleIDCredential.fullName

                handleSuccessfulSignIn(
                    userIdentifier: userIdentifier,
                    email: email,
                    fullName: fullName
                )
            }
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            // Handle error
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    self.authError = nil  // User canceled, no error
                case .failed:
                    self.authError = "Authentication failed. Please try again."
                case .notHandled:
                    self.authError = "Unable to handle request."
                case .unknown:
                    self.authError = "An unknown error occurred."
                default:
                    self.authError = "Sign in failed."
                }
            }
        }
    }
}
