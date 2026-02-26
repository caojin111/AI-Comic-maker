//
//  PaywallView.swift
//  AI Picture Book
//
//  Subscription paywall: benefits, yearly/monthly plans, restore, subscribe button.
//

import SwiftUI

struct PaywallView: View {
    @Environment(AppState.self) private var appState

    enum Plan: String, CaseIterable {
        case yearly = "Yearly"
        case monthly = "Monthly"
    }

    private let yearlyPrice = "$29.99"
    private let monthlyPrice = "$4.99"
    private let yearlySavePercent = "53"

    @State private var selectedPlan: Plan = .yearly

    private var billingDescription: String {
        switch selectedPlan {
        case .yearly:
            return "$0.00 due today, then \(yearlyPrice) billed every year"
        case .monthly:
            return "\(monthlyPrice) due today, then \(monthlyPrice) billed every month"
        }
    }

    private let benefits: [(icon: String, text: String)] = [
        ("book.pages.fill", "Unlimited AI storybooks"),
        ("wand.and.stars", "New characters & themes"),
        ("speaker.wave.2.fill", "Read-aloud for every page"),
        ("photo.stack.fill", "Custom illustrations per story")
    ]

    var body: some View {
        ZStack {
            AppTheme.bgPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    HStack {
                        Spacer()
                        Button(action: {
                            appState.dismissPaywall()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(AppTheme.font(size: 32))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .buttonStyle(ClickSoundButtonStyle())
                        .padding(.trailing, 20)
                        .padding(.top, 16)
                    }

                    Text("Unlock unlimited stories")
                        .font(AppTheme.font(size: 26))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("Choose the plan that works for you")
                        .font(AppTheme.font(size: 16))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.bottom, 8)

                    // Benefits with icons
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(benefits.enumerated()), id: \.offset) { _, item in
                            HStack(spacing: 14) {
                                Image(systemName: item.icon)
                                    .font(AppTheme.font(size: 20))
                                    .foregroundStyle(AppTheme.primary)
                                    .frame(width: 28, alignment: .center)
                                Text(item.text)
                                    .font(AppTheme.font(size: 15))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)

                    // Plan cards: Yearly first (with Save 53%), then Monthly
                    VStack(spacing: 12) {
                        planCard(
                            plan: .yearly,
                            title: "Yearly",
                            price: yearlyPrice,
                            period: "1-week free trial",
                            badge: "Save \(yearlySavePercent)%"
                        )
                        planCard(
                            plan: .monthly,
                            title: "Monthly",
                            price: monthlyPrice,
                            period: "1-week free trial",
                            badge: nil
                        )
                    }
                    .padding(.horizontal, 24)

                    // Billing description below plan selection
                    Text(billingDescription)
                        .font(AppTheme.font(size: 13))
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)

                    // Subscribe button (triggers purchase flow)
                    Button(action: {
                        print("[PaywallView] Subscribe tapped, plan: \(selectedPlan.rawValue)")
                        appState.dismissPaywall()
                    }) {
                        Text("Start your free week!")
                            .font(AppTheme.font(size: 18))
                            .foregroundStyle(AppTheme.textOnLight)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    // Restore purchases
                    Button(action: {
                        print("[PaywallView] Restore purchases")
                    }) {
                        Text("Restore purchases")
                            .font(AppTheme.font(size: 14))
                            .foregroundStyle(AppTheme.textSecondary)
                            .underline()
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
        }
    }

    @ViewBuilder
    private func planCard(plan: Plan, title: String, price: String, period: String, badge: String?) -> some View {
        let isSelected = selectedPlan == plan
        Button(action: {
            selectedPlan = plan
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(AppTheme.font(size: 18))
                            .foregroundStyle(AppTheme.textOnLight)
                        if let badge = badge {
                            Text(badge)
                                .font(AppTheme.font(size: 12))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green, in: RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    Text(period)
                        .font(AppTheme.font(size: 13))
                        .foregroundStyle(Color.gray)
                }
                Spacer()
                Text(price)
                    .font(AppTheme.font(size: 18))
                    .foregroundStyle(AppTheme.primary)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? AppTheme.primary : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(ClickSoundButtonStyle())
    }
}

#Preview {
    PaywallView()
        .environment(AppState.shared)
}
