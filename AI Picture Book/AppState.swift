//
//  AppState.swift
//  AI Picture Book
//
//  应用状态与页面流转
//

import SwiftUI

/// 页面流转枚举
enum AppPage: Int, CaseIterable {
    case splash = 0
    case obStart = 1
    case obAge = 2
    case obGender = 3
    case obAvatar = 4
    case obName = 5
    case home = 6
    case storyLoading = 7
    case storyBook = 8
}

/// 用户选择年龄段
enum ChildAge: String, CaseIterable {
    case age2_3 = "2-3岁"
    case age4_5 = "4-5岁"
    case age6_7 = "6-7岁"
}

/// 用户选择性别
enum ChildGender: String, CaseIterable {
    case boy = "男孩"
    case girl = "女孩"
}

/// 头像选项（设计稿中的 6 种）
enum AvatarOption: String, CaseIterable {
    case smile
    case star
    case sun
    case moon
    case cloud
    case flower
    
    var sfSymbolName: String {
        switch self {
        case .smile: return "face.smiling"
        case .star: return "star.fill"
        case .sun: return "sun.max.fill"
        case .moon: return "moon.fill"
        case .cloud: return "cloud.fill"
        case .flower: return "leaf.fill"
        }
    }
    
    var color: String {
        switch self {
        case .smile, .moon: return "FF6B9D"
        case .star, .cloud: return "4ECDC4"
        case .sun, .flower: return "FFB84D"
        }
    }
}

@Observable
final class AppState {
    static let shared = AppState()
    
    /// 当前显示的页面
    var currentPage: AppPage = .splash
    
    /// 是否已完成 Onboarding（用于持久化）
    @ObservationIgnored
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    
    /// 用户数据
    @ObservationIgnored
    @AppStorage("childAge") var childAgeRaw: String = ""
    @ObservationIgnored
    @AppStorage("childGender") var childGenderRaw: String = ""
    @ObservationIgnored
    @AppStorage("childAvatar") var childAvatarRaw: String = ""
    @ObservationIgnored
    @AppStorage("childName") var childName: String = ""
    
    /// 当前故事主题
    var storyTheme: String = ""
    
    var childAge: ChildAge? {
        get { ChildAge(rawValue: childAgeRaw) }
        set { childAgeRaw = newValue?.rawValue ?? "" }
    }
    
    var childGender: ChildGender? {
        get { ChildGender(rawValue: childGenderRaw) }
        set { childGenderRaw = newValue?.rawValue ?? "" }
    }
    
    var childAvatar: AvatarOption? {
        get { AvatarOption(rawValue: childAvatarRaw) }
        set { childAvatarRaw = newValue?.rawValue ?? "" }
    }
    
    private init() {}
    
    /// 进入 OB 流程（从启动页或 OB 开始）
    func enterOnboarding() {
        print("[AppState] enterOnboarding")
        currentPage = .obAge
    }
    
    /// OB 下一页
    func nextOnboardingPage() {
        switch currentPage {
        case .obAge: currentPage = .obGender
        case .obGender: currentPage = .obAvatar
        case .obAvatar: currentPage = .obName
        case .obName:
            hasCompletedOnboarding = true
            currentPage = .home
        default: break
        }
        print("[AppState] nextOnboardingPage -> \(currentPage)")
    }
    
    /// 完成 Onboarding 进入首页
    func finishOnboarding() {
        hasCompletedOnboarding = true
        currentPage = .home
        print("[AppState] finishOnboarding -> home")
    }
    
    /// 开始故事创作（从首页点击开始按钮）
    func startStoryCreation(theme: String) {
        storyTheme = theme
        print("[AppState] startStoryCreation, theme: \(theme)")
        // 先跳转到loading页面
        currentPage = .storyLoading
    }
    
    /// 完成故事加载，跳转到绘本页面
    func finishStoryLoading() {
        print("[AppState] finishStoryLoading, 跳转到绘本页面")
        currentPage = .storyBook
    }
    
    /// 从首页进入绘本页面（已废弃，保留用于兼容）
    func showStoryBook() {
        currentPage = .storyBook
        print("[AppState] showStoryBook")
    }
    
    /// 从绘本页面返回首页
    func backToHome() {
        currentPage = .home
        print("[AppState] backToHome")
    }
    
    /// 启动页结束后决定跳转
    func onSplashComplete() {
        if hasCompletedOnboarding {
            currentPage = .home
            print("[AppState] onSplashComplete -> home (already onboarded)")
        } else {
            currentPage = .obStart
            print("[AppState] onSplashComplete -> obStart")
        }
    }
}
