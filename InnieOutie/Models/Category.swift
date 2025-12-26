//
//  Category.swift
//  ProfitLens
//
//  Expense categories optimized for freelancers
//

import Foundation

struct Category: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var icon: String  // SF Symbol name
    var isDefault: Bool
    var sortOrder: Int

    init(
        id: String = UUID().uuidString,
        name: String,
        icon: String,
        isDefault: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.isDefault = isDefault
        self.sortOrder = sortOrder
    }
}

// MARK: - Freelancer Category Presets

enum FreelancerCategory: String, CaseIterable {
    case softwareSubscriptions = "Software & Tools"
    case equipmentGear = "Equipment & Gear"
    case platformFees = "Platform Fees"
    case marketingAds = "Marketing & Ads"
    case websiteHosting = "Website & Hosting"
    case professionalServices = "Legal & Accounting"
    case education = "Courses & Education"
    case travelMileage = "Travel & Mileage"
    case coworkingOffice = "Coworking / Office"
    case meals = "Client Meals"
    case insurance = "Insurance"
    case bankFees = "Payment Processing"
    case miscWriteOffs = "Misc Write-Offs"

    var icon: String {
        switch self {
        case .softwareSubscriptions: return "laptopcomputer"
        case .equipmentGear: return "desktopcomputer"
        case .platformFees: return "percent"
        case .marketingAds: return "megaphone"
        case .websiteHosting: return "globe"
        case .professionalServices: return "briefcase"
        case .education: return "book"
        case .travelMileage: return "car"
        case .coworkingOffice: return "building.2"
        case .meals: return "fork.knife"
        case .insurance: return "shield"
        case .bankFees: return "creditcard"
        case .miscWriteOffs: return "folder"
        }
    }

    /// Convert to Category model
    func toCategory(sortOrder: Int) -> Category {
        Category(
            id: UUID().uuidString,
            name: self.rawValue,
            icon: self.icon,
            isDefault: true,
            sortOrder: sortOrder
        )
    }

    /// Get all default categories
    static var defaultCategories: [Category] {
        FreelancerCategory.allCases.enumerated().map { index, category in
            category.toCategory(sortOrder: index)
        }
    }
}
