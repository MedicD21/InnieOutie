//
//  MonthPickerView.swift
//  ProfitLens
//
//  Month navigation component for Dashboard
//

import SwiftUI

struct MonthPickerView: View {
    @Binding var selectedMonth: Date
    @EnvironmentObject var paywallService: PaywallService

    var onMonthChange: ((Date) -> Void)?

    private var canGoBack: Bool {
        // Pro users can view any month
        if paywallService.isPro {
            return true
        }

        // Free users can only view current month
        return false
    }

    private var canGoForward: Bool {
        let calendar = Calendar.current
        return !calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    var body: some View {
        HStack {
            // Previous month button
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(canGoBack ? .primary : .gray.opacity(0.3))
                    .frame(width: 44, height: 44)
            }
            .disabled(!canGoBack)

            Spacer()

            // Month display
            VStack(spacing: 4) {
                Text(monthName)
                    .font(.title3.bold())

                Text(yearString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Next month button
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(canGoForward ? .primary : .gray.opacity(0.3))
                    .frame(width: 44, height: 44)
            }
            .disabled(!canGoForward)
        }
        .padding(.horizontal)
    }

    private var monthName: String {
        selectedMonth.formatted(.dateTime.month(.wide))
    }

    private var yearString: String {
        selectedMonth.formatted(.dateTime.year())
    }

    private func previousMonth() {
        guard let previous = CalculationService.previousMonth(from: selectedMonth) else {
            return
        }

        // Check if this requires Pro
        if !CalculationService.isWithinFreeTierLimit(date: previous) {
            if !paywallService.requestAccess(to: .unlimitedHistory, trigger: .viewHistoricalMonth) {
                return  // Paywall shown
            }
        }

        selectedMonth = previous
        onMonthChange?(previous)
    }

    private func nextMonth() {
        guard let next = CalculationService.nextMonth(from: selectedMonth) else {
            return
        }

        selectedMonth = next
        onMonthChange?(next)
    }
}

// MARK: - Preview

#Preview {
    MonthPickerView(selectedMonth: .constant(Date()))
        .environmentObject(PaywallService())
}
