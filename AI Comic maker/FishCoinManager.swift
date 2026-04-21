//
//  FishCoinManager.swift
//  AI Comic maker
//
//  小鱼干货币系统管理器（使用 iCloud 同步）
//

import Foundation
import SwiftUI
import StoreKit

@Observable
final class FishCoinManager {
    static let shared = FishCoinManager()
    
    // iCloud KeyValue Store
    private let ubiquitousStore = NSUbiquitousKeyValueStore.default
    
    // 本地备份（当 iCloud 不可用时使用）
    private let localDefaults = UserDefaults.standard
    
    // Keys
    private let balanceKey = "fishCoinBalance"
    private let lastLoginDateKey = "lastLoginDate"
    
    // 检查 iCloud 是否可用
    private var isICloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }
    
    // 小鱼干余额（使用 iCloud 同步，降级到本地存储）
    var balance: Int {
        get {
            if isICloudAvailable {
                // 优先从 iCloud 读取
                let cloudBalance = ubiquitousStore.longLong(forKey: balanceKey)
                if cloudBalance > 0 {
                    return Int(cloudBalance)
                }
            }
            // 降级到本地存储
            return localDefaults.integer(forKey: balanceKey)
        }
        set {
            if isICloudAvailable {
                ubiquitousStore.set(Int64(newValue), forKey: balanceKey)
                ubiquitousStore.synchronize()
                print("[FishCoinManager] 余额已更新并同步到 iCloud：\(newValue)")
            } else {
                print("[FishCoinManager] iCloud 不可用，使用本地存储：\(newValue)")
            }
            // 同时保存到本地作为备份
            localDefaults.set(newValue, forKey: balanceKey)
        }
    }
    
    // 上次登录日期
    private var lastLoginDateString: String {
        get {
            if isICloudAvailable {
                if let cloudDate = ubiquitousStore.string(forKey: lastLoginDateKey) {
                    return cloudDate
                }
            }
            return localDefaults.string(forKey: lastLoginDateKey) ?? ""
        }
        set {
            if isICloudAvailable {
                ubiquitousStore.set(newValue, forKey: lastLoginDateKey)
                ubiquitousStore.synchronize()
            }
            localDefaults.set(newValue, forKey: lastLoginDateKey)
        }
    }
    
    // 每日奖励（无订阅时）
    private let baseDailyReward = 1
    
    // 订阅奖励
    private let weeklySubscriptionReward = 150
    private let monthlySubscriptionReward = 500
    private let yearlySubscriptionReward = 2000
    
    // 订阅对应的每日奖励
    private let weeklyDailyReward = 5
    private let monthlyDailyReward = 10
    private let yearlyDailyReward = 20
    
    // 生成绘本单张消耗
    private let imageGenerationCost = 10
    /// 生成记录中单张图片重新生成消耗
    private let singleImageRegenerationCost = 5
    
    /// 当前订阅对应的每日奖励
    var currentDailyRewardAmount: Int {
        switch PurchaseManager.shared.currentSubscriptionTier {
        case .yearly:
            return yearlyDailyReward
        case .monthly:
            return monthlyDailyReward
        case .weekly:
            return weeklyDailyReward
        case .none:
            return baseDailyReward
        }
    }

    var currentDailyRewardDescription: String {
        switch PurchaseManager.shared.currentSubscriptionTier {
        case .yearly:
            return "Yearly member daily reward"
        case .monthly:
            return "Monthly member daily reward"
        case .weekly:
            return "Weekly member daily reward"
        case .none:
            return "Daily login reward"
        }
    }

    private init() {
        let currentBalance = balance
        print("[FishCoinManager] 初始化，当前余额：\(currentBalance)")
        print("[FishCoinManager] iCloud 可用：\(isICloudAvailable)")
        
        // 只在 iCloud 可用时监听变化
        if isICloudAvailable {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(iCloudStoreDidChange),
                name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                object: ubiquitousStore
            )
            
            // 异步同步，避免阻塞主线程
            DispatchQueue.global(qos: .utility).async { [weak self] in
                self?.ubiquitousStore.synchronize()
            }
        }
    }
    
    @objc private func iCloudStoreDidChange(notification: Notification) {
        DispatchQueue.main.async {
            print("[FishCoinManager] iCloud 数据已更新")
            // SwiftUI 的 @Observable 会自动处理
        }
    }
    
    /// 检查是否需要显示每日奖励
    func shouldShowDailyReward() -> Bool {
        let today = getTodayDateString()
        let shouldShow = lastLoginDateString != today
        print("[FishCoinManager] 检查每日奖励：上次登录=\(lastLoginDateString), 今天=\(today), 需要显示=\(shouldShow)")
        return shouldShow
    }
    
    /// 领取每日奖励
    func claimDailyReward() -> Int {
        let reward = currentDailyRewardAmount
        balance += reward
        lastLoginDateString = getTodayDateString()
        print("[FishCoinManager] 领取每日奖励：+\(reward)，新余额：\(balance)")
        return reward
    }
    
    /// 按订阅档位获取完整奖励
    func fullSubscriptionRewardAmount(for tier: PurchaseManager.SubscriptionTier) -> Int {
        switch tier {
        case .weekly:
            return weeklySubscriptionReward
        case .monthly:
            return monthlySubscriptionReward
        case .yearly:
            return yearlySubscriptionReward
        }
    }

    /// 按订阅档位获取试用期结束后待补发奖励
    func deferredSubscriptionRewardAmount(for tier: PurchaseManager.SubscriptionTier) -> Int {
        switch tier {
        case .weekly:
            return weeklySubscriptionReward
        case .monthly:
            return max(0, monthlySubscriptionReward - 100)
        case .yearly:
            return max(0, yearlySubscriptionReward - 100)
        }
    }

    /// 按订阅档位发放对应小鱼干奖励
    func grantSubscriptionReward(for tier: PurchaseManager.SubscriptionTier, amount: Int? = nil, source: String, transactionID: UInt64) {
        let rewardAmount = amount ?? fullSubscriptionRewardAmount(for: tier)

        let oldBalance = balance
        balance += rewardAmount
        print("[FishCoinManager] [\(source)] 发放订阅奖励成功：tier=\(tier.rawValue), transactionID=\(transactionID), reward=+\(rewardAmount), 旧余额=\(oldBalance), 新余额=\(balance)")
    }

    
    /// 计算生成指定张数所需小鱼干
    func storyGenerationCost(for imageCount: Int = 1) -> Int {
        max(1, imageCount) * imageGenerationCost
    }
    
    /// 单张图片重新生成所需小鱼干
    func imageRegenerationCost() -> Int {
        singleImageRegenerationCost
    }
    
    /// 检查是否有足够的小鱼干生成故事
    func canGenerateStory(imageCount: Int = 1) -> Bool {
        return balance >= storyGenerationCost(for: imageCount)
    }
    
    /// 消耗小鱼干生成故事
    func consumeForStoryGeneration(imageCount: Int = 1) -> Bool {
        let cost = storyGenerationCost(for: imageCount)
        let currentBalance = balance
        print("[FishCoinManager] 消耗前余额：\(currentBalance)")
        
        guard canGenerateStory(imageCount: imageCount) else {
            print("[FishCoinManager] 余额不足，无法生成故事")
            return false
        }
        
        balance -= cost
        let newBalance = balance
        print("[FishCoinManager] 消耗小鱼干生成故事：-\(cost)，旧余额：\(currentBalance)，新余额：\(newBalance)")
        
        // 验证余额是否正确更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let verifyBalance = self.balance
            print("[FishCoinManager] 验证余额：\(verifyBalance)")
        }
        
        return true
    }
    
    /// 生成失败时退还小鱼干
    func refundForFailedGeneration(imageCount: Int = 1) {
        let refundAmount = storyGenerationCost(for: imageCount)
        balance += refundAmount
        print("[FishCoinManager] 生成失败，退还小鱼干：+\(refundAmount)，新余额：\(balance)")
    }
    
    /// 检查是否有足够的小鱼干重新生成单张图片
    func canRegenerateImage() -> Bool {
        balance >= imageRegenerationCost()
    }
    
    /// 消耗小鱼干重新生成单张图片
    func consumeForImageRegeneration() -> Bool {
        let cost = imageRegenerationCost()
        let currentBalance = balance
        print("[FishCoinManager] 重新生成前余额：\(currentBalance)")
        
        guard canRegenerateImage() else {
            print("[FishCoinManager] 余额不足，无法重新生成图片")
            return false
        }
        
        balance -= cost
        let newBalance = balance
        print("[FishCoinManager] 重新生成图片消耗：-\(cost)，旧余额：\(currentBalance)，新余额：\(newBalance)")
        return true
    }
    
    /// 重新生成失败时退还小鱼干
    func refundForImageRegeneration() {
        let refundAmount = imageRegenerationCost()
        balance += refundAmount
        print("[FishCoinManager] 重新生成失败，退还小鱼干：+\(refundAmount)，新余额：\(balance)")
    }
    
    /// 获取今天的日期字符串（YYYY-MM-DD）
    private func getTodayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    /// 添加小鱼干（用于测试或其他奖励）
    func addCoins(_ amount: Int) {
        balance += amount
        print("[FishCoinManager] 添加小鱼干：+\(amount)，新余额：\(balance)")
    }
    
    /// 手动同步到 iCloud
    func syncToCloud() {
        guard isICloudAvailable else {
            print("[FishCoinManager] iCloud 不可用，跳过同步")
            return
        }
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.ubiquitousStore.synchronize()
            print("[FishCoinManager] 手动同步到 iCloud")
        }
    }
}

