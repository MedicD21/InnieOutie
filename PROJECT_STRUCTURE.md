# InnieOutie - Project Structure

**Finances Made Easy** - A complete iOS expense tracker for freelancers, creators, and side hustlers.

---

## 📁 Final Project Structure

```
InnieOutie/
│
├── README.md                           # Main project documentation
├── IMPLEMENTATION_GUIDE.md              # Setup and deployment guide
├── PRODUCT_BRIEF.md                     # Product vision and strategy
├── PROJECT_STRUCTURE.md                 # This file
│
├── InnieOutieApp.swift                  # App entry point
│
├── Models/
│   ├── Expense.swift                    # Expense data model
│   ├── Income.swift                     # Income data model
│   ├── Category.swift                   # Category model + freelancer presets
│   └── MonthlySnapshot.swift            # Monthly financial summary + User model
│
├── Views/
│   ├── Dashboard/
│   │   ├── DashboardView.swift          # Main dashboard (HERO SCREEN)
│   │   ├── ProfitCardView.swift         # Big profit number display
│   │   ├── MonthPickerView.swift        # Month navigation
│   │   ├── TopCategoriesView.swift      # Top 3 expenses
│   │   ├── IncomeSourcesView.swift      # Income breakdown
│   │   └── QuickAddBar.swift            # Quick action buttons
│   │
│   ├── Expenses/
│   │   └── AddExpenseView.swift         # Expense entry form
│   │
│   ├── Income/
│   │   └── AddIncomeView.swift          # Income entry form
│   │
│   ├── Reports/
│   │   ├── MonthlyReportsView.swift     # Historical reports list
│   │   └── ExportOptionsView.swift      # CSV/PDF export (Pro)
│   │
│   ├── Paywall/
│   │   └── PaywallView.swift            # Pro subscription screen
│   │
│   ├── Onboarding/
│   │   └── OnboardingView.swift         # First-run experience
│   │
│   ├── Authentication/
│   │   └── AuthenticationView.swift     # Guest mode + Sign in with Apple
│   │
│   └── Settings/
│       └── SettingsView.swift           # App settings
│
├── ViewModels/
│   ├── DashboardViewModel.swift         # Dashboard logic
│   ├── AddExpenseViewModel.swift        # Expense form logic
│   ├── AddIncomeViewModel.swift         # Income form logic
│   └── MonthlyReportsViewModel.swift    # Reports logic
│
├── Services/
│   ├── DataService.swift                # SQLite database operations
│   ├── CalculationService.swift         # Profit calculations (CORE LOGIC)
│   ├── PaywallService.swift             # Monetization + StoreKit 2
│   ├── ExportService.swift              # CSV/PDF generation (Pro)
│   └── AuthenticationService.swift      # Auth + guest mode
│
└── Utils/
    ├── SampleData.swift                 # Test data generation
    └── Extensions.swift                 # Helper extensions
```

---

## 🎯 Key Files by Feature

### Core Value Proposition
The **"Am I making money?"** answer comes from:
- `CalculationService.swift` - Profit logic
- `ProfitCardView.swift` - Big bold display
- `DashboardView.swift` - 5-second value

### Monetization
Freemium → Pro conversion handled by:
- `PaywallService.swift` - StoreKit 2 + feature gating
- `PaywallView.swift` - Conversion-optimized UI
- `ExportService.swift` - Pro-only CSV/PDF

### Data Layer
Local-first SQLite powered by:
- `DataService.swift` - All CRUD operations
- Native SQLite (no external dependencies)
- `Models/` - Clean data structures

### User Experience
Speed and clarity through:
- `QuickAddBar.swift` - One-tap entry
- `MonthPickerView.swift` - Easy navigation
- `TopCategoriesView.swift` - Instant insights

---

## 🔧 Setup Instructions

### 1. Open in Xcode

```bash
# Navigate to project
cd ~/Desktop/InnieOutie

# Create Xcode project
# File > New > Project > iOS App
# Name: InnieOutie
# Interface: SwiftUI
# Language: Swift

# Add all .swift files to your project
# Organize into groups matching folder structure above
```

### 2. Configure Project

- **Bundle Identifier**: `com.yourteam.innieoutie`
- **Deployment Target**: iOS 16.0+
- **Development Team**: Select your team

### 3. Add Capabilities

- Sign in with Apple
- In-App Purchase
- iCloud (optional - for Pro sync)

### 4. Update Product IDs

In `PaywallService.swift`:
```swift
static let monthlyProductID = "com.innieoutie.pro.monthly"
static let annualProductID = "com.innieoutie.pro.annual"
```

Match these in App Store Connect.

### 5. Build & Run

```bash
# Select target device/simulator
# Press Cmd+R to build and run
```

---

## 📊 Database Schema

### Tables

