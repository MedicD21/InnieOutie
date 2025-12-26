//
//  AppearanceManager.swift
//  InnieOutie
//
//  Manages app appearance (light/dark mode)
//

import SwiftUI

enum AppearanceMode: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

class AppearanceManager: ObservableObject {
    @Published var selectedMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(selectedMode.rawValue, forKey: "appearance_mode")
        }
    }

    init() {
        // Load saved preference or default to system
        if let savedMode = UserDefaults.standard.string(forKey: "appearance_mode"),
           let mode = AppearanceMode(rawValue: savedMode) {
            self.selectedMode = mode
        } else {
            self.selectedMode = .system
        }
    }
}
