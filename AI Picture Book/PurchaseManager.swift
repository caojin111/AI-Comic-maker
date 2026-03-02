//
//  PurchaseManager.swift
//  AI Picture Book
//
//  StoreKit 2 订阅管理：拉取商品信息、购买与恢复
//

import Foundation
import StoreKit

@MainActor
final class PurchaseManager {
    static let shared = PurchaseManager()

    /// ASC 中配置的商品 ID
    enum ProductID: String, CaseIterable {
        case monthly = "monthlyplan_14.99"
        case yearly = "yearlyplan_29.99"
        case coins1 = "coins_1"
        case coins2 = "coins_2"
        case coins3 = "coins_3"
        case coins4 = "coins_4"
    }

    var products: [Product] = []
    var isPurchasing: Bool = false
    private var transactionUpdateTask: Task<Void, Never>?

    private init() {
        Task {
            await loadProductsIfNeeded()
        }
        // 监听交易更新，避免错过成功的购买
        transactionUpdateTask = Task {
            await listenForTransactionUpdates()
        }
    }
    
    deinit {
        transactionUpdateTask?.cancel()
    }
    
    /// 监听交易更新
    private func listenForTransactionUpdates() async {
        print("[PurchaseManager] 开始监听交易更新")
        for await result in Transaction.updates {
            switch result {
            case .verified(let transaction):
                print("[PurchaseManager] 收到已验证的交易更新: \(transaction.productID), id: \(transaction.id)")
                await transaction.finish()
            case .unverified(let transaction, let error):
                print("[PurchaseManager] 收到未验证的交易: \(transaction.productID), 错误: \(error)")
            }
        }
    }

    /// 按需拉取商品，避免重复请求
    func loadProductsIfNeeded() async {
        guard products.isEmpty else {
            print("[PurchaseManager] 商品已加载，跳过重复请求。当前商品数量: \(products.count)")
            for product in products {
                print("[PurchaseManager] - \(product.id): \(product.displayPrice)")
            }
            return
        }
        do {
            let ids = Set(ProductID.allCases.map { $0.rawValue })
            print("[PurchaseManager] 请求商品信息: \(ids)")
            products = try await Product.products(for: ids)
            print("[PurchaseManager] ✅ 已加载 \(products.count) 个商品:")
            for product in products {
                print("[PurchaseManager]   - ID: \(product.id)")
                print("[PurchaseManager]     价格: \(product.displayPrice)")
                print("[PurchaseManager]     类型: \(product.type)")
            }
            if products.isEmpty {
                print("[PurchaseManager] ⚠️ 警告：未加载到任何商品！请检查：")
                print("[PurchaseManager]   1. Product ID 是否在 App Store Connect 中正确配置")
                print("[PurchaseManager]   2. 是否已在 Xcode 中配置 StoreKit Configuration File")
                print("[PurchaseManager]   3. 沙盒环境是否正确设置")
            }
        } catch {
            print("[PurchaseManager] ❌ 加载商品失败: \(error)")
        }
    }

    func product(for id: ProductID) -> Product? {
        products.first(where: { $0.id == id.rawValue })
    }

    /// 购买指定商品，成功返回 true
    func purchase(_ product: Product) async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            print("[PurchaseManager] 开始购买: \(product.id)")
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                // 简单处理：只要验证通过就视为成功，不做复杂权利校验
                let transaction = try verification.payloadValue
                print("[PurchaseManager] 购买成功，transaction id = \(transaction.id)")
                await transaction.finish()
                return true
            case .userCancelled:
                print("[PurchaseManager] 用户取消购买")
                return false
            case .pending:
                print("[PurchaseManager] 购买挂起")
                return false
            @unknown default:
                print("[PurchaseManager] 未知购买结果")
                return false
            }
        } catch {
            print("[PurchaseManager] 购买失败: \(error)")
            return false
        }
    }

    /// 恢复历史购买
    func restorePurchases() async {
        print("[PurchaseManager] 开始恢复购买")
        do {
            for await result in Transaction.currentEntitlements {
                guard case .verified(let transaction) = result else { continue }
                print("[PurchaseManager] 已拥有 entitlement: \(transaction.productID)")
            }
        } catch {
            print("[PurchaseManager] 恢复购买失败: \(error)")
        }
    }
}

