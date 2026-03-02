//
//  FishCoinManager.swift
//  AI Picture Book
//
//  小鱼干货币系统管理器（使用 iCloud 同步）
//

import Foundation
import SwiftUI

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
    
    // 每日奖励
    private let dailyReward = 1
    
    // 订阅奖励
    private let monthlySubscriptionReward = 50
    private let yearlySubscriptionReward = 200
    
    // 生成绘本消耗
    private let storyGenerationCost = 10
    
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
        balance += dailyReward
        lastLoginDateString = getTodayDateString()
        print("[FishCoinManager] 领取每日奖励：+\(dailyReward)，新余额：\(balance)")
        return dailyReward
    }
    
    /// 月订阅奖励
    func grantMonthlySubscriptionReward() {
        balance += monthlySubscriptionReward
        print("[FishCoinManager] 月订阅奖励：+\(monthlySubscriptionReward)，新余额：\(balance)")
    }
    
    /// 年订阅奖励
    func grantYearlySubscriptionReward() {
        balance += yearlySubscriptionReward
        print("[FishCoinManager] 年订阅奖励：+\(yearlySubscriptionReward)，新余额：\(balance)")
    }
    
    /// 检查是否有足够的小鱼干生成故事
    func canGenerateStory() -> Bool {
        return balance >= storyGenerationCost
    }
    
    /// 消耗小鱼干生成故事
    func consumeForStoryGeneration() -> Bool {
        let currentBalance = balance
        print("[FishCoinManager] 消耗前余额：\(currentBalance)")
        
        guard canGenerateStory() else {
            print("[FishCoinManager] 余额不足，无法生成故事")
            return false
        }
        
        balance -= storyGenerationCost
        let newBalance = balance
        print("[FishCoinManager] 消耗小鱼干生成故事：-\(storyGenerationCost)，旧余额：\(currentBalance)，新余额：\(newBalance)")
        
        // 验证余额是否正确更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let verifyBalance = self.balance
            print("[FishCoinManager] 验证余额：\(verifyBalance)")
        }
        
        return true
    }
    
    /// 生成失败时退还小鱼干
    func refundForFailedGeneration() {
        balance += storyGenerationCost
        print("[FishCoinManager] 生成失败，退还小鱼干：+\(storyGenerationCost)，新余额：\(balance)")
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

