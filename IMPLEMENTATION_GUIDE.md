# InnieOutie - Implementation Guide

**Finances Made Easy**

A complete implementation guide for setting up and deploying the InnieOutie iOS app.

---

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Xcode Setup](#xcode-setup)
3. [App Store Connect Configuration](#app-store-connect-configuration)
4. [StoreKit Products Setup](#storekit-products-setup)
5. [Sign in with Apple Configuration](#sign-in-with-apple-configuration)
6. [Testing Guide](#testing-guide)
7. [Deployment Checklist](#deployment-checklist)

---

## 🚀 Quick Start

### Prerequisites

- macOS Ventura 13.0+
- Xcode 15.0+
- Apple Developer Account ($99/year)
- Basic Swift/SwiftUI knowledge

### Initial Setup

1. **Create Xcode Project**
   ```bash
   # Navigate to the project folder
   cd ProfitLens/ProfitLens

   # Open in Xcode (you'll need to create the .xcodeproj first)
   # File > New > Project
   # Select: iOS > App
   # Name: InnieOutie
   # Interface: SwiftUI
   # Language: Swift
   ```

2. **Copy Source Files**
   - Copy all files from the generated `ProfitLens/` folder into your Xcode project
   - Organize into groups matching the folder structure
   - Ensure all `.swift` files are added to your target

3. **Configure Project Settings**
   - Select your project in Xcode navigator
   - Update **Bundle Identifier**: `com.yourteam.innieoutie`
   - Set **Deployment Target**: iOS 16.0+
   - Select your **Development Team**

---

## 🔧 Xcode Setup

### Required Capabilities

Navigate to **Signing & Capabilities** tab and add:

1. **Sign in with Apple**
   - Click "+ Capability"
   - Search for "Sign in with Apple"
   - Add it

2. **In-App Purchase**
   - Click "+ Capability"
   - Search for "In-App Purchase"
   - Add it

3. **iCloud (Optional - for Pro sync)**
   - Click "+ Capability"
   - Search for "iCloud"
   - Enable "CloudKit"
   - Create a new container: `iCloud.com.yourteam.innieoutie`

### Info.plist Configuration

Add these keys to `Info.plist`:

```xml
<!-- Privacy Descriptions -->
<key>NSPhotoLibraryUsageDescription</key>
<string>InnieOutie needs access to your photo library to attach receipt images to expenses.</string>

<key>NSCameraUsageDescription</key>
<string>InnieOutie needs camera access to take photos of receipts.</string>

<!-- App Transport Security (if needed for web links) -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>
```

---

## 🍎 App Store Connect Configuration

### 1. Create App Record

1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Go to **My Apps** > **+** > **New App**
3. Fill in:
   - **Platform**: iOS
   - **Name**: InnieOutie
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: Select `com.yourteam.innieoutie`
   - **SKU**: `innieoutie-ios-001`
   - **User Access**: Full Access

### 2. App Information

- **Category**: Finance
- **Subcategory**: Personal Finance
- **Content Rights**: Check if you own rights
- **Age Rating**: 4+

### 3. Pricing and Availability

- **Price**: Free
- **Availability**: All territories
- **Pre-orders**: Optional

### 4. App Privacy

Configure data collection:

1. **Data Types Collected**:
   - Email Address (optional - for Sign in with Apple)
   - Name (optional - for Sign in with Apple)
   - Financial Info (expenses, income - not shared)

2. **Data Usage**:
   - App Functionality
   - Analytics (if using analytics)

3. **Data Sharing**:
   - None (local-first app)

---

## 💳 StoreKit Products Setup

### Create Subscription Products

1. In App Store Connect, go to your app
2. Navigate to **Features** > **In-App Purchases**
3. Click **+** to create new subscription

### Product 1: Monthly Subscription

- **Reference Name**: InnieOutie Pro Monthly
- **Product ID**: `com.innieoutie.pro.monthly`
- **Subscription Group**: Create new: "Pro Subscription"
- **Subscription Duration**: 1 Month
- **Pricing**: $7.99/month
- **Display Name**: Pro Monthly
- **Description**: "Get unlimited access to all InnieOutie Pro features with a monthly subscription."
- **Review Screenshot**: Upload app screenshot showing Pro features

### Product 2: Annual Subscription

- **Reference Name**: InnieOutie Pro Annual
- **Product ID**: `com.innieoutie.pro.annual`
- **Subscription Group**: Select "Pro Subscription"
- **Subscription Duration**: 1 Year
- **Pricing**: $49.99/year
- **Display Name**: Pro Annual
- **Description**: "Save 48% with an annual InnieOutie Pro subscription and get unlimited access to all features."
- **Review Screenshot**: Same as monthly

### Subscription Settings

- **Free Trial**: 7 days (optional)
- **Introductory Offer**: 3 months for $4.99 (optional)
- **Auto-Renewable**: Yes
- **Family Sharing**: No

### Testing StoreKit

For local testing, create a **StoreKit Configuration File**:

1. In Xcode: **File** > **New** > **File**
2. Choose **StoreKit Configuration File**
3. Name it `Products.storekit`
4. Add your products manually:

```json
{
  "identifier" : "com.innieoutie.pro.monthly",
  "reference name" : "Pro Monthly",
  "type" : "Auto-Renewable Subscription",
  "duration" : "1 Month",
  "price" : "7.99",
  "subscription_group_id" : "pro_subscription"
}
```

5. In scheme settings: **Product** > **Scheme** > **Edit Scheme**
6. Under **Run** > **Options**, select your StoreKit Configuration

---

## 🔐 Sign in with Apple Configuration

### 1. Enable in Developer Portal

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select your **App ID** (com.yourteam.innieoutie)
4. Enable **Sign in with Apple**
5. Click **Save**

### 2. Configure in App Store Connect

1. In App Store Connect, go to your app
2. Navigate to **App Information**
3. Under **Sign in with Apple**, enable it
4. Set **Primary App ID** if you have multiple apps

### 3. Test Sign in with Apple

- Use real device OR simulator with Apple ID signed in
- Test both new account creation and existing account sign-in
- Verify email/name are properly retrieved

---

## 🧪 Testing Guide

### Unit Testing (Optional but Recommended)

Create tests for core business logic:

```swift
// Tests/CalculationServiceTests.swift
import XCTest
@testable import InnieOutie

class CalculationServiceTests: XCTestCase {
    func testProfitCalculation() {
        let income = [Income(amount: 5000, date: Date(), source: "Client")]
        let expenses = [Expense(amount: 2000, date: Date(), categoryId: "test")]

        let snapshot = CalculationService.calculateMonthlySnapshot(
            expenses: expenses,
            income: income,
            categories: [],
            for: Date()
        )

        XCTAssertEqual(snapshot.netProfit, 3000)
        XCTAssertTrue(snapshot.isProfit)
    }
}
```

### Manual Testing Checklist

#### Core Features
- [ ] Add expense with all category types
- [ ] Add income with different sources
- [ ] View dashboard with zero data (empty state)
- [ ] View dashboard with populated data
- [ ] Navigate between months
- [ ] Delete expense
- [ ] Delete income

#### Authentication
- [ ] Start in guest mode
- [ ] Sign in with Apple (new account)
- [ ] Sign in with Apple (existing account)
- [ ] Sign out
- [ ] Upgrade guest to signed in

#### Monetization
- [ ] Free tier: view current month only
- [ ] Paywall shown when viewing historical month
- [ ] Paywall shown when exporting CSV
- [ ] Paywall shown when exporting PDF
- [ ] Paywall shown when uploading receipt
- [ ] Purchase monthly subscription (sandbox)
- [ ] Purchase annual subscription (sandbox)
- [ ] Restore purchases
- [ ] Pro features unlock after purchase

#### Export (Pro Only)
- [ ] Export CSV with data
- [ ] Export PDF with data
- [ ] Share exported file

### TestFlight Beta Testing

1. **Create Build**
   ```bash
   # Archive your app
   # Product > Archive
   # Wait for archive to complete
   ```

2. **Upload to App Store Connect**
   - Window > Organizer
   - Select your archive
   - Click **Distribute App**
   - Choose **App Store Connect**
   - Upload

3. **Configure TestFlight**
   - In App Store Connect, go to **TestFlight** tab
   - Add internal/external testers
   - Write test notes
   - Submit for beta review (external only)

4. **Gather Feedback**
   - Monitor crash reports
   - Read tester feedback
   - Iterate and upload new builds

---

## 📦 Deployment Checklist

### Pre-Submission

- [ ] App icon (1024x1024, no transparency)
- [ ] Launch screen configured
- [ ] All capabilities enabled in Xcode
- [ ] StoreKit products created and approved
- [ ] Privacy policy URL live: `https://innieoutie.app/privacy`
- [ ] Terms of service URL live: `https://innieoutie.app/terms`
- [ ] Support URL live: `https://innieoutie.app/support`

### App Store Screenshots

Required sizes:
- **6.7" (iPhone 14 Pro Max)**: 1290 x 2796 pixels
- **6.5" (iPhone 11 Pro Max)**: 1242 x 2688 pixels
- **5.5" (iPhone 8 Plus)**: 1242 x 2208 pixels

Recommended screenshots:
1. Dashboard with profit data
2. Add expense screen
3. Add income screen
4. Monthly reports
5. Pro paywall

### App Preview Video (Optional)

- 15-30 seconds
- Show core user flow
- Highlight value proposition

### App Store Listing

**App Name**: InnieOutie - Finances Made Easy

**Subtitle**: Track Income & Expenses

**Description**:
```
InnieOutie makes freelance finances simple.

Know exactly if you're making money this month—no accounting degree required.

✨ MADE FOR CREATORS & FREELANCERS
• Track income from clients and platforms
• Manage business expenses with smart categories
• See your profit at a glance

💰 CLEAR PROFIT VIEW
• Instant net profit calculation
• Income vs expenses breakdown
• Month-over-month trends
• Top spending categories

📊 PRO FEATURES
• Unlimited history (Free: current month only)
• CSV & PDF exports for taxes
• Receipt photo storage
• Cloud sync across devices

🚀 FAST & SIMPLE
• Manual entry only—no bank linking complexity
• One-tap expense/income tracking
• Guest mode (no sign-up required)
• Local-first, works offline

Perfect for:
• Freelancers & Contractors
• Content Creators & Streamers
• Side Hustlers
• Self-Employed Professionals
• 1099 Workers

Stop wondering if you're profitable. Start knowing with InnieOutie.

---

Free tier includes:
• Current month tracking
• All core features
• Unlimited entries

Pro subscription ($49/year or $8/month):
• All historical data
• Export to CSV/PDF
• Receipt storage
• Cloud backup

Terms: https://innieoutie.app/terms
Privacy: https://innieoutie.app/privacy
```

**Keywords**:
```
freelance,expense,income,profit,tax,business,accounting,1099,creator,self-employed
```

**Promotional Text**:
```
Track your freelance income and expenses. See your profit instantly. No accounting knowledge needed.
```

### App Review Notes

Provide test account and notes for reviewers:

```
TEST ACCOUNT:
Guest Mode: Tap "Start Using InnieOutie" (no credentials needed)

TESTING INSTRUCTIONS:
1. App starts in guest mode by default
2. Add sample expense via bottom bar
3. Add sample income via bottom bar
4. View profit on dashboard
5. Tap "Upgrade to Pro" to see paywall (DO NOT PURCHASE)

SUBSCRIPTIONS:
- Monthly: $7.99/month
- Annual: $49.99/year

All features work in free tier for current month.
Pro features unlock historical data and exports.

Data is stored locally—no user data collected.
```

---

## 🐛 Common Issues & Solutions

### Issue: "Failed to verify StoreKit products"

**Solution**:
- Ensure product IDs match exactly in code and App Store Connect
- Products must be "Ready to Submit" status
- Wait 24 hours after creating products
- Test with StoreKit Configuration File locally

### Issue: "Sign in with Apple not working"

**Solution**:
- Verify capability is enabled in Xcode
- Check App ID has Sign in with Apple enabled in Developer Portal
- Ensure device/simulator has Apple ID signed in
- Test on real device for best results

### Issue: "App crashes on launch"

**Solution**:
- Check database initialization in DataService
- Verify all @EnvironmentObject dependencies are provided
- Test with clean install (delete app, reinstall)
- Check Console for crash logs

### Issue: "Export files not saving"

**Solution**:
- Verify Info.plist has photo library permissions
- Check file system access in Sandbox
- Test export on real device, not simulator
- Ensure Pro status is properly set

---

## 📞 Support & Resources

### Official Documentation
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [StoreKit 2 Guide](https://developer.apple.com/documentation/storekit)
- [Sign in with Apple](https://developer.apple.com/sign-in-with-apple/)

### Community
- [Swift Forums](https://forums.swift.org)
- [Apple Developer Forums](https://developer.apple.com/forums)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/swiftui)

### Contact
- Email: support@innieoutie.app
- Website: https://innieoutie.app

---

## 🎯 Post-Launch Checklist

### Week 1
- [ ] Monitor crash reports
- [ ] Respond to user reviews
- [ ] Track conversion metrics
- [ ] Check paywall performance

### Week 2
- [ ] Analyze user behavior
- [ ] Identify drop-off points
- [ ] Plan feature improvements
- [ ] A/B test paywall copy (if traffic allows)

### Month 1
- [ ] Hit first 100 users
- [ ] Achieve 5% Pro conversion (target)
- [ ] Collect user feedback
- [ ] Plan v1.1 features

---

**Made with ❤️ for freelancers, creators, and side hustlers everywhere.**
