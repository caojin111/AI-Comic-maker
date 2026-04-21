//
//  PaywallView.swift
//  AI Comic maker
//
//  Subscription paywall: benefits, yearly/monthly plans, restore, subscribe button.
//

import SwiftUI
import StoreKit
import AVKit
import AVFoundation
import Lottie
import Mixpanel

private extension PurchaseManager.ProductID {
    var subscriptionTier: PurchaseManager.SubscriptionTier? {
        PurchaseManager.SubscriptionTier(rawValue: rawValue)
    }
}

struct PaywallView: View {
    @Environment(AppState.self) private var appState
    private let purchaseManager = PurchaseManager.shared

    enum Plan: String, CaseIterable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        case yearly = "Yearly"
    }

    private let weeklyPrice = "$4.99"
    private let monthlyPrice = "$9.99"
    private let yearlyPrice = "$34.99"
    private let yearlySavePercent = "71"

    @State private var selectedPlan: Plan = .yearly
    @State private var showRestoreAlert = false
    @State private var restoreAlertMessage = ""
    @State private var showBatAnimation = false

    private var childNameForTitle: String {
        let name = appState.childName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "your child" : name
    }

    private var billingDescription: String {
        switch selectedPlan {
        case .yearly:
            return "$0.00 due today for 3 days, then \(yearlyDisplayPrice) billed every year"
        case .monthly:
            return "\(monthlyDisplayPrice) due today, then \(monthlyDisplayPrice) billed every month"
        case .weekly:
            return "\(weeklyDisplayPrice) due today, then \(weeklyDisplayPrice) billed every week"
        }
    }

    private let benefits: [(icon: String, text: String)] = [
        ("book.pages.fill", "Create personalized comics"),
        ("square.stack.3d.up.fill", "Unlimited comic storage"),
        ("person.crop.circle.badge.plus", "Create your own role with your photos"),
        ("sparkles", "Ad-free, pure enjoyment")
    ]

    private func productID(for plan: Plan) -> PurchaseManager.ProductID {
        switch plan {
        case .weekly: return .weekly
        case .yearly: return .yearly
        case .monthly: return .monthly
        }
    }

    private func product(for plan: Plan) -> Product? {
        purchaseManager.product(for: productID(for: plan))
    }

    private var weeklyDisplayPrice: String {
        if let p = product(for: .weekly) {
            print("[PaywallView] Weekly product found: \(p.id), price: \(p.displayPrice)")
            return p.displayPrice
        }
        print("[PaywallView] Weekly product NOT found, using fallback: \(weeklyPrice)")
        return weeklyPrice
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
            AnalyticsManager.track(
                AnalyticsEvent.subscriptionPurchaseFailed,
                properties: [
                    "plan": selectedPlan.rawValue,
                    "reason": "product_not_found"
                ]
            )
            print("[PaywallView] 未找到对应的 StoreKit 商品，请检查 App Store Connect 中的 product id")
            return
        }
        AnalyticsManager.track(
            AnalyticsEvent.subscriptionPurchaseStarted,
            properties: [
                "plan": selectedPlan.rawValue,
                "product_id": product.id,
                "price": product.displayPrice,
                "has_trial": selectedPlan != .weekly
            ]
        )
        let purchaseResult = await purchaseManager.purchase(product)
        let latestTier = purchaseManager.currentSubscriptionTier
        print("[PaywallView] 购买流程结束，result=\(String(describing: purchaseResult)), currentSubscriptionTier=\(String(describing: latestTier?.rawValue))")

        switch purchaseResult {
        case .purchased(_, let purchasedTier):
            if purchasedTier == productID(for: selectedPlan).subscriptionTier {
                print("[PaywallView] 本次点击已完成真实购买，显示 bat 动画")
                print("[PaywallView] 首购奖励将由购买结果或交易监听统一处理，避免重复发放")
                showBatAnimation = true
            } else {
                AnalyticsManager.track(
                    AnalyticsEvent.subscriptionPurchaseFailed,
                    properties: [
                        "plan": selectedPlan.rawValue,
                        "product_id": product.id,
                        "reason": "purchased_tier_mismatch"
                    ]
                )
                print("[PaywallView] 购买成功但订阅档位与当前选择不一致，不进入首页")
            }
        case .alreadyActive(let tier):
            print("[PaywallView] 当前订阅已有效，tier=\(tier.rawValue)，不触发购买成功动画")
        case .userCancelled:
            print("[PaywallView] 用户取消购买")
        case .pending:
            print("[PaywallView] 购买处于待处理状态")
        case .failed(let reason):
            AnalyticsManager.track(
                AnalyticsEvent.subscriptionPurchaseFailed,
                properties: [
                    "plan": selectedPlan.rawValue,
                    "product_id": product.id,
                    "reason": reason
                ]
            )
            print("[PaywallView] 购买失败，reason=\(reason)")
        }
    }

    private func restorePurchases() {
        print("[PaywallView] Restore purchases")
        AnalyticsManager.track(AnalyticsEvent.restorePurchasesTapped, properties: ["entry": "paywall"])
        Task {
            let restoredTier = await purchaseManager.restorePurchases()
            print("[PaywallView] 恢复购买完成，tier: \(restoredTier?.rawValue ?? "none")")
            if restoredTier != nil {
                appState.dismissPaywall()
            } else {
                restoreAlertMessage = "No active subscription was found for this Apple ID."
                showRestoreAlert = true
            }
        }
    }

    var body: some View {
        ZStack {
            PaywallVideoBackground()
                .ignoresSafeArea()

            Rectangle()
                .fill(Color.black.opacity(0.55))
                .background(.ultraThinMaterial.opacity(0.5))
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    Spacer().frame(height: 4)

                    Text("Ready to begin your adventure with comic?")
                        .font(AppTheme.font(size: 26))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 6)

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(benefits.enumerated()), id: \.offset) { _, item in
                            HStack(spacing: 10) {
                                Image(systemName: item.icon)
                                    .font(AppTheme.font(size: 18))
                                    .foregroundStyle(AppTheme.primary)
                                    .frame(width: 24, alignment: .center)
                                Text(item.text)
                                    .font(AppTheme.font(size: 14))
                                    .foregroundStyle(Color(hex: "03412E"))
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color(hex: "D0FBC3"), in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 2)

                    VStack(spacing: 8) {
                        planCard(
                            plan: .yearly,
                            title: "Yearly",
                            price: yearlyDisplayPrice,
                            period: "3-day free trial",
                            badge: "Save \(yearlySavePercent)%"
                        )
                        planCard(
                            plan: .monthly,
                            title: "Monthly",
                            price: monthlyDisplayPrice,
                            period: "3-day free trial",
                            badge: nil
                        )
                        planCard(
                            plan: .weekly,
                            title: "Weekly",
                            price: weeklyDisplayPrice,
                            period: "No free trial",
                            badge: nil
                        )
                    }
                    .padding(.horizontal, 24)

                    Text(billingDescription)
                        .font(AppTheme.font(size: 13))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 2)

                    Button(action: {
                        print("[PaywallView] Subscribe tapped, plan: \(selectedPlan.rawValue)")
                        Task {
                            await purchaseSelectedPlan()
                        }
                    }) {
                        Text(selectedPlan == .weekly ? "Subscribe now" : "Start your free trial")
                            .font(AppTheme.font(size: 18))
                            .foregroundStyle(AppTheme.textOnLight)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.top, 2)

                    Button(action: {
                        restorePurchases()
                    }) {
                        Text("Restore purchases")
                            .font(AppTheme.font(size: 14))
                            .foregroundStyle(.white)
                            .underline()
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                    .padding(.top, 6)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("How your free trial works")
                            .font(AppTheme.fontBold(size: 18))
                            .foregroundStyle(.white)
                        VStack(spacing: 16) {
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
                                    Text("Day 2")
                                        .font(AppTheme.fontBold(size: 15))
                                        .foregroundStyle(Color(hex: "03412E"))
                                    Text("We'll remind you that your trial is ending soon.")
                                        .font(AppTheme.font(size: 13))
                                        .foregroundStyle(Color(hex: "03412E"))
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Day 3")
                                        .font(AppTheme.fontBold(size: 15))
                                        .foregroundStyle(Color(hex: "03412E"))
                                    Text("Your subscription starts.\nCancel any time before renewal.")
                                        .font(AppTheme.font(size: 13))
                                        .foregroundStyle(Color(hex: "03412E"))
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(hex: "D0FBC3"), in: RoundedRectangle(cornerRadius: 16))

                        Text("How can I cancel?")
                            .font(AppTheme.fontBold(size: 18))
                            .foregroundStyle(.white)
                            .padding(.top, 8)
                        Text("""
It's easy: Go to your iPhone Settings, tap your Apple ID at the top, select "Subscriptions," find AI Comic maker, and tap "Cancel Subscription." You can cancel anytime before the trial ends.
""")
                            .font(AppTheme.font(size: 13))
                            .foregroundStyle(Color(hex: "03412E"))
                            .multilineTextAlignment(.leading)
                            .padding(16)
                            .background(Color(hex: "D0FBC3"), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

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
                    print("[PaywallView] 加载商品...")
                    await purchaseManager.loadProductsIfNeeded()
                    print("[PaywallView] 商品加载完成")
                }
            }
        }
        .alert("Restore Purchases", isPresented: $showRestoreAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(restoreAlertMessage)
        }
        .overlay {
            if showBatAnimation {
                ZStack {
                    Color.black.opacity(0.9)
                        .ignoresSafeArea()

                    LottieView(
                        animationName: "bat",
                        subdirectory: "lottie",
                        loopMode: .playOnce,
                        contentMode: .scaleAspectFill,
                        onComplete: {
                            print("[PaywallView] bat 动画播放完成，跳转到首页")
                            appState.dismissPaywall()
                        }
                    )
                    .ignoresSafeArea()
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            AnalyticsManager.track(AnalyticsEvent.paywallViewed)
            BackgroundMusicManager.shared.playMusic(
                fileName: "mixkit-island-beat-250",
                ext: "mp3",
                subdirectory: "music",
                volume: 0.25,
                loops: true,
                restartIfSameTrack: false
            )
            print("[PaywallView] 保持或开始播放 Paywall 背景音乐")
        }
        .onDisappear {
            print("[PaywallView] 离开 Paywall，不中断当前背景音乐")
        }
    }

    private func planCard(plan: Plan, title: String, price: String, period: String, badge: String?) -> some View {
        let isSelected = selectedPlan == plan
        let bonusCoins: Int
        let dailyCoins: Int
        switch plan {
        case .weekly:
            bonusCoins = 150
            dailyCoins = 5
        case .monthly:
            bonusCoins = 500
            dailyCoins = 10
        case .yearly:
            bonusCoins = 2000
            dailyCoins = 20
        }

        return Button(action: {
            selectedPlan = plan
        }) {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text(title)
                                .font(AppTheme.font(size: 17))
                                .foregroundStyle(AppTheme.textOnLight)
                            if let badge = badge {
                                Text(badge)
                                    .font(AppTheme.font(size: 11))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.green, in: RoundedRectangle(cornerRadius: 6))
                            }
                        }
                        Text(period)
                            .font(AppTheme.font(size: 12))
                            .foregroundStyle(Color.gray)
                    }
                    Spacer()
                    Text(price)
                        .font(AppTheme.font(size: 17))
                        .foregroundStyle(AppTheme.primary)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)

                // 小鱼干奖励横幅
                HStack(spacing: 8) {
                    Image("fish coin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)

                    Text("Get \(bonusCoins) bonus fish coins")
                        .font(AppTheme.fontBold(size: 12))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Text("Daily +\(dailyCoins)")
                        .font(AppTheme.fontBold(size: 11))
                        .foregroundStyle(Color(hex: "5D3A00"))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.85), in: Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
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

// MARK: - 视频背景组件

private struct PaywallVideoBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        guard let url = Bundle.main.url(forResource: "paywall_video", withExtension: "mp4")
            ?? Bundle.main.url(forResource: "paywall_video", withExtension: "mp4", subdirectory: "videos")
        else {
            print("[PaywallVideoBackground] 未找到 paywall_video.mp4")
            return view
        }
        let player = AVPlayer(url: url)
        player.isMuted = true
        player.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(playerLayer)
        player.play()
        context.coordinator.player = player
        context.coordinator.playerLayer = playerLayer
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.playerLayer?.frame = uiView.bounds
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject {
        var player: AVPlayer?
        var playerLayer: AVPlayerLayer?
    }
}

#Preview {
    PaywallView()
        .environment(AppState.shared)
}
