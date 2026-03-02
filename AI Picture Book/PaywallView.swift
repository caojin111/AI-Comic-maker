//
//  PaywallView.swift
//  AI Picture Book
//
//  Subscription paywall: benefits, yearly/monthly plans, restore, subscribe button.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(AppState.self) private var appState
    private let purchaseManager = PurchaseManager.shared

    enum Plan: String, CaseIterable {
        case yearly = "Yearly"
        case monthly = "Monthly"
    }

    private let yearlyPrice = "$39.99"
    private let monthlyPrice = "$9.99"
    private let yearlySavePercent = "60"

    @State private var selectedPlan: Plan = .yearly

    private var childNameForTitle: String {
        let name = appState.childName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "your child" : name
    }

    private var billingDescription: String {
        switch selectedPlan {
        case .yearly:
            return "$0.00 due today, then $39.99 billed every year"
        case .monthly:
            return "$9.99 due today, then $9.99 billed every month"
        }
    }

    private let benefits: [(icon: String, text: String)] = [
        ("book.pages.fill", "Unlimited AI storybooks"),
        ("wand.and.stars", "New characters & themes"),
        ("speaker.wave.2.fill", "Read-aloud for every page"),
        ("photo.stack.fill", "Custom illustrations per story")
    ]

    private func productID(for plan: Plan) -> PurchaseManager.ProductID {
        switch plan {
        case .yearly: return .yearly
        case .monthly: return .monthly
        }
    }

    private func product(for plan: Plan) -> Product? {
        purchaseManager.product(for: productID(for: plan))
    }

    private var yearlyDisplayPrice: String {
        if let p = product(for: .yearly) {
            print("[PaywallView] Yearly product found: \(p.id), price: \(p.displayPrice)")
            return p.displayPrice
        }
        print("[PaywallView] Yearly product NOT found, using fallback: \(yearlyPrice)")
        return yearlyPrice
    }

    private var monthlyDisplayPrice: String {
        if let p = product(for: .monthly) {
            print("[PaywallView] Monthly product found: \(p.id), price: \(p.displayPrice)")
            return p.displayPrice
        }
        print("[PaywallView] Monthly product NOT found, using fallback: \(monthlyPrice)")
        return monthlyPrice
    }

    private func purchaseSelectedPlan() async {
        if product(for: selectedPlan) == nil {
            print("[PaywallView] 未找到商品缓存，先尝试重新拉取商品...")
            await purchaseManager.loadProductsIfNeeded()
        }
        guard let product = product(for: selectedPlan) else {
            print("[PaywallView] 未找到对应的 StoreKit 商品: \(selectedPlan.rawValue)，请检查 App Store Connect 中的 product id 是否与代码一致：yearlyplan_29.99 / monthlyplan_14.99")
            return
        }
        let success = await purchaseManager.purchase(product)
        if success {
            print("[PaywallView] 购买成功，关闭 paywall")
            
            // 根据订阅类型赠送小鱼干
            let fishCoinManager = FishCoinManager.shared
            if selectedPlan == .yearly {
                fishCoinManager.grantYearlySubscriptionReward()
            } else {
                fishCoinManager.grantMonthlySubscriptionReward()
            }
            
            appState.dismissPaywall()
        } else {
            print("[PaywallView] 购买未完成或失败")
        }
    }

    var body: some View {
        ZStack {
            AppTheme.bgPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
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
                        .padding(.top, 6)
                    }

                    (Text("Ready to read with ").font(AppTheme.font(size: 26)).foregroundStyle(AppTheme.textPrimary) + Text(childNameForTitle).font(AppTheme.font(size: 26)).foregroundStyle(Color(hex: "FEB979")) + Text("?").font(AppTheme.font(size: 26)).foregroundStyle(AppTheme.textPrimary))
                        .multilineTextAlignment(.center)
                    Text("Choose the plan that works for you")
                        .font(AppTheme.font(size: 16))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.bottom, 4)

                    // Benefits with icons
                    VStack(alignment: .leading, spacing: 10) {
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
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 4)

                    // Plan cards: Yearly first (with Save 53%), then Monthly
                    VStack(spacing: 10) {
                        planCard(
                            plan: .yearly,
                            title: "Yearly",
                            price: yearlyDisplayPrice,
                            period: "1-week free trial",
                            badge: "Save \(yearlySavePercent)%"
                        )
                        planCard(
                            plan: .monthly,
                            title: "Monthly",
                            price: monthlyDisplayPrice,
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
                        .padding(.top, 2)

                    // Subscribe button (triggers purchase flow)
                    Button(action: {
                        print("[PaywallView] Subscribe tapped, plan: \(selectedPlan.rawValue)")
                        Task {
                            await purchaseSelectedPlan()
                        }
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
                    .padding(.top, 4)

                    // Restore purchases
                    Button(action: {
                        print("[PaywallView] Restore purchases")
                        Task {
                            await purchaseManager.restorePurchases()
                        }
                    }) {
                        Text("Restore purchases")
                            .font(AppTheme.font(size: 14))
                            .foregroundStyle(AppTheme.textSecondary)
                            .underline()
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                    .padding(.top, 8)

                    // Long-page extra info sections
                    VStack(alignment: .leading, spacing: 16) {
                        // How your free trial works
                        Text("How your free trial works")
                            .font(AppTheme.fontBold(size: 18))
                            .foregroundStyle(AppTheme.textPrimary)
                        VStack(spacing: 16) {
                            // Simple arrow bar to echo the reference style
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 999)
                                    .fill(Color.white.opacity(0.18))
                                    .frame(height: 12)
                                RoundedRectangle(cornerRadius: 999)
                                    .fill(AppTheme.primary)
                                    .frame(width: 160, height: 12)
                            }
                            HStack(alignment: .top, spacing: 20) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Today")
                                        .font(AppTheme.fontBold(size: 15))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text("Get instant access and start learning!")
                                        .font(AppTheme.font(size: 13))
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Day 5")
                                        .font(AppTheme.fontBold(size: 15))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text("We'll remind you that your trial is ending by email.")
                                        .font(AppTheme.font(size: 13))
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Day 7")
                                        .font(AppTheme.fontBold(size: 15))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text("Your subscription starts.\nCancel any time.")
                                        .font(AppTheme.font(size: 13))
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))

                        // How can I cancel?
                        Text("How can I cancel?")
                            .font(AppTheme.fontBold(size: 18))
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(.top, 8)
                        Text("""
It's easy: Open the AI Picture Book app, tap Settings at the top right, and then \"Cancel Free Trial.\" Now you're in your App Store Subscriptions. Select AI Picture Book, \"Cancel Trial\" and confirm.
""")
                        .font(AppTheme.font(size: 13))
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.leading)
                        .padding(16)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // Terms & Privacy links at the very bottom
                    HStack(spacing: 24) {
                        Button(action: {
                            print("[PaywallView] Terms of Use tapped")
                        }) {
                            Text("Terms of Use")
                                .font(AppTheme.font(size: 13))
                                .foregroundStyle(AppTheme.textSecondary)
                                .underline()
                        }
                        .buttonStyle(ClickSoundButtonStyle())

                        Button(action: {
                            print("[PaywallView] Privacy Policy tapped")
                        }) {
                            Text("Privacy Policy")
                                .font(AppTheme.font(size: 13))
                                .foregroundStyle(AppTheme.textSecondary)
                                .underline()
                        }
                        .buttonStyle(ClickSoundButtonStyle())
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
                .task {
                    print("[PaywallView] task 开始，加载商品...")
                    await purchaseManager.loadProductsIfNeeded()
                    print("[PaywallView] task 完成，商品数量: \(purchaseManager.products.count)")
                    print("[PaywallView] Yearly price: \(yearlyDisplayPrice)")
                    print("[PaywallView] Monthly price: \(monthlyDisplayPrice)")
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
