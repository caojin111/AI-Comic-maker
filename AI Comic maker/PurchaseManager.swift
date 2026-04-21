//
//  PurchaseManager.swift
//  AI Comic maker
//
//  StoreKit 2 订阅管理：拉取商品信息、购买与恢复
//

import Foundation
import StoreKit
import Mixpanel

@MainActor
final class PurchaseManager {
    static let shared = PurchaseManager()

    enum SubscriptionTier: String {
        case weekly = "Comic_weekly"
        case monthly = "Comic_monthly"
        case yearly = "Comic_yearly"
    }

    private let subscriptionTierKey = "activeSubscriptionTier"
    private let rewardedSubscriptionTransactionIDsKey = "rewardedSubscriptionTransactionIDs"
    private let rewardedInitialSubscriptionTransactionIDsKey = "rewardedInitialSubscriptionTransactionIDs"
    private let trialConsumedSubscriptionOriginalIDsKey = "trialConsumedSubscriptionOriginalIDs"
    private let activeTrialSubscriptionTierKey = "activeTrialSubscriptionTier"
    private let pendingTrialRewardTransactionIDKey = "pendingTrialRewardTransactionID"

    /// ASC 中配置的商品 ID
    enum ProductID: String, CaseIterable {
        case weekly = "Comic_weekly"
        case monthly = "Comic_monthly"
        case yearly = "Comic_yearly"
        case coins1 = "comic_fish_0.99"
        case coins2 = "comic_fish_2.99"
        case coins3 = "comic_fish_6.99"
        case coins4 = "comic_fish_14.99"
    }

    enum PurchaseResult {
        case purchased(transactionID: UInt64, tier: SubscriptionTier)
        case alreadyActive(tier: SubscriptionTier)
        case userCancelled
        case pending
        case failed(reason: String)
    }


    private init() {
        Task {
            await loadProductsIfNeeded()
            await refreshSubscriptionTier()
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
                print("[PurchaseManager] 收到已验证的交易更新: \(transaction.productID), id: \(transaction.id), originalID: \(transaction.originalID)")
                processSubscriptionRewardIfNeeded(for: transaction, source: "Transaction.updates")
                if let tier = SubscriptionTier(rawValue: transaction.productID) {
                    AnalyticsManager.track(
                        AnalyticsEvent.subscriptionPurchaseSucceeded,
                        properties: [
                            "plan": tier.rawValue,
                            "product_id": transaction.productID,
                            "transaction_id": String(transaction.id),
                            "source": "transaction_updates"
                        ]
                    )
                    updateCurrentSubscriptionTier(tier)
                }
                await transaction.finish()
                print("[PurchaseManager] 已完成交易 finish: \(transaction.id)")
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
            print("[PurchaseManager] 🔍 开始请求商品信息...")
            print("[PurchaseManager] 📦 请求的 Product IDs: \(ids)")
            print("[PurchaseManager] 📱 Bundle ID: \(Bundle.main.bundleIdentifier ?? "未知")")
            
            products = try await Product.products(for: ids)
            
            print("[PurchaseManager] ✅ 已加载 \(products.count) 个商品:")
            for product in products {
                print("[PurchaseManager]   - ID: \(product.id)")
                print("[PurchaseManager]     价格: \(product.displayPrice)")
                print("[PurchaseManager]     类型: \(product.type)")
            }
            
            if products.isEmpty {
                print("[PurchaseManager] ⚠️ 警告：未加载到任何商品！")
                print("[PurchaseManager] 📋 排查清单：")
                print("[PurchaseManager]   1. App Store Connect 中 Bundle ID 是否为: \(Bundle.main.bundleIdentifier ?? "未知")")
                print("[PurchaseManager]   2. 商品状态是否为「准备提交」（不能是草稿）")
                print("[PurchaseManager]   3. 付费 App 协议是否已签署")
                print("[PurchaseManager]   4. Xcode Scheme → StoreKit Configuration 是否设置为 None")
                print("[PurchaseManager]   5. 设备是否登录沙盒账号（设置 → App Store → 沙盒账户）")
                print("[PurchaseManager]   6. 是否在真机上测试（模拟器不支持沙盒支付）")
            }
        } catch {
            print("[PurchaseManager] ❌ 加载商品失败，错误详情: \(error)")
            print("[PurchaseManager] 错误类型: \(type(of: error))")
            if let storeError = error as? StoreKitError {
                print("[PurchaseManager] StoreKit 错误: \(storeError)")
            }
        }
    }

