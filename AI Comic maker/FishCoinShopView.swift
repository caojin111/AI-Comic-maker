//
//  FishCoinShopView.swift
//  AI Comic maker
//

import SwiftUI
import StoreKit
import Mixpanel

struct FishCoinShopView: View {
    @Environment(\.dismiss) private var dismiss
    private let purchaseManager = PurchaseManager.shared

    private let coinProducts: [(productID: PurchaseManager.ProductID, coins: Int, price: String, label: String)] = [
        (.coins1, 30,   "$0.99",  "Starter Pack"),
        (.coins2, 120,  "$2.99",  "hot"),
        (.coins3, 350,  "$6.99",  "Value Bucket"),
        (.coins4, 1000, "$14.99", "Ultimate Chest")
    ]

    var body: some View {
        ZStack {
            // 背景
            Color(hex: "0A0E1A").ignoresSafeArea()

            // 背景装饰圆圈
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(Color(hex: "FF1493").opacity(0.06))
                        .frame(width: 320, height: 320)
                        .offset(x: geo.size.width - 100, y: -60)
                    Circle()
                        .fill(Color(hex: "00D9FF").opacity(0.05))
                        .frame(width: 250, height: 250)
                        .offset(x: -80, y: geo.size.height - 200)
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── 顶部栏 ──
                HStack {
                    Button(action: { dismiss() }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "1A1F2E"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: "FF1493"), lineWidth: 1)
                                )
                                .frame(width: 40, height: 40)
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "FF1493"))
                        }
                    }
                    .buttonStyle(ClickSoundButtonStyle())

                    Spacer()

                    Text("Fish Coin Shop")
                        .font(AppTheme.fontRowdiesBold(size: 20))
                        .foregroundStyle(Color.white)

                    Spacer()

                    // 占位保持标题居中
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // ── Hero 区域 ──
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FF1493"), Color(hex: "FF69B4"), Color(hex: "FF1493")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.black, lineWidth: 3)
                                )

                            GeometryReader { geo in
                                ZStack {
                                    Circle().fill(Color.white.opacity(0.08)).frame(width: 100, height: 100)
                                        .offset(x: geo.size.width - 40, y: -30)
                                    Circle().fill(Color(hex: "00D9FF").opacity(0.12)).frame(width: 70, height: 70)
                                        .offset(x: -20, y: geo.size.height - 20)
                                }
                            }

                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 64, height: 64)
                                    Image("fish coin")
                                        .resizable().scaledToFit()
                                        .frame(width: 40, height: 40)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Power Up!")
                                        .font(AppTheme.fontRowdiesBold(size: 20))
                                        .foregroundStyle(.white)
                                    Text("Get fish coins to create more stories")
                                        .font(AppTheme.font(size: 12))
                                        .foregroundStyle(.white.opacity(0.85))
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                        }
                        .frame(height: 110)
                        .shadow(color: Color(hex: "FF1493").opacity(0.5), radius: 20, x: 0, y: 10)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // ── 商品列表 ──
                        VStack(spacing: 12) {
                            ForEach(Array(coinProducts.enumerated()), id: \.offset) { index, product in
                                CoinProductCard(
                                    productID: product.productID,
                                    coins: product.coins,
                                    defaultPrice: product.price,
                                    label: product.label,
                                    isPopular: index == 1
                                )
                            }
                        }
                        .padding(.horizontal, 20)

                        // ── 说明区域 ──
                        VStack(spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(AppTheme.font(size: 15))
                                    .foregroundStyle(Color(hex: "00D9FF"))
                                Text("How it works")
                                    .font(AppTheme.fontBold(size: 15))
                                    .foregroundStyle(Color.white)
                                Spacer()
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                ShopInfoRow(icon: "book.fill",    text: "Each generated image costs 10 fish coins", color: "FF1493")
                                ShopInfoRow(icon: "gift.fill",    text: "Get free coins every day",     color: "FF69B4")
                                ShopInfoRow(icon: "sparkles",     text: "Premium gets bonus coins",       color: "00D9FF")
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(hex: "1A1F2E"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color(hex: "00D9FF").opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)

                        // Restore purchases
                        Button(action: {
                            AnalyticsManager.track(AnalyticsEvent.restorePurchasesTapped, properties: ["entry": "coin_shop"])
                            Task { await purchaseManager.restorePurchases() }
                        }) {
                            Text("Restore Purchases")
                                .font(AppTheme.font(size: 13))
                                .foregroundStyle(Color(hex: "606070"))
                                .underline()
                        }
                        .buttonStyle(ClickSoundButtonStyle())
                        .padding(.top, 4)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .task {
            await purchaseManager.loadProductsIfNeeded()
        }
    }
}

