# InnieOutie 📊

**Finances Made Easy**

A niche expense tracker for freelancers who want to know: "Am I actually making money?"

Built for iOS using native Swift and SwiftUI.

---

## 🎯 Core Value Proposition

InnieOutie answers one question better than any other app:

> **"Did I make money this month?"**

No accounting knowledge required. No complex setup. Just clarity on your profitability.

---

## ✨ Features

### Free Tier
- ✅ Manual income & expense tracking
- ✅ Current month dashboard with profit view
- ✅ Freelancer-specific expense categories
- ✅ Net profit calculation
- ✅ Top expense categories
- ✅ Income by source breakdown

### Pro Tier ($49/year or $8/month)
- 👑 Unlimited historical data
- 👑 CSV export for taxes
- 👑 PDF professional reports
- 👑 Receipt photo storage
- 👑 Cloud sync across devices

---

## 🏗️ Architecture

### Tech Stack
- **Platform**: iOS 16+
- **Language**: Swift
- **UI Framework**: SwiftUI
- **Database**: SQLite (native)
- **Authentication**: Sign in with Apple
- **Payments**: StoreKit 2
- **Architecture**: MVVM

### Project Structure

```
InnieOutie/
├── Models/
│   ├── Expense.swift           # Expense data model
│   ├── Income.swift            # Income data model
│   ├── Category.swift          # Category model + freelancer presets
│   └── MonthlySnapshot.swift   # Monthly financial summary
│
├── Views/
│   ├── Dashboard/
│   │   ├── DashboardView.swift          # Main dashboard (HERO)
│   │   ├── ProfitCardView.swift         # Profit display card
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
│   │   ├── MonthlyReportsView.swift     # Historical reports
│   │   └── ExportOptionsView.swift      # CSV/PDF export
│   │
│   ├── Paywall/
│   │   └── PaywallView.swift            # Pro subscription
│   │
│   ├── Onboarding/
│   │   └── OnboardingView.swift         # First-run experience
│   │
│   ├── Authentication/
│   │   └── AuthenticationView.swift     # Guest/Sign in
│   │
│   └── Settings/
│       └── SettingsView.swift           # App settings
│
├── ViewModels/
│   ├── DashboardViewModel.swift
│   ├── AddExpenseViewModel.swift
│   ├── AddIncomeViewModel.swift
│   └── MonthlyReportsViewModel.swift
│
├── Services/
│   ├── DataService.swift              # SQLite CRUD operations
│   ├── CalculationService.swift       # Profit logic (CORE)
│   ├── PaywallService.swift           # Monetization + StoreKit
│   ├── ExportService.swift            # CSV/PDF generation
│   └── AuthenticationService.swift    # Auth + guest mode
│
└── Utils/
    ├── SampleData.swift               # Test data generation
    └── Extensions.swift               # Helper extensions
```

---

## 💰 Monetization Strategy

### Freemium → Pro Model

**Free Tier Limitations:**
- Current month data only
- No exports
- No receipt storage
- No cloud sync

**Pro Triggers (Paywall shown when):**
- User tries to view historical months
- User taps "Export CSV/PDF"
- User tries to upload receipt photo
- User has tracked 30+ days (proactive prompt)

**Pricing:**
- Monthly: $8/month
- Annual: $49/year (49% savings)

**Target Conversion:** 5% of free users → Pro within 60 days

---

## 🎨 Design Principles

1. **CLARITY > FEATURES**
   - One question: "Am I making money?"
   - Big, bold profit number
   - Green = good, Red = bad

2. **SPEED > COMPLETENESS**
   - Manual entry only (no bank sync complexity)
   - One-tap quick add
   - Smart defaults

3. **NICHE > GENERIC**
   - Freelancer-specific categories
   - Platform fees, client tracking
   - Tax-friendly language

4. **LOCAL-FIRST**
   - SQLite database
   - Works offline
   - Cloud sync is Pro feature

---

## 📊 Database Schema

```sql
-- EXPENSES
CREATE TABLE expenses (
    id TEXT PRIMARY KEY,
    amount REAL NOT NULL,
    date INTEGER NOT NULL,
    category_id TEXT NOT NULL,
    note TEXT,
    receipt_path TEXT,
    created_at INTEGER NOT NULL
);

-- INCOME
CREATE TABLE income (
    id TEXT PRIMARY KEY,
    amount REAL NOT NULL,
    date INTEGER NOT NULL,
    source TEXT NOT NULL,
    note TEXT,
    created_at INTEGER NOT NULL
);

-- CATEGORIES (Preloaded + Custom)
CREATE TABLE categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    icon TEXT NOT NULL,
    is_default INTEGER NOT NULL DEFAULT 0,
    sort_order INTEGER NOT NULL DEFAULT 0
);
```

**Indices:**
- `idx_expenses_date` on expenses(date DESC)
- `idx_income_date` on income(date DESC)

---

## 🚀 Setup Instructions

### Prerequisites
- Xcode 15+
- iOS 16+ deployment target
- Apple Developer Account (for Sign in with Apple)

### Installation

