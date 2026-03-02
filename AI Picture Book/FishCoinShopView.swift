//
//  FishCoinShopView.swift
//  AI Picture Book
//
//  小鱼干商店：购买小鱼干
//

import SwiftUI
import StoreKit

struct FishCoinShopView: View {
    @Environment(\.dismiss) private var dismiss
    private let purchaseManager = PurchaseManager.shared
    
    // 小鱼干商品配置
    private let coinProducts: [(productID: PurchaseManager.ProductID, coins: Int, price: String)] = [
        (.coins1, 5, "$0.99"),
        (.coins2, 18, "$2.99"),
        (.coins3, 50, "$6.99"),
        (.coins4, 120, "$14.99")
    ]
    
    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                colors: [
                    Color(hex: "FFF8F0"),
                    Color(hex: "FFF0E6"),
                    Color(hex: "FFE8DC")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部栏
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(AppTheme.font(size: 16))
                            Text("Back")
                                .font(AppTheme.fontBold(size: 16))
                        }
                        .foregroundStyle(Color(hex: "FF6A88"))
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(AppTheme.font(size: 28))
                            .foregroundStyle(Color(hex: "8B7355"))
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // 标题区域
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "FFB84D"), Color(hex: "FF9A8B")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                
                                Image("fish coin")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                            }
                            .shadow(color: Color(hex: "FFB84D").opacity(0.3), radius: 12, x: 0, y: 6)
                            
                            Text("Fish Coin Shop")
                                .font(AppTheme.fontBold(size: 28))
                                .foregroundStyle(Color(hex: "5D4E37"))
                            
                            Text("Get more fish coins to create stories")
                                .font(AppTheme.font(size: 15))
                                .foregroundStyle(Color(hex: "8B7355"))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // 商品列表
                        VStack(spacing: 12) {
                            ForEach(Array(coinProducts.enumerated()), id: \.offset) { index, product in
                                CoinProductCard(
                                    productID: product.productID,
                                    coins: product.coins,
                                    defaultPrice: product.price,
                                    isPopular: index == 1 // 第2个商品（$2.99）标记为热门
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // 底部说明
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(AppTheme.font(size: 16))
                                    .foregroundStyle(Color(hex: "FF6A88"))
                                Text("Why Fish Coins?")
                                    .font(AppTheme.fontBold(size: 16))
                                    .foregroundStyle(Color(hex: "5D4E37"))
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                InfoRow(icon: "book.fill", text: "Each story costs 10 fish coins")
                                InfoRow(icon: "gift.fill", text: "Get 1 free coin daily")
                                InfoRow(icon: "sparkles", text: "Premium subscribers get bonus coins")
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.6))
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Restore purchases
                        Button(action: {
                            print("[FishCoinShopView] Restore purchases")
                            Task {
                                await purchaseManager.restorePurchases()
                            }
                        }) {
                            Text("Restore Purchases")
                                .font(AppTheme.font(size: 14))
                                .foregroundStyle(Color(hex: "A0826D"))
                                .underline()
                        }
                        .buttonStyle(ClickSoundButtonStyle())
                        .padding(.top, 8)
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
    let isPopular: Bool
    
    @Environment(\.dismiss) private var dismiss
    private let purchaseManager = PurchaseManager.shared
    @State private var isPurchasing = false
    
    private var product: Product? {
        purchaseManager.product(for: productID)
    }
    
    private var displayPrice: String {
        product?.displayPrice ?? defaultPrice
    }
    
    var body: some View {
        Button(action: {
            guard !isPurchasing else { return }
            Task {
                await purchaseProduct()
            }
        }) {
            ZStack(alignment: .topTrailing) {
                HStack(spacing: 16) {
                    // 左侧：小鱼干图标和数量
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FFB84D").opacity(0.3), Color(hex: "FF9A8B").opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                            
                            Image("fish coin")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 35, height: 35)
                        }
                        
                        Text("x\(coins)")
                            .font(AppTheme.fontBold(size: 20))
                            .foregroundStyle(Color(hex: "5D4E37"))
                        
                        Text("coins")
                            .font(AppTheme.font(size: 12))
                            .foregroundStyle(Color(hex: "A0826D"))
                    }
                    .frame(width: 80)
                    
                    Spacer()
                    
                    // 右侧：价格和购买按钮
                    VStack(spacing: 8) {
                        if isPurchasing {
                            ProgressView()
                                .tint(Color(hex: "FF6A88"))
                        } else {
                            Text(displayPrice)
                                .font(AppTheme.fontBold(size: 24))
                                .foregroundStyle(Color(hex: "5D4E37"))
                            
                            Text("Buy Now")
                                .font(AppTheme.fontBold(size: 14))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "FF9A8B"), Color(hex: "FF6A88")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                    }
                    .frame(width: 100)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                        .shadow(color: Color(hex: "D4A574").opacity(0.15), radius: 8, x: 0, y: 3)
                )
                
                // 热门标签
                if isPopular {
                    Text("POPULAR")
                        .font(AppTheme.fontBold(size: 11))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "FF6A88"))
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
            return
        }
        
        isPurchasing = true
        let success = await purchaseManager.purchase(product)
        isPurchasing = false
        
        if success {
            print("[CoinProductCard] 购买成功，赠送 \(coins) 小鱼干")
            FishCoinManager.shared.addCoins(coins)
            
            // 购买成功后关闭页面，返回首页
            await MainActor.run {
                dismiss()
            }
        } else {
            print("[CoinProductCard] 购买失败或取消")
        }
    }
}

// MARK: - 信息行

private struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(AppTheme.font(size: 14))
                .foregroundStyle(Color(hex: "FF6A88"))
                .frame(width: 20)
            
            Text(text)
                .font(AppTheme.font(size: 13))
                .foregroundStyle(Color(hex: "8B7355"))
            
            Spacer()
        }
    }
}

#Preview {
    FishCoinShopView()
}

