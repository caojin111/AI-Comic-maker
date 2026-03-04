//
//  HomeView.swift
//  AI Picture Book
//
//  首页：全新设计，温馨儿童绘本风格
//

import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var fishCoinManager = FishCoinManager.shared
    @State private var fishCoinBalance: Int = 0
    @State private var showThemeModal = false
    @State private var showAllStories = false
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var showDailyReward = false
    @State private var dailyRewardAmount = 0
    @State private var recentStories: [SavedStory] = []
    @State private var createButtonScale: CGFloat = 1.0
    @State private var refreshID = UUID()
    
    private let maxStoriesOnHome = 3
    
    private var displayName: String {
        let name = appState.childName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Little Reader" : name
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Sweet Dreams"
        }
    }
    
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
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // 顶部头像卡片区域
                    topProfileCard
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 36)
                    
                    // 中部创作按钮区域
                    createStorySection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                    
                    // 底部历史记录区域
                    recentStoriesSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                }
            }
        }
        .overlay {
            if showSettings {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture { showSettings = false }
                    .overlay {
                        SettingsPopupView(isPresented: $showSettings)
                    }
                    .zIndex(1000)
            }
            if showEditProfile {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture { showEditProfile = false }
                    .overlay {
                        EditProfilePopupView(isPresented: $showEditProfile)
                            .environment(appState)
                    }
                    .zIndex(1000)
                    .onChange(of: showEditProfile) { oldValue, newValue in
                        if !newValue {
                            // 弹窗关闭时强制刷新
                            refreshID = UUID()
                        }
                    }
            }
            if showDailyReward {
                DailyRewardPopupView(isPresented: $showDailyReward, rewardAmount: dailyRewardAmount)
                    .zIndex(2000)
                    .onChange(of: showDailyReward) { oldValue, newValue in
                        if !newValue {
                            // 弹窗关闭时刷新余额，稍微延迟确保数据已保存
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                fishCoinBalance = fishCoinManager.balance
                                print("[HomeView] 每日奖励弹窗关闭，刷新余额：\(fishCoinBalance)")
                            }
                        }
                    }
            }
        }
        .overlay {
            if showThemeModal {
                ThemeInputModalView(isPresented: $showThemeModal)
                    .environment(appState)
                    .zIndex(1000)
                    .onChange(of: showThemeModal) { oldValue, newValue in
                        if !newValue {
                            // 弹窗关闭时刷新余额
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                let newBalance = fishCoinManager.balance
                                print("[HomeView] 主题弹窗关闭，刷新余额：\(fishCoinBalance) -> \(newBalance)")
                                fishCoinBalance = newBalance
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showAllStories) {
            RecentStoriesListView(stories: recentStories)
                .environment(appState)
        }
        .sheet(isPresented: Binding(
            get: { appState.showFishCoinShop },
            set: { appState.showFishCoinShop = $0 }
        )) {
            FishCoinShopView()
        }
        .overlay {
            if appState.showRateUs {
                RateUsView(isPresented: Binding(
                    get: { appState.showRateUs },
                    set: { appState.showRateUs = $0 }
                ))
                .environment(appState)
                .zIndex(3000)
            }
        }
        .overlay {
            // Thank You Toast
            if appState.showThankYouToast {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "81C784"))
                        Text("Thanks for your feedback!")
                            .font(AppTheme.fontBold(size: 16))
                            .foregroundColor(Color(hex: "5D4E37"))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    )
                    .padding(.bottom, 50)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(4000)
            }
        }
        .onChange(of: appState.showFishCoinShop) { oldValue, newValue in
            if !newValue {
                // 商店关闭时刷新余额
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    fishCoinBalance = fishCoinManager.balance
                    print("[HomeView] 小鱼干商店关闭，刷新余额：\(fishCoinBalance)")
                }
            }
        }
        .onAppear {
            print("[HomeView] onAppear")
            setOrientation(.portrait)
            
            // 检查订阅状态，未订阅则跳转到 Paywall
            Task {
                let hasSubscription = await PurchaseManager.shared.hasActiveSubscription()
                if !hasSubscription {
                    print("[HomeView] 用户未订阅，跳转到 Paywall")
                    appState.currentPage = .paywall
                    return
                }
            }
            
            fishCoinBalance = fishCoinManager.balance
            recentStories = StoryStorage.shared.loadAll()
            startCreateButtonAnimation()
            checkDailyReward()
        }
    }
    
    // MARK: - 检查每日奖励
    private func checkDailyReward() {
        if fishCoinManager.shouldShowDailyReward() {
            dailyRewardAmount = fishCoinManager.claimDailyReward()
            // 立即更新余额
            fishCoinBalance = fishCoinManager.balance
            print("[HomeView] 领取每日奖励后余额：\(fishCoinBalance)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showDailyReward = true
            }
        }
    }
    
    // MARK: - 顶部区域（头像和小鱼干）
    private var topProfileCard: some View {
        HStack(alignment: .top, spacing: 16) {
            // 头像区域
            Button(action: {
                print("[HomeView] 点击头像")
                showEditProfile = true
            }) {
                HStack(spacing: 14) {
                    // 头像
                    ZStack {
                        if let avatar = appState.childAvatar {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: avatar.color).opacity(0.8), Color(hex: avatar.color)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            LottieView(
                                animationName: avatar.lottieAnimationName,
                                subdirectory: "lottie",
                                contentMode: .scaleAspectFit
                            )
                            .frame(width: 80, height: 80)
                            .id(avatar.rawValue)
                        } else {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FFB6C1"), Color(hex: "FF69B4")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Image(systemName: "sparkles")
                                .font(AppTheme.font(size: 32))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 68, height: 68)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .id(refreshID)
                    
                    // 问候语和名字
                    VStack(alignment: .leading, spacing: 6) {
                        Text(greetingText)
                            .font(AppTheme.fontRowdiesBold(size: 20))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "FF6A88"), Color(hex: "FF9A8B")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        Text(displayName)
                            .font(AppTheme.fontBold(size: 18))
                            .foregroundStyle(Color(hex: "5D4E37"))
                            .lineLimit(1)
                        Text("Ready for a new adventure?")
                            .font(AppTheme.font(size: 12))
                            .foregroundStyle(Color(hex: "A0826D"))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(ClickSoundButtonStyle())
            
            // 小鱼干货币（右上角，缩小版，整个区域可点击）
            Button(action: {
                print("[HomeView] 点击小鱼干区域，打开商店")
                appState.showFishCoinShop = true
            }) {
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "FFB84D"), Color(hex: "FF9A8B")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                        
                        Image("fish coin")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                    .shadow(color: Color(hex: "FFB84D").opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Text("\(fishCoinBalance)")
                        .font(AppTheme.fontBold(size: 18))
                        .foregroundStyle(Color(hex: "5D4E37"))
                    
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                        Image(systemName: "plus")
                            .font(AppTheme.fontBold(size: 11))
                            .foregroundStyle(Color(hex: "FFB84D"))
                    }
                    .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white)
                        .shadow(color: Color(hex: "D4A574").opacity(0.12), radius: 6, x: 0, y: 2)
                )
            }
            .buttonStyle(ClickSoundButtonStyle())
        }
    }
    
    // MARK: - 创作按钮区域
    private var createStorySection: some View {
        VStack(spacing: 12) {
            // 主创作按钮
            Button(action: {
                print("[HomeView] 点击创作按钮")
                showThemeModal = true
            }) {
                ZStack {
                    // 背景渐变
                    RoundedRectangle(cornerRadius: 32)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "FF9A8B"),
                                    Color(hex: "FF6A88"),
                                    Color(hex: "FF99AC")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // 装饰性圆点
                    GeometryReader { geo in
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .offset(x: geo.size.width - 60, y: -20)
                        
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 120, height: 120)
                            .offset(x: -40, y: geo.size.height - 60)
                    }
                    
                    // 内容
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.25))
                                .frame(width: 88, height: 88)
                            
                            Image(systemName: "plus.circle.fill")
                                .font(AppTheme.font(size: 56))
                                .foregroundStyle(.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        
                        VStack(spacing: 6) {
                            Text("Create New Story")
                                .font(AppTheme.fontBold(size: 22))
                                .foregroundStyle(.white)
                            
                            Text("Tap to start your magical journey")
                                .font(AppTheme.font(size: 13))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                    .padding(.vertical, 22)
                }
                .frame(height: 165)
                .frame(maxWidth: 340)
                .scaleEffect(createButtonScale)
                .shadow(color: Color(hex: "FF6A88").opacity(0.4), radius: 20, x: 0, y: 8)
            }
            .buttonStyle(ClickSoundButtonStyle())
        }
    }
    
    // MARK: - 最近故事区域
    private var recentStoriesSection: some View {
        VStack(spacing: 16) {
            // 标题和“查看更多”
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "book.fill")
                        .font(AppTheme.font(size: 18))
                        .foregroundStyle(Color(hex: "FF6A88"))
                    Text("Recent Stories")
                        .font(AppTheme.fontBold(size: 20))
                        .foregroundStyle(Color(hex: "5D4E37"))
                }
                
                Spacer()
                
                if !recentStories.isEmpty {
                    Button(action: {
                        print("[HomeView] 点击查看更多")
                        showAllStories = true
                    }) {
                        HStack(spacing: 4) {
                            Text("View All")
                                .font(AppTheme.font(size: 14))
                            Image(systemName: "arrow.right.circle.fill")
                                .font(AppTheme.font(size: 16))
                        }
                        .foregroundStyle(Color(hex: "FF6A88"))
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                }
            }
            .frame(maxWidth: 340)
            
            if recentStories.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "book.closed.fill")
                        .font(AppTheme.font(size: 48))
                        .foregroundStyle(Color(hex: "D4A574").opacity(0.5))
                    
                    Text("No Stories Yet")
                        .font(AppTheme.fontBold(size: 17))
                        .foregroundStyle(Color(hex: "8B7355"))
                    
                    Text("Create your first magical story above!")
                        .font(AppTheme.font(size: 13))
                        .foregroundStyle(Color(hex: "A0826D"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: 340)
                .padding(.vertical, 36)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color(hex: "D4A574").opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                        )
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(recentStories.prefix(maxStoriesOnHome))) { story in
                        EnhancedStoryRowButton(story: story) {
                            print("[HomeView] 点击故事：\(story.theme)")
                            appState.viewSavedStory(story)
                        }
                    }
                }
                .frame(maxWidth: 340)
            }
        }
    }
    
    // MARK: - 动画
    private func startCreateButtonAnimation() {
        withAnimation(
            Animation.easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
        ) {
            createButtonScale = 1.02
        }
    }
    
    // MARK: - 竖屏控制
    private func setOrientation(_ orientation: UIInterfaceOrientationMask) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first
        else { return }
        
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
    }
}