**expenses**
- id (TEXT PRIMARY KEY)
- amount (REAL)
- date (INTEGER - Unix timestamp)
- category_id (TEXT)
- note (TEXT, nullable)
- receipt_path (TEXT, nullable, Pro only)
- created_at (INTEGER)

**income**
- id (TEXT PRIMARY KEY)
- amount (REAL)
- date (INTEGER)
- source (TEXT)
- note (TEXT, nullable)
- created_at (INTEGER)

**categories**
- id (TEXT PRIMARY KEY)
- name (TEXT)
- icon (TEXT - SF Symbol name)
- is_default (INTEGER - boolean)
- sort_order (INTEGER)

### Indices
- `idx_expenses_date` - Fast date queries
- `idx_income_date` - Fast date queries

---

## 💰 Monetization Model

### Free Tier
- Current month tracking
- Unlimited entries
- All freelancer categories
- Profit view
- Guest mode

### Pro Tier ($49/year or $8/month)
- Unlimited historical data
- CSV export
- PDF export
- Receipt photo storage
- Cloud sync (future)

### Conversion Triggers
Paywall shows when user:
1. Views past month
2. Taps export CSV
3. Taps export PDF
4. Uploads receipt
5. After 30 days of use (proactive)

**Target**: 5% conversion rate

---

## 🚀 Key Features Walkthrough

### 1. Dashboard (Hero Screen)
**File**: `Views/Dashboard/DashboardView.swift`

Answers "Am I making money?" in 5 seconds:
- Giant profit number (green/red)
- Income vs expenses breakdown
- Month-over-month trend
- Top 3 spending categories
- Income by source

### 2. Quick Entry
**Files**: `Views/Expenses/AddExpenseView.swift`, `Views/Income/AddIncomeView.swift`

Minimal friction data entry:
- Pre-filled date (today)
- Smart category defaults
- Recent sources memory
- Optional notes
- Receipt photos (Pro)

### 3. Calculations
**File**: `Services/CalculationService.swift`

Core business logic:
- Net profit = Income - Expenses
- Profit margin % = (Profit / Income) × 100
- Month-over-month change
- Category totals
- Source totals

### 4. Exports
**File**: `Services/ExportService.swift`

Tax-friendly formats (Pro only):
- CSV with income/expense detail
- PDF professional summary
- Category breakdowns
- Share via iOS share sheet

---

## 🧪 Testing

### Manual Testing
See `IMPLEMENTATION_GUIDE.md` for full checklist.

### Sample Data
Use `Utils/SampleData.swift` to generate test data:
```swift
#if DEBUG
SampleData.seedDatabase(dataService: DataService())
#endif
```

### StoreKit Testing
Use StoreKit Configuration File for local IAP testing.

---

## 📦 Deployment

### Pre-Launch
1. ✅ App icon (1024×1024)
2. ✅ Screenshots (all device sizes)
3. ✅ Privacy policy URL
4. ✅ Terms of service URL
5. ✅ StoreKit products created
6. ✅ TestFlight beta testing

### App Store
- **Category**: Finance > Personal Finance
- **Age Rating**: 4+
- **Price**: Free (with IAP)
- **Keywords**: freelance, expense, income, profit, tax

---

## 🔒 Privacy & Security

### Data Storage
- **Local-first**: All data on device (free tier)
- **No tracking**: No analytics without consent
- **No sharing**: Data never leaves device unless Pro sync enabled

### Authentication
- **Guest mode**: No data collection
- **Sign in with Apple**: Privacy-focused auth
- **Optional**: Sign in NOT required

---

## 🎨 Design System

### Colors
- **Profit**: Green (`Color.green`)
- **Loss**: Red (`Color.red`)
- **Neutral**: Gray (`Color.secondary`)
- **Primary**: Blue (`Color.blue`)

### Typography
- **Profit number**: 52pt, bold, rounded
- **Headlines**: System bold
- **Body**: System regular
- **Captions**: System secondary

### Components
- Rounded cards (16pt radius)
- Shadow: 0.05 opacity, 10pt blur
- Spacing: 24pt between sections
- Padding: 16-20pt inside cards

---

## 📚 Documentation

- **README.md** - High-level overview and roadmap
- **IMPLEMENTATION_GUIDE.md** - Technical setup guide
- **PRODUCT_BRIEF.md** - Product strategy and vision
- **PROJECT_STRUCTURE.md** - This file

---

## 🤝 Contributing (Future)

This is currently a solo project. Future collaboration:
- Bug reports welcome
- Feature requests considered
- Pull requests reviewed
- Translations needed (v2.0)

---

## 📞 Support

- **Email**: support@innieoutie.app
- **Website**: https://innieoutie.app
- **Docs**: All documentation in this repo

---

## 📝 License

Copyright © 2025 InnieOutie

All rights reserved. Proprietary software.

---

**Built for freelancers, creators, streamers, and side hustlers.**

**Finances Made Easy.**

🚀 Now go build an Xcode project and ship it!