    /// 当前有效订阅档位
    var currentSubscriptionTier: SubscriptionTier? {
        guard let rawValue = UserDefaults.standard.string(forKey: subscriptionTierKey) else {
            return nil
        }
        return SubscriptionTier(rawValue: rawValue)
    }

    var activeTrialSubscriptionTier: SubscriptionTier? {
        guard let rawValue = UserDefaults.standard.string(forKey: activeTrialSubscriptionTierKey) else {
            return nil
        }
        return SubscriptionTier(rawValue: rawValue)
    }

    var shouldShowTrialRewardBanner: Bool {
        guard let activeTrialSubscriptionTier else {
            print("[PurchaseManager] Trial reminder hidden: no active trial tier")
            return false
        }
        guard currentSubscriptionTier == activeTrialSubscriptionTier else {
            print("[PurchaseManager] Trial reminder hidden: current tier mismatch, current=\(currentSubscriptionTier?.rawValue ?? "nil"), trial=\(activeTrialSubscriptionTier.rawValue)")
            return false
        }
        let shouldShow = activeTrialSubscriptionTier == .monthly || activeTrialSubscriptionTier == .yearly
        print("[PurchaseManager] Trial reminder visibility=\(shouldShow), tier=\(activeTrialSubscriptionTier.rawValue)")
        return shouldShow
    }

    var debugTrialStatusSummary: String {
        let activeTrial = activeTrialSubscriptionTier?.rawValue ?? "nil"
        let currentTier = currentSubscriptionTier?.rawValue ?? "nil"
        let pendingTrialTransactionID = UserDefaults.standard.string(forKey: pendingTrialRewardTransactionIDKey) ?? "nil"
        let consumedTrialOriginalIDs = UserDefaults.standard.stringArray(forKey: trialConsumedSubscriptionOriginalIDsKey) ?? []
        let rewardedInitialIDs = UserDefaults.standard.stringArray(forKey: rewardedInitialSubscriptionTransactionIDsKey) ?? []
        let rewardedRenewalIDs = UserDefaults.standard.stringArray(forKey: rewardedSubscriptionTransactionIDsKey) ?? []
        let isTrialState = shouldShowTrialRewardBanner
        return "isTrial=\(isTrialState), currentTier=\(currentTier), activeTrialTier=\(activeTrial), pendingTrialTransactionID=\(pendingTrialTransactionID), consumedTrialOriginalIDs=\(consumedTrialOriginalIDs), rewardedInitialIDs=\(rewardedInitialIDs), rewardedRenewalIDs=\(rewardedRenewalIDs)"
    }

    private func updateActiveTrialSubscriptionTier(_ tier: SubscriptionTier?) {
        if let tier {
            UserDefaults.standard.set(tier.rawValue, forKey: activeTrialSubscriptionTierKey)
            print("[PurchaseManager] 已更新试用期订阅档位: \(tier.rawValue)")
        } else {
            UserDefaults.standard.removeObject(forKey: activeTrialSubscriptionTierKey)
            UserDefaults.standard.removeObject(forKey: pendingTrialRewardTransactionIDKey)
            print("[PurchaseManager] 已清除试用期订阅档位")
        }
    }

    private func updateCurrentSubscriptionTier(_ tier: SubscriptionTier?) {
        if let tier {
            UserDefaults.standard.set(tier.rawValue, forKey: subscriptionTierKey)
            print("[PurchaseManager] 已更新当前订阅档位: \(tier.rawValue)")
        } else {
            UserDefaults.standard.removeObject(forKey: subscriptionTierKey)
            print("[PurchaseManager] 已清除当前订阅档位")
        }
    }

    private func rewardedTransactionIDs(for key: String) -> Set<String> {
        let ids = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
        print("[PurchaseManager] 读取奖励记录 key=\(key)，数量: \(ids.count)")
        return ids
    }

    private func hasConsumedTrial(originalTransactionID: UInt64) -> Bool {
        let consumed = rewardedTransactionIDs(for: trialConsumedSubscriptionOriginalIDsKey).contains(String(originalTransactionID))
        print("[PurchaseManager] 检查试用资格是否已消费: originalID=\(originalTransactionID), 结果: \(consumed)")
        return consumed
    }