// MARK: - 增强版故事行按钮（首页专用）
private struct EnhancedStoryRowButton: View {
    let story: SavedStory
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // 封面图
                ZStack {
                    if let firstPage = story.pages.first, !firstPage.imageUrl.isEmpty,
                       let url = URL(string: firstPage.imageUrl) {
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FFD6A5"), Color(hex: "FDCB6E")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    ProgressView()
                                        .tint(.white)
                                )
                        }
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white, lineWidth: 2)
                        )
                    } else {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "A8E6CF"), Color(hex: "81C784")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                            .overlay(
                                Image(systemName: "book.fill")
                                    .font(AppTheme.font(size: 28))
                                    .foregroundStyle(.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                }
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                
                // 文字信息
                VStack(alignment: .leading, spacing: 6) {
                    Text(story.theme)
                        .font(AppTheme.fontBold(size: 16))
                        .foregroundStyle(Color(hex: "5D4E37"))
                        .lineLimit(1)
                    
                    Text(story.previewText)
                        .font(AppTheme.font(size: 13))
                        .foregroundStyle(Color(hex: "8B7355"))
                        .lineLimit(2)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(AppTheme.font(size: 10))
                        Text(story.formattedDate)
                            .font(AppTheme.font(size: 11))
                    }
                    .foregroundStyle(Color(hex: "A0826D"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 箭头
                Image(systemName: "chevron.right")
                    .font(AppTheme.font(size: 16))
                    .foregroundStyle(Color(hex: "D4A574"))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .shadow(color: Color(hex: "D4A574").opacity(0.15), radius: 8, x: 0, y: 3)
            )
        }
        .buttonStyle(ClickSoundButtonStyle())
    }
}

#Preview {
    HomeView()
        .environment(AppState.shared)
}