// MARK: - 商品卡片

private struct CoinProductCard: View {
    let productID: PurchaseManager.ProductID
    let coins: Int
    let defaultPrice: String
    let label: String
    let isPopular: Bool

    @Environment(\.dismiss) private var dismiss
    private let purchaseManager = PurchaseManager.shared
    @State private var isPurchasing = false

    private var product: Product? { purchaseManager.product(for: productID) }
    private var displayPrice: String { product?.displayPrice ?? defaultPrice }

    var body: some View {
        Button(action: {
            guard !isPurchasing else { return }
            Task { await purchaseProduct() }
        }) {
            ZStack(alignment: .topTrailing) {
                HStack(spacing: 14) {
                    // 左：图标 + 数量
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FF1493").opacity(0.2), Color(hex: "FF69B4").opacity(0.1)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                            Image("fish coin")
                                .resizable().scaledToFit()
                                .frame(width: 32, height: 32)
                        }

                        Text("x\(coins)")
                            .font(AppTheme.fontBold(size: 18))
                            .foregroundStyle(Color.white)

                        Text("coins")
                            .font(AppTheme.font(size: 11))
                            .foregroundStyle(Color(hex: "B0B0B0"))
                    }
                    .frame(width: 76)

                    // 分割线
                    Rectangle()
                        .fill(Color(hex: "FF1493").opacity(0.2))
                        .frame(width: 1, height: 60)

                    Spacer()

                    // 右：价格 + 按钮
                    VStack(spacing: 6) {
                        if isPurchasing {
                            ProgressView().tint(Color(hex: "FF1493"))
                        } else {
                            Text(displayPrice)
                                .font(AppTheme.fontBold(size: 22))
                                .foregroundStyle(Color.white)

                            Text("Buy Now")
                                .font(AppTheme.fontBold(size: 13))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "FF1493"), Color(hex: "FF69B4")],
                                                startPoint: .leading, endPoint: .trailing
                                            )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.black, lineWidth: 1.5)
                                        )
                                )
                        }
                    }
                    .frame(width: 110)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "1A1F2E"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.black, lineWidth: 2.5)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    isPopular ? Color(hex: "FF1493") : Color(hex: "FF1493").opacity(0.2),
                                    lineWidth: isPopular ? 1.5 : 1
                                )
                        )
                )
                .shadow(
                    color: isPopular ? Color(hex: "FF1493").opacity(0.3) : Color.black.opacity(0.2),
                    radius: isPopular ? 16 : 6, x: 0, y: isPopular ? 8 : 3
                )

                // 标签
                if isPopular {
                    Text(label.uppercased())
                        .font(AppTheme.fontBold(size: 10))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FF1493"), Color(hex: "FF69B4")],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.black, lineWidth: 1.5)
                                )
                        )
                        .offset(x: -8, y: -8)
                }
            }
        }
        .buttonStyle(ClickSoundButtonStyle())
        .disabled(isPurchasing)
    }

    private func purchaseProduct() async {
        guard let product = product else {
            print("[CoinProductCard] 未找到商品：\(productID)")
            AnalyticsManager.track(AnalyticsEvent.fishCoinPurchaseFailed, properties: ["product_id": productID.rawValue, "reason": "product_not_found"])
            return
        }
        AnalyticsManager.track(
            AnalyticsEvent.fishCoinPurchaseStarted,
            properties: [
                "product_id": product.id,
                "coins": coins,
                "price": product.displayPrice,
                "label": label
            ]
        )
        isPurchasing = true
        let success = await purchaseManager.purchase(product)
        isPurchasing = false
        if success {
            FishCoinManager.shared.addCoins(coins)
            AnalyticsManager.track(
                AnalyticsEvent.fishCoinPurchaseSucceeded,
                properties: [
                    "product_id": product.id,
                    "coins": coins,
                    "price": product.displayPrice,
                    "label": label
                ]
            )
            await MainActor.run { dismiss() }
        } else {
            AnalyticsManager.track(
                AnalyticsEvent.fishCoinPurchaseFailed,
                properties: [
                    "product_id": product.id,
                    "coins": coins,
                    "price": product.displayPrice,
                    "label": label,
                    "reason": "purchase_not_completed"
                ]
            )
        }
    }
}

// MARK: - 信息行

private struct ShopInfoRow: View {
    let icon: String
    let text: String
    let color: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(AppTheme.font(size: 13))
                .foregroundStyle(Color(hex: color))
                .frame(width: 18)
            Text(text)
                .font(AppTheme.font(size: 13))
                .foregroundStyle(Color(hex: "B0B0B0"))
            Spacer()
        }
    }
}

#Preview {
    FishCoinShopView()
}