    private func markTrialConsumed(originalTransactionID: UInt64) {
        markRewarded(transactionID: originalTransactionID, key: trialConsumedSubscriptionOriginalIDsKey, label: "试用资格")
        print("[PurchaseManager] 已标记试用资格已消费: originalID=\(originalTransactionID)")
    }

    private func markRewarded(transactionID: UInt64, key: String, label: String) {
        var ids = rewardedTransactionIDs(for: key)
        ids.insert(String(transactionID))
        let sortedIDs = ids.sorted()
        UserDefaults.standard.set(sortedIDs, forKey: key)
        print("[PurchaseManager] 已记录\(label)奖励交易: \(transactionID)，当前记录数: \(sortedIDs.count)")
    }

    private func hasRewarded(transactionID: UInt64, key: String, label: String) -> Bool {
        let rewarded = rewardedTransactionIDs(for: key).contains(String(transactionID))
        print("[PurchaseManager] 检查\(label)奖励是否已发放: \(transactionID)，结果: \(rewarded)")
        return rewarded
    }

    private func hasPendingTrialReward(transactionID: UInt64, tier: SubscriptionTier) -> Bool {
        let pendingTransactionID = UserDefaults.standard.string(forKey: pendingTrialRewardTransactionIDKey)
        let pendingTier = activeTrialSubscriptionTier
        let hasPending = pendingTransactionID == String(transactionID) && pendingTier == tier
        print("[PurchaseManager] 检查试用期待补发奖励: transactionID=\(transactionID), tier=\(tier.rawValue), 结果: \(hasPending)")
        return hasPending
    }

    private func markPendingTrialReward(transactionID: UInt64, tier: SubscriptionTier) {
        UserDefaults.standard.set(String(transactionID), forKey: pendingTrialRewardTransactionIDKey)
        updateActiveTrialSubscriptionTier(tier)
        print("[PurchaseManager] 已记录试用期待补发奖励: transactionID=\(transactionID), tier=\(tier.rawValue)")
    }

    private func clearPendingTrialReward() {
        updateActiveTrialSubscriptionTier(nil)
    }

    private func processSubscriptionRewardIfNeeded(for transaction: Transaction, source: String) {
        guard let tier = SubscriptionTier(rawValue: transaction.productID) else {
            print("[PurchaseManager] [\(source)] 交易 \(transaction.id) 不是订阅商品，无需发放订阅奖励")
            return
        }

        let isInitialPurchase = transaction.id == transaction.originalID
        let isTrialEligibleTier = tier == .monthly || tier == .yearly
        let trialAlreadyConsumed = hasConsumedTrial(originalTransactionID: transaction.originalID)
        let hasLegacyInitialRewardRecord = hasRewarded(transactionID: transaction.id, key: rewardedInitialSubscriptionTransactionIDsKey, label: "首购订阅")
        if hasLegacyInitialRewardRecord && isTrialEligibleTier && !trialAlreadyConsumed {
            markTrialConsumed(originalTransactionID: transaction.originalID)
            clearPendingTrialReward()
            print("[PurchaseManager] [\(source)] Detected legacy initial trial record, auto-marked trial as consumed, originalID=\(transaction.originalID)")
        }
        let effectiveTrialConsumed = hasConsumedTrial(originalTransactionID: transaction.originalID)
        print("[PurchaseManager] [\(source)] 准备处理订阅奖励，productID=\(transaction.productID), transactionID=\(transaction.id), originalID=\(transaction.originalID), isInitialPurchase=\(isInitialPurchase), trialAlreadyConsumed=\(effectiveTrialConsumed), hasLegacyInitialRewardRecord=\(hasLegacyInitialRewardRecord)")

        if isInitialPurchase {
            guard !hasLegacyInitialRewardRecord else {
                print("[PurchaseManager] [\(source)] 交易 \(transaction.id) 的首购奖励已发放，跳过重复发放")
                updateCurrentSubscriptionTier(tier)
                if !effectiveTrialConsumed {
                    updateActiveTrialSubscriptionTier(tier)
                } else {
                    clearPendingTrialReward()
                }
                return
            }

            let shouldUseTrialReward = isTrialEligibleTier && !effectiveTrialConsumed
            let initialRewardAmount = shouldUseTrialReward ? 100 : FishCoinManager.shared.fullSubscriptionRewardAmount(for: tier)
            FishCoinManager.shared.grantSubscriptionReward(for: tier, amount: initialRewardAmount, source: source, transactionID: transaction.id)
            markRewarded(transactionID: transaction.id, key: rewardedInitialSubscriptionTransactionIDsKey, label: "首购订阅")
            if shouldUseTrialReward {
                markPendingTrialReward(transactionID: transaction.id, tier: tier)
                markTrialConsumed(originalTransactionID: transaction.originalID)
            } else {
                clearPendingTrialReward()
            }
            updateCurrentSubscriptionTier(tier)
            print("[PurchaseManager] [\(source)] 已完成首购订阅奖励发放，transactionID=\(transaction.id), tier=\(tier.rawValue), reward=\(initialRewardAmount), usedTrialReward=\(shouldUseTrialReward)")
            return
        }

        guard !hasRewarded(transactionID: transaction.id, key: rewardedSubscriptionTransactionIDsKey, label: "续订订阅") else {
            print("[PurchaseManager] [\(source)] 交易 \(transaction.id) 已发放过续订奖励，跳过重复发放")
            updateCurrentSubscriptionTier(tier)
            return
        }

        if hasPendingTrialReward(transactionID: transaction.originalID, tier: tier) {
            let deferredRewardAmount = FishCoinManager.shared.deferredSubscriptionRewardAmount(for: tier)
            FishCoinManager.shared.grantSubscriptionReward(for: tier, amount: deferredRewardAmount, source: source, transactionID: transaction.id)
            clearPendingTrialReward()
            print("[PurchaseManager] [\(source)] 试用期结束，已补发剩余奖励，transactionID=\(transaction.id), originalID=\(transaction.originalID), reward=\(deferredRewardAmount)")
        } else {
            let rewardAmount = FishCoinManager.shared.fullSubscriptionRewardAmount(for: tier)
            FishCoinManager.shared.grantSubscriptionReward(for: tier, amount: rewardAmount, source: source, transactionID: transaction.id)
        }
        markRewarded(transactionID: transaction.id, key: rewardedSubscriptionTransactionIDsKey, label: "续订订阅")
        updateCurrentSubscriptionTier(tier)
        print("[PurchaseManager] [\(source)] 已完成续订奖励发放，transactionID=\(transaction.id), tier=\(tier.rawValue)")
    }