1. **Open Project in Xcode**
   ```bash
   cd ProfitLens/ProfitLens
   open InnieOutie.xcodeproj
   ```

2. **Configure Signing**
   - Select your development team
   - Update bundle identifier: `com.yourteam.innieoutie`

3. **Enable Capabilities**
   - Sign in with Apple
   - In-App Purchase
   - iCloud (for Pro sync - optional)

4. **Configure StoreKit**
   - Create products in App Store Connect:
     - `com.innieoutie.pro.monthly` (Auto-renewable subscription)
     - `com.innieoutie.pro.annual` (Auto-renewable subscription)
   - Update product IDs in `PaywallService.swift`

5. **Run**
   ```bash
   # Build and run on simulator or device
   ⌘ + R
   ```

### Testing with Sample Data

To seed the database with test data:

```swift
// In DashboardView or App init
#if DEBUG
SampleData.seedDatabase(dataService: DataService())
#endif
```

---

## 🧪 Testing Checklist

### Core Functionality
- [ ] Add expense (all categories)
- [ ] Add income (multiple sources)
- [ ] View dashboard profit calculation
- [ ] Navigate between months (Pro)
- [ ] Delete expense/income
- [ ] Receipt photo upload (Pro)

### Monetization
- [ ] Paywall triggers correctly
- [ ] StoreKit sandbox purchase (monthly)
- [ ] StoreKit sandbox purchase (annual)
- [ ] Restore purchases
- [ ] Pro features unlock after purchase

### Authentication
- [ ] Guest mode works
- [ ] Sign in with Apple
- [ ] Sign out
- [ ] Upgrade guest → signed in

### Edge Cases
- [ ] Empty state (no data)
- [ ] Large amounts (formatting)
- [ ] Negative profit
- [ ] Zero income/expenses
- [ ] Special characters in notes

---

## 📱 App Store Submission Checklist

### Required Assets
- [ ] App icon (1024x1024)
- [ ] Screenshots (6.5", 6.7", 12.9" iPad)
- [ ] App preview video (optional but recommended)

### Required URLs
- [ ] Privacy Policy: `https://innieoutie.app/privacy`
- [ ] Terms of Service: `https://innieoutie.app/terms`
- [ ] Support URL: `https://innieoutie.app/support`

### App Store Connect
- [ ] App Information
  - Category: Finance
  - Subcategory: Personal Finance
- [ ] Pricing & Availability
  - Free download
  - In-app purchases configured
- [ ] App Review Information
  - Test account credentials
  - Notes for reviewer
- [ ] App Privacy
  - Data collection disclosure
  - Sign in with Apple configured

### Keywords
```
freelance, expense tracker, profit, income, tax, self-employed,
contractor, 1099, business expenses, write-offs
```

---

## 🗓️ 30-Day MVP Roadmap

### Week 1: Foundation
- ✅ Database schema
- ✅ Core models
- ✅ DataService CRUD
- ✅ CalculationService

### Week 2: Core Features
- ✅ Dashboard UI
- ✅ Add Expense/Income forms
- ✅ Category management
- ✅ Profit calculations

### Week 3: Monetization
- ✅ PaywallService
- ✅ StoreKit integration
- ✅ Paywall UI
- ✅ Export features (Pro)

### Week 4: Polish & Ship
- ✅ Onboarding
- ✅ Sign in with Apple
- ✅ Settings
- ⏳ App Store submission
- ⏳ Marketing assets

---

## 🎯 Key Metrics to Track

### Engagement
- Daily active users
- Average expenses/income tracked per user
- Dashboard views per session

### Monetization
- Paywall impression rate
- Paywall conversion rate (target: 5%)
- Average revenue per user (ARPU)
- Churn rate

### Triggers Performance
- Which paywall trigger converts best
- Time to first paywall
- Time to conversion

---

## 🚫 What We're NOT Building (Scope)

- ❌ Bank integrations
- ❌ Budgeting features
- ❌ Forecasting/predictions
- ❌ Investment tracking
- ❌ Multi-currency (v1)
- ❌ Team/collaboration
- ❌ AI categorization
- ❌ Receipts OCR (v1)

**Focus:** Ship fast, validate, iterate.

---

## 🔮 Future Enhancements (Post-MVP)

### Version 1.1
- Client-level profitability tracking
- Quarterly tax estimates
- Mileage auto-tracking

### Version 1.2
- Stripe/PayPal integration
- Invoice generation
- Expense rules/automation

### Version 2.0
- Web dashboard
- Accountant export
- Multi-user (for agencies)

---

## 📄 License

Copyright © 2025 InnieOutie

All rights reserved. This is proprietary software.

---

## 🤝 Support

- Email: support@innieoutie.app
- Website: https://innieoutie.app
- Twitter: @innieoutieapp

---

## 🎉 Credits

Built by an indie developer who understands freelance struggles.

**Tech Stack:**
- Swift & SwiftUI
- SQLite
- StoreKit 2
- Sign in with Apple

**Inspiration:**
Every freelancer who's asked: "Wait, did I actually make money last month?"

---

Made with ❤️ for freelancers everywhere.
