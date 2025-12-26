//
//  Tag.swift
//  InnieOutie
//
//  Tags for organizing transactions by projects, clients, or custom groupings
//  Complements categories for flexible reporting
//

import Foundation
import SwiftUI

struct Tag: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var color: TagColor
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        color: TagColor = .blue,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.createdAt = createdAt
    }
}

// MARK: - Tag Colors

enum TagColor: String, Codable, CaseIterable {
    case blue = "Blue"
    case green = "Green"
    case orange = "Orange"
    case red = "Red"
    case purple = "Purple"
    case pink = "Pink"
    case yellow = "Yellow"
    case teal = "Teal"
    case indigo = "Indigo"
    case gray = "Gray"

    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        case .purple: return .purple
        case .pink: return .pink
        case .yellow: return .yellow
        case .teal: return .teal
        case .indigo: return .indigo
        case .gray: return .gray
        }
    }

    var icon: String {
        "tag.fill"
    }
}
