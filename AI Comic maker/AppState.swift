//
//  AppState.swift
//  AI Comic maker
//
//  应用状态与页面流转
//

import SwiftUI
import Mixpanel

/// 页面流转枚举
enum AppPage: Int, CaseIterable {
    case splash = 0
    case obStart = 1
    case obGetStarted = 2
    case obPage2 = 3
    case obPage3 = 4
    case obPage4 = 5   // 选择风格
    case obPage5 = 6   // 选择格式
    case obPage6 = 7   // Get Started（最后一页 → paywall）
    case paywall = 8
    case home = 9
    case storyLoading = 10
    case storyBook = 11
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
    
    /// 故事是否已准备好展示（所有图片生成完毕后才为 true，避免展示旧图）
    var isStoryReady: Bool = false

    /// 当前故事主题
    var storyTheme: String = ""
    
    /// 当前要查看的已保存故事（从「最近的故事」点击进入时使用）
    var viewingSavedStory: SavedStory?
    
    /// 是否显示小鱼干商店
    var showFishCoinShop: Bool = false
    
    /// 是否显示评分弹窗
    var showRateUs: Bool = false
    
    /// 是否显示感谢提示
    var showThankYouToast: Bool = false
    
    /// 是否已经从绘本返回过首页（用于触发评分弹窗）
    var hasReturnedFromStoryBook: Bool = false
    
    /// 是否已经显示过评分弹窗
    @ObservationIgnored
    @AppStorage("hasShownRateUs") var hasShownRateUs = false
    
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
    
    /// 请求 OB 下一页：直接跳转，不再依赖 sparkles 动画
    func requestOBNextPage() {
        guard !obPendingSparkles else {
            print("[AppState] requestOBNextPage 忽略：已在处理跳转")
            return
        }
        
        obPendingSparkles = true
        print("[AppState] requestOBNextPage, 立即跳转下一页")
        
        // 立即跳转，不延迟
        self.nextOnboardingPage()
        
        // 短暂锁定后解锁，防止重复点击
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.obPendingSparkles = false
        }
    }

    /// OB 下一页（sparkles 播完后由 OBFlowContainer 调用，或非 OB 流程直接调用）
    func nextOnboardingPage() {
        let finishedPage = currentPage
        obNavigationForward = true
        withAnimation(.easeInOut(duration: 0.35)) {
            switch currentPage {
            case .obGetStarted: currentPage = .obPage2
            case .obPage2:      currentPage = .obPage3
            case .obPage3:      currentPage = .obPage4
            case .obPage4:      currentPage = .obPage5
            case .obPage5:      currentPage = .obPage6
            case .obPage6:
                hasCompletedOnboarding = true
                currentPage = .paywall
            default: break
            }
        }
        AnalyticsManager.track(
            AnalyticsEvent.obPageFinished,
            properties: [
                "finished_page": finishedPage.rawValue,
                "finished_page_name": String(describing: finishedPage),
                "next_page": currentPage.rawValue,
                "next_page_name": String(describing: currentPage)
            ]
        )
        if finishedPage == .obPage6 {
            AnalyticsManager.track(AnalyticsEvent.onboardingCompleted)
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
            case .obPage2: currentPage = .obGetStarted
            case .obPage3: currentPage = .obPage2
            case .obPage4: currentPage = .obPage3
            case .obPage5: currentPage = .obPage4
            case .obPage6: currentPage = .obPage5
            default: break
            }
        }
        print("[AppState] previousOnboardingPage -> \(currentPage)")
    }

    /// 订阅完成后进入首页（仅在购买成功后调用）
    func dismissPaywall() {
        hasCompletedOnboarding = true
        currentPage = .home
        AnalyticsManager.track(AnalyticsEvent.subscriptionPurchaseSucceeded)
        print("[AppState] dismissPaywall -> home")
    }

    func skipPaywallForTesting() {
        currentPage = .home
        print("[AppState] skipPaywallForTesting -> home")
    }
    
    
    /// 开始故事创作（从首页点击开始按钮）
    func startStoryCreation(theme: String) {
        storyTheme = theme
        isStoryReady = false  // 重置，防止旧图片提前显示
        print("[AppState] startStoryCreation, theme: \(theme)")
        // 先跳转到loading页面
        currentPage = .storyLoading
    }

    /// 完成故事加载，跳转到绘本页面
    func finishStoryLoading() {
        print("[AppState] finishStoryLoading, 跳转到绘本页面")
        isStoryReady = true   // 所有图片已就绪，可以安全展示
        currentPage = .storyBook
    }
    
    /// 从首页进入绘本页面（已废弃，保留用于兼容）
    func showStoryBook() {
        currentPage = .storyBook
        print("[AppState] showStoryBook")
    }
    
    /// 从绘本页面返回首页
    func backToHome(fromStoryBook: Bool = false) {
        currentPage = .home
        viewingSavedStory = nil
        isStoryReady = false  // 重置，下次生成前不显示旧内容
        hasReturnedFromStoryBook = fromStoryBook
        print("[AppState] backToHome, fromStoryBook: \(fromStoryBook)")
        
        // 仅首次从绘本返回首页时，显示评分弹窗
        if fromStoryBook && !hasShownRateUs {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showRateUs = true
                self.hasShownRateUs = true
                print("[AppState] 显示评分弹窗")
            }
        }
    }
    
    /// 查看已保存的故事
    func viewSavedStory(_ story: SavedStory) {
        viewingSavedStory = story
        currentPage = .storyBook
        print("[AppState] viewSavedStory, 主题：\(story.theme)")
    }
    
    /// 启动页结束后决定跳转
    func onSplashComplete() {
        Task {
            let hasSubscription = await PurchaseManager.shared.hasActiveSubscription()
            await MainActor.run {
                if hasCompletedOnboarding {
                    currentPage = hasSubscription ? .home : .paywall
                    print("[AppState] onSplashComplete -> \(currentPage)")
                } else {
                    currentPage = .obGetStarted
                    print("[AppState] onSplashComplete -> obGetStarted")
                }
            }
        }
    }
    
    /// 显示感谢提示
    func showThankYouMessage() {
        showThankYouToast = true
        print("[AppState] 显示感谢提示")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showThankYouToast = false
            print("[AppState] 隐藏感谢提示")
        }
    }
}