    @discardableResult
    func refreshSubscriptionTier() async -> SubscriptionTier? {
        do {
            var resolvedTier: SubscriptionTier?
            for await result in Transaction.currentEntitlements {
                guard case .verified(let transaction) = result else { continue }
                print("[PurchaseManager] currentEntitlements 命中有效交易: \(transaction.productID), id: \(transaction.id), originalID: \(transaction.originalID)")
                processSubscriptionRewardIfNeeded(for: transaction, source: "currentEntitlements")
                if let tier = SubscriptionTier(rawValue: transaction.productID) {
                    resolvedTier = preferredSubscriptionTier(between: resolvedTier, and: tier)
                }
            }
            if let resolvedTier {
                updateCurrentSubscriptionTier(resolvedTier)
                return resolvedTier
            }
        } catch {
            print("[PurchaseManager] 获取当前订阅档位失败: \(error)")
        }
        clearPendingTrialReward()
        updateCurrentSubscriptionTier(nil)
        print("[PurchaseManager] 未找到有效订阅，已清除试用提醒状态")
        return nil
    }

    private func preferredSubscriptionTier(between lhs: SubscriptionTier?, and rhs: SubscriptionTier) -> SubscriptionTier {
        guard let lhs else { return rhs }
        let priority: [SubscriptionTier: Int] = [
            .yearly: 3,
            .monthly: 2,
            .weekly: 1
        ]
        return (priority[rhs] ?? 0) >= (priority[lhs] ?? 0) ? rhs : lhs
    }

    func product(for id: ProductID) -> Product? {
        products.first(where: { $0.id == id.rawValue })
    }

