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
    case obGetStarted = 2
    case obTeamIntro = 3
    case obAge = 4
    case obAgeMotivation = 5
    case obGender = 6
    case obAvatar = 7
    case obName = 8
    case obNameMotivation = 9
    case obRelationship = 10
    case obRelationshipMotivation = 11
    case obPersonalizing = 12
    case paywall = 13
    case home = 14
    case storyLoading = 15
    case storyBook = 16
}

/// 用户选择年龄段
enum ChildAge: String, CaseIterable {
    case under3 = "Under 3"
    case age3_5 = "3-5"
    case age6_7 = "6-7"
    case age8Plus = "8+"
}

/// 用户与孩子的关系（Who are you to the child?）
enum ChildRelationship: String, CaseIterable {
    case mom = "Mom"
    case dad = "Dad"
    case grandparent = "Grandparent"
    case teacher = "Teacher"
    case other = "Other"
}

/// 用户选择性别
enum ChildGender: String, CaseIterable {
    case boy = "Boy"
    case girl = "Girl"
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
    
    /// 头像对应的 Lottie 动画文件名（不含 .json）
    var lottieAnimationName: String {
        switch self {
        case .smile: return "boy-with-a-relieved-expression-animation_10780301"
        case .star: return "boy-with-a-relieved-expression-animation_10780302"
        case .sun: return "boy-with-a-relieved-expression-animation_10780303"
        case .moon: return "girl-with-a-relieved-expression-animation_10780306"
        case .cloud: return "girl-with-a-relieved-expression-animation_10780307"
        case .flower: return "girl-with-a-relieved-expression-animation_10780309"
        }
    }
}

@Observable
final class AppState {
    static let shared = AppState()
    
    /// 当前显示的页面
    var currentPage: AppPage = .splash
    
    /// OB 翻页方向：true = 下一页（从左滑入），false = 上一页（从右滑入），用于过渡动画
    var obNavigationForward: Bool = true

    /// 为 true 时表示正在播放进度条 sparkles，播完后会执行 nextOnboardingPage
    var obPendingSparkles: Bool = false
    
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
    @ObservationIgnored
    @AppStorage("childRelationship") var childRelationshipRaw: String = ""
    
    /// 当前故事主题
    var storyTheme: String = ""
    
    /// 当前要查看的已保存故事（从「最近的故事」点击进入时使用）
    var viewingSavedStory: SavedStory?
    
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
    
    var childRelationship: ChildRelationship? {
        get { ChildRelationship(rawValue: childRelationshipRaw) }
        set { childRelationshipRaw = newValue?.rawValue ?? "" }
    }
    
    private init() {}
    
    /// 进入 OB 流程（从启动页或 OB 开始）
    func enterOnboarding() {
        print("[AppState] enterOnboarding -> obGetStarted")
        currentPage = .obGetStarted
    }
    
    /// 请求 OB 下一页：先播进度条 sparkles，播完后再调用 nextOnboardingPage（OB 内容页用）
    func requestOBNextPage() {
        guard !obPendingSparkles else {
            print("[AppState] requestOBNextPage 忽略：已在播放 sparkles")
            return
        }
        obPendingSparkles = true
        print("[AppState] requestOBNextPage, obPendingSparkles = true")
    }

    /// OB 下一页（sparkles 播完后由 OBFlowContainer 调用，或非 OB 流程直接调用）
    func nextOnboardingPage() {
        obNavigationForward = true
        withAnimation(.easeInOut(duration: 0.35)) {
            switch currentPage {
            case .obGetStarted: currentPage = .obTeamIntro
            case .obTeamIntro: currentPage = .obAge
            case .obAge: currentPage = .obAgeMotivation
            case .obAgeMotivation: currentPage = .obGender
            case .obGender: currentPage = .obAvatar
            case .obAvatar: currentPage = .obName
            case .obName: currentPage = .obNameMotivation
            case .obNameMotivation: currentPage = .obRelationship
            case .obRelationship: currentPage = .obRelationshipMotivation
            case .obRelationshipMotivation: currentPage = .obPersonalizing
            case .obPersonalizing: currentPage = .paywall
            default: break
            }
        }
        print("[AppState] nextOnboardingPage -> \(currentPage)")
    }
    
    /// 完成 Onboarding 进入首页
    func finishOnboarding() {
        hasCompletedOnboarding = true
        currentPage = .home
        print("[AppState] finishOnboarding -> home")
    }

    /// OB 返回上一页
    func previousOnboardingPage() {
        obNavigationForward = false
        withAnimation(.easeInOut(duration: 0.35)) {
            switch currentPage {
            case .obTeamIntro: currentPage = .obGetStarted
            case .obAge: currentPage = .obTeamIntro
            case .obAgeMotivation: currentPage = .obAge
            case .obGender: currentPage = .obAgeMotivation
            case .obAvatar: currentPage = .obGender
            case .obName: currentPage = .obAvatar
            case .obNameMotivation: currentPage = .obName
            case .obRelationship: currentPage = .obNameMotivation
            case .obRelationshipMotivation: currentPage = .obRelationship
            default: break
            }
        }
        print("[AppState] previousOnboardingPage -> \(currentPage)")
    }

    /// Paywall 关闭或订阅完成后进入首页
    func dismissPaywall() {
        hasCompletedOnboarding = true
        currentPage = .home
        print("[AppState] dismissPaywall -> home")
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
        viewingSavedStory = nil
        print("[AppState] backToHome")
    }
    
    /// 查看已保存的故事
    func viewSavedStory(_ story: SavedStory) {
        viewingSavedStory = story
        currentPage = .storyBook
        print("[AppState] viewSavedStory, 主题：\(story.theme)")
    }
    
    /// 启动页结束后决定跳转
    func onSplashComplete() {
        if hasCompletedOnboarding {
            currentPage = .home
            print("[AppState] onSplashComplete -> home (already onboarded)")
        } else {
            currentPage = .obGetStarted
            print("[AppState] onSplashComplete -> obGetStarted")
        }
    }
}
