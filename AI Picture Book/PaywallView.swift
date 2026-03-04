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
    @State private var showRestoreAlert = false
    @State private var restoreAlertMessage = ""

    private var childNameForTitle: String {
        let name = appState.childName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "your child" : name
    }

    private var billingDescription: String {
        switch selectedPlan {
        case .yearly:
            return "$0.00 due today, then \(yearlyDisplayPrice) billed every year"
        case .monthly:
            return "\(monthlyDisplayPrice) due today, then \(monthlyDisplayPrice) billed every month"
        }
    }

    private let benefits: [(icon: String, text: String)] = [
        ("book.pages.fill", "Create personalized storybooks"),
        ("square.stack.3d.up.fill", "Unlimited story storage"),
        ("speaker.wave.2.fill", "Expressive voice narration"),
        ("sparkles", "Ad-free, pure enjoyment")
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
            // 艺术感渐变背景
            LinearGradient(
                colors: [
                    Color(hex: "05C187"),
                    Color(hex: "04A870"),
                    Color(hex: "038F5E")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 装饰性圆形元素（增加设计感）
            GeometryReader { geo in
                // 左上角大圆
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 280, height: 280)
                    .offset(x: -100, y: -80)
                
                // 右上角中圆
                Circle()
                    .fill(Color(hex: "FFF07F").opacity(0.12))
                    .frame(width: 180, height: 180)
                    .offset(x: geo.size.width - 80, y: 50)
                
                // 左下角小圆
                Circle()
                    .fill(Color(hex: "D0FBC3").opacity(0.15))
                    .frame(width: 150, height: 150)
                    .offset(x: -40, y: geo.size.height - 100)
                
                // 右下角装饰圆
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 200, height: 200)
                    .offset(x: geo.size.width - 60, y: geo.size.height - 80)
                
                // Thumb 图片 - 放在左上角作为装饰，半透明
                Image("thumb")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-10))
                    .offset(x: -30, y: -20)
                    .opacity(0.4)
                
                // Sleep 图片 - 放在右下角作为装饰，半透明，镜像反转
                Image("sleep")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 270, height: 270)
                    .scaleEffect(x: -1, y: 1)
                    .rotationEffect(.degrees(10))
                    .offset(x: geo.size.width - 200, y: geo.size.height - 200)
                    .opacity(0.4)
            }
            .allowsHitTesting(false)

            ScrollView {
                VStack(spacing: 18) {
                    // 顶部留白，保持视觉平衡
                    Spacer()
                        .frame(height: 20)

                    (Text("Ready to read with ").font(AppTheme.font(size: 26)).foregroundStyle(.white) + Text(childNameForTitle).font(AppTheme.font(size: 26)).foregroundStyle(Color(hex: "FEB979")) + Text("?").font(AppTheme.font(size: 26)).foregroundStyle(.white))
                        .multilineTextAlignment(.center)
                    Text("Choose the plan that works for you")
                        .font(AppTheme.font(size: 16))
                        .foregroundStyle(.white)
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
                                    .foregroundStyle(Color(hex: "03412E"))
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(hex: "D0FBC3"), in: RoundedRectangle(cornerRadius: 12))
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
                        .foregroundStyle(.white)
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
                            // 恢复后检查订阅状态
                            let hasSubscription = await purchaseManager.hasActiveSubscription()
                            if hasSubscription {
                                print("[PaywallView] 恢复购买成功，有有效订阅")
                                appState.dismissPaywall()
                            } else {
                                print("[PaywallView] 恢复购买完成，但未找到有效订阅")
                                restoreAlertMessage = "No active subscription found. Please check your purchase history or contact support."
                                showRestoreAlert = true
                            }
                        }
                    }) {
                        Text("Restore purchases")
                            .font(AppTheme.font(size: 14))
                            .foregroundStyle(.white)
                            .underline()
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                    .padding(.top, 8)

                    // Long-page extra info sections
                    VStack(alignment: .leading, spacing: 16) {
                        // How your free trial works
                        Text("How your free trial works")
                            .font(AppTheme.fontBold(size: 18))
                            .foregroundStyle(.white)
                        VStack(spacing: 16) {
                            // Simple arrow bar to echo the reference style
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 999)
                                    .fill(Color(hex: "FFF07F"))
                                    .frame(height: 12)
                                RoundedRectangle(cornerRadius: 999)
                                    .fill(AppTheme.primary)
                                    .frame(width: 160, height: 12)
                            }
                            HStack(alignment: .top, spacing: 20) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Today")
                                        .font(AppTheme.fontBold(size: 15))
                                        .foregroundStyle(Color(hex: "03412E"))
                                    Text("Get instant access and start learning!")
                                        .font(AppTheme.font(size: 13))
                                        .foregroundStyle(Color(hex: "03412E"))
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Day 5")
                                        .font(AppTheme.fontBold(size: 15))
                                        .foregroundStyle(Color(hex: "03412E"))
                                    Text("We'll remind you that your trial is ending by email.")
                                        .font(AppTheme.font(size: 13))
                                        .foregroundStyle(Color(hex: "03412E"))
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Day 7")
                                        .font(AppTheme.fontBold(size: 15))
                                        .foregroundStyle(Color(hex: "03412E"))
                                    Text("Your subscription starts.\nCancel any time.")
                                        .font(AppTheme.font(size: 13))
                                        .foregroundStyle(Color(hex: "03412E"))
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(hex: "D0FBC3"), in: RoundedRectangle(cornerRadius: 16))

                        // How can I cancel?
                        Text("How can I cancel?")
                            .font(AppTheme.fontBold(size: 18))
                            .foregroundStyle(.white)
                            .padding(.top, 8)
                        Text("""
It's easy: Go to your iPhone Settings, tap your Apple ID at the top, select "Subscriptions," find AI Picture Book, and tap "Cancel Subscription." You can cancel anytime before the trial ends.
""")
                        .font(AppTheme.font(size: 13))
                        .foregroundStyle(Color(hex: "03412E"))
                        .multilineTextAlignment(.leading)
                        .padding(16)
                        .background(Color(hex: "D0FBC3"), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // Terms & Privacy links at the very bottom
                    HStack(spacing: 24) {
                        Button(action: {
                            if let url = URL(string: "https://docs.qq.com/doc/p/e3df6a83dbc7dc08ef8a5ee99267cee9f0588550") {
                                UIApplication.shared.open(url)
                            }
                            print("[PaywallView] Terms of Use tapped")
                        }) {
                            Text("Terms of Use")
                                .font(AppTheme.font(size: 13))
                                .foregroundStyle(.white)
                                .underline()
                        }
                        .buttonStyle(ClickSoundButtonStyle())

                        Button(action: {
                            if let url = URL(string: "https://docs.qq.com/doc/p/6902accfcd5d641bad0a6169342c88ecb6666aad") {
                                UIApplication.shared.open(url)
                            }
                            print("[PaywallView] Privacy Policy tapped")
                        }) {
                            Text("Privacy Policy")
                                .font(AppTheme.font(size: 13))
                                .foregroundStyle(.white)
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
        .alert("Restore Purchases", isPresented: $showRestoreAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(restoreAlertMessage)
        }
        .onDisappear {
            // 离开 Paywall 时停止 OB 背景音乐
            BackgroundMusicManager.shared.stop()
            print("[PaywallView] 停止 OB 背景音乐")
        }
    }

    @ViewBuilder
    private func planCard(plan: Plan, title: String, price: String, period: String, badge: String?) -> some View {
        let isSelected = selectedPlan == plan
        let bonusCoins = plan == .yearly ? 200 : 50
        
        Button(action: {
            selectedPlan = plan
        }) {
            VStack(spacing: 0) {
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
                
                // 小鱼干奖励横幅
                HStack(spacing: 6) {
                    Image("fish coin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    
                    Text("Get \(bonusCoins) bonus fish coins!")
                        .font(AppTheme.fontBold(size: 13))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "FFB84D"), Color(hex: "FF9A8B")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
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