    /// 购买指定商品，返回明确结果
    func purchase(_ product: Product) async -> PurchaseResult {
        isPurchasing = true
        defer { isPurchasing = false }

        let subscriptionTierBeforePurchase = currentSubscriptionTier
        print("[PurchaseManager] 准备发起购买，product=\(product.id), 当前缓存订阅档位=\(String(describing: subscriptionTierBeforePurchase?.rawValue))")

        if SubscriptionTier(rawValue: product.id) != nil {
            let refreshedTier = await refreshSubscriptionTier()
            let targetTier = SubscriptionTier(rawValue: product.id)
            print("[PurchaseManager] 购买前刷新订阅状态完成，最新有效订阅档位=\(String(describing: refreshedTier?.rawValue))，目标档位=\(String(describing: targetTier?.rawValue))")
            if let refreshedTier, refreshedTier == targetTier {
                print("[PurchaseManager] 检测到同档位订阅仍处于有效状态，直接返回 alreadyActive")
                AnalyticsManager.track(
                    AnalyticsEvent.subscriptionPurchaseFailed,
                    properties: [
                        "product_id": product.id,
                        "reason": "subscription_already_active"
                    ]
                )
                return .alreadyActive(tier: refreshedTier)
            }
        }

        do {
            print("[PurchaseManager] 开始购买: \(product.id)")
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verification.payloadValue
                print("[PurchaseManager] 购买成功，transaction id = \(transaction.id)")
                guard let tier = SubscriptionTier(rawValue: transaction.productID) else {
                    print("[PurchaseManager] 购买成功但无法识别订阅档位: \(transaction.productID)")
                    return .failed(reason: "unknown_subscription_tier")
                }
                AnalyticsManager.track(
                    AnalyticsEvent.subscriptionPurchaseSucceeded,
                    properties: [
                        "plan": tier.rawValue,
                        "product_id": transaction.productID,
                        "transaction_id": String(transaction.id),
                        "source": "purchase"
                    ]
                )
                processSubscriptionRewardIfNeeded(for: transaction, source: "purchase")
                updateCurrentSubscriptionTier(tier)
                await transaction.finish()
                print("[PurchaseManager] purchase 已完成交易 finish: \(transaction.id)")
                return .purchased(transactionID: transaction.id, tier: tier)
            case .userCancelled:
                print("[PurchaseManager] 用户取消购买")
                AnalyticsManager.track(AnalyticsEvent.subscriptionPurchaseFailed, properties: ["product_id": product.id, "reason": "user_cancelled"])
                return .userCancelled
            case .pending:
                print("[PurchaseManager] 购买挂起")
                AnalyticsManager.track(AnalyticsEvent.subscriptionPurchaseFailed, properties: ["product_id": product.id, "reason": "pending"])
                return .pending
            @unknown default:
                print("[PurchaseManager] 未知购买结果")
                AnalyticsManager.track(AnalyticsEvent.subscriptionPurchaseFailed, properties: ["product_id": product.id, "reason": "unknown_result"])
                return .failed(reason: "unknown_result")
            }
        } catch {
            print("[PurchaseManager] 购买失败: \(error)")
            AnalyticsManager.track(AnalyticsEvent.subscriptionPurchaseFailed, properties: ["product_id": product.id, "reason": error.localizedDescription])
            return .failed(reason: error.localizedDescription)
        }
    }

    /// 恢复历史购买
    @discardableResult
    func restorePurchases() async -> SubscriptionTier? {
        print("[PurchaseManager] 开始恢复购买")
        AnalyticsManager.track(AnalyticsEvent.restorePurchasesTapped)
        do {
            print("[PurchaseManager] 调用 AppStore.sync 开始同步购买记录")
            try await AppStore.sync()
            print("[PurchaseManager] AppStore.sync 完成")

            for await result in Transaction.currentEntitlements {
                guard case .verified(let transaction) = result else { continue }
                print("[PurchaseManager] 已拥有 entitlement: \(transaction.productID), id: \(transaction.id), originalID: \(transaction.originalID)")
                processSubscriptionRewardIfNeeded(for: transaction, source: "restorePurchases")
            }
            let tier = await refreshSubscriptionTier()
            AnalyticsManager.track(
                AnalyticsEvent.restorePurchasesSucceeded,
                properties: [
                    "has_active_subscription": tier != nil,
                    "tier": tier?.rawValue ?? "none"
                ]
            )
            return tier
        } catch {
            print("[PurchaseManager] 恢复购买失败: \(error)")
            AnalyticsManager.track(AnalyticsEvent.restorePurchasesFailed, properties: ["reason": error.localizedDescription])
            return nil
        }
    }
    
    /// 检查用户是否有有效订阅
    func hasActiveSubscription() async -> Bool {
        print("[PurchaseManager] 检查订阅状态...")
        let tier = await refreshSubscriptionTier()
        if let tier {
            print("[PurchaseManager] ✅ 找到有效订阅: \(tier.rawValue)")
            return true
        }
        print("[PurchaseManager] ❌ 未找到有效订阅")
        return false
    }
}

