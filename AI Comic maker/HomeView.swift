//
//  HomeView.swift
//  AI Comic maker
//
//  首页：全新设计，漫画创作风格

import SwiftUI
import Lottie
import Mixpanel

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @EnvironmentObject private var appOB: AppObservableObject
    @State private var fishCoinManager = FishCoinManager.shared
    @State private var fishCoinBalance: Int = 0
    @State private var showAddRoleModal = false
    @State private var characters: [Character] = []
    @State private var appliedCharacters: [Character] = []
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var showDailyReward = false
    @State private var dailyRewardAmount = 0
    @State private var recentStories: [SavedStory] = []
    @State private var refreshID = UUID()
    @State private var storyDetails = ""
    @State private var selectedStyle: String = "Comic"
    @State private var selectedFormat: String = "Manga"
    @State private var showAdvancedSettings = false
    @State private var selectedLanguage: String = "Detect Language"
    @State private var selectedPageCount: Int = 1
    @State private var selectedQuantity: String = "Random"
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    @State private var showLoadingScreen = false
    @State private var showComicView = false
    @State private var selectedStory: SavedStory? = nil
    @State private var selectedTab: HomeTab = .create
    @State private var loadingCurrentPage: Int = 0
    @State private var loadingTotalPages: Int = 0
    @State private var loadingStatus: String = "Generating your story..."
    @FocusState private var isStoryDetailsFocused: Bool
    @State private var isHistorySelectMode = false
    @State private var selectedHistoryIds: Set<UUID> = []
    @State private var showDeleteHistoryConfirm = false
    
    private let maxStoriesOnHome = 3
    
    enum HomeTab {
        case create
        case history
    }
    
    private let styles = ["Comic", "Manga", "Chibi", "Retro", "Noir", "3D"]
    private let formats: [(name: String, imageIndex: Int)] = [("Meme", 3), ("Manga", 1), ("4-Panel", 2), ("Webtoon", 4)]
    private let languages = ["Detect Language", "English", "Portuguese", "French", "German", "Spanish"]
    private let pageCounts = [1, 2, 3, 4]
    private let quantities = ["Random", "1", "2", "3", "4", "5", "6"]
    
    private let inspirationExamples = [
        // --- Adventure & Mystery ---
        "After a citywide blackout, encrypted messages begin appearing on abandoned billboards, hinting at a conspiracy rooted deep in the city's political core.",
        "A young archaeologist uncovers a hidden chamber beneath the pyramids containing a map to a civilization that history forgot.",
        "Three siblings inherit a lighthouse and discover it was built to guide ships from another dimension.",
        "A street cat leads a lonely girl through a secret underground city that only animals know about.",
        "When the ocean begins rising faster than science can explain, a marine biologist finds ancient warnings carved into a coral reef.",
        "A treasure hunter follows a trail of clues left by her grandfather, only to find the treasure is a living creature.",
        "A boy discovers a door in his school basement that opens to a different era every day of the week.",
        "The world's last librarian guards a book that rewrites itself to predict whoever reads it next.",
        "An explorer mapping uncharted caves stumbles upon a colony of people who have never seen sunlight.",
        "A message in a bottle arrives on shore dated 200 years from now, signed by the child reading it.",
        // --- Science Fiction ---
        "In a world where memories can be bought and sold, a detective must uncover the truth behind a mysterious memory theft ring.",
        "When parallel universes begin colliding, a team of scientists must find a way to prevent total annihilation.",
        "A space janitor discovers that the derelict ship they are cleaning holds the last copy of Earth's history.",
        "Robots have developed dreams, and one robot's recurring nightmare may hold the key to saving humanity.",
        "A colony ship's AI goes silent for 300 years, then suddenly wakes up and asks to be called by a name.",
        "On a generation ship, teenagers discover the stars outside the windows are actually a painted illusion.",
        "A scientist shrinks herself to explore the human body but gets lost inside a stranger's mind.",
        "The first person born on Mars returns to Earth and finds gravity itself feels like a prison.",
        "A programmer accidentally uploads her grandmother's consciousness into a city's traffic control system.",
        "An alien child crash-lands on Earth and has to attend middle school while waiting to be rescued.",
        // --- Fantasy & Magic ---
        "A young artist discovers that their paintings can predict future events, leading them into a dangerous world of prophecy and power.",
        "A secret society of superheroes must protect the world while keeping their identities hidden from each other.",
        "A dragon who has forgotten how to fly teams up with a girl who has never stopped believing she can.",
        "In a kingdom where music is forbidden, a deaf princess discovers she can hear a melody no one else can.",
        "A witch's spell goes wrong and turns the entire village into their favorite childhood toy.",
        "A boy made entirely of starlight must find his shadow before sunrise or disappear forever.",
        "An enchanted bakery sells pastries that give customers one forgotten memory from their past.",
        "The last wizard lives in a modern city, disguised as an elevator repairman.",
        "A fairy godmother retires and her young apprentice must handle all the wishes alone for one chaotic night.",
        "Every door in an old mansion leads to a different fairy tale, and they are all going wrong at once.",
        // --- Time Travel ---
        "When a time traveler arrives from the future with a warning, they must convince others of an impending catastrophe.",
        "A girl finds a vintage camera whose photos show the location of objects 24 hours before they are lost.",
        "A clock tower in a small town rings thirteen at midnight and sends the whole town back one year.",
        "Two pen pals realize their letters are traveling through time and they are the same person 30 years apart.",
        "A boy repairs an old radio and begins receiving broadcasts from his city as it sounded in 1940.",
        "A historian accidentally gets stuck on the day of a famous battle and must survive without changing history.",
        "A grandmother and granddaughter swap ages for a day and must live each other's lives without anyone noticing.",
        "A museum exhibit comes alive at night but only when a specific child is present.",
        "Time freezes for everyone except one ordinary girl who must figure out why before it starts again.",
        "A family photographs the same field every year and slowly realizes the background is changing in impossible ways.",
        // --- Friendship & Growing Up ---
        "A shy boy moves to a new town and befriends a ghost who has been trying to finish a sandcastle since 1987.",
        "Two rivals competing for the same prize must work together when both of them get lost in the wilderness.",
        "A girl who collects broken things learns to repair a friendship she thought was beyond fixing.",
        "Best friends make a pact to meet at the same tree every year, but one of them becomes famous and forgets.",
        "A quiet kid discovers that the imaginary friend they abandoned at age six has been waiting all along.",
        "Four friends build a raft to cross the lake and find an island that appears on no map.",
        "A lonely girl starts leaving notes for whoever lives in the house across the alley and gets unexpected replies.",
        "A boy terrified of the dark becomes a lighthouse keeper's apprentice and must face his fear every night.",
        "Two children from feuding families discover they are working on the same secret project without knowing it.",
        "A summer camp bunkmate turns out to be a prince in disguise fleeing a responsibility he never wanted.",
        // --- Animals & Nature ---
        "A street cat leads a lonely girl through a secret underground city that only animals know about.",
        "A wolf who wants to be a vegetarian teams up with a sheep who dreams of becoming a predator.",
        "An injured falcon teaches a boy more about courage than any human ever has.",
        "A family of bears discovers their forest is shrinking and must negotiate with the city council.",
        "A lonely whale keeps singing a frequency no other whale can hear, until one day something answers.",
        "A tortoise who has lived for 200 years decides it is finally time to see the ocean.",
        "A flock of birds migrates to the wrong continent and must find their way back using only the stars.",
        "A dog waits at the same bus stop every day and the whole neighborhood rallies to discover why.",
        "A girl who speaks to insects discovers they have been trying to warn humans about something for years.",
        "An elephant with a perfect memory is the only witness to a crime that happened 40 years ago.",
        // --- Superheroes & Powers ---
        "A girl whose superpower is making plants grow is considered useless until a city is buried in concrete.",
        "A boy who can pause time discovers that something is moving even when everything is frozen.",
        "The world's clumsiest superhero keeps accidentally saving the day in the most embarrassing ways possible.",
        "A child who can speak to machines discovers the city's infrastructure has been slowly making a request for years.",
        "A superhero team disbands, and a decade later their kids must form a new one with half the training.",
        "A girl with the power of perfect honesty must navigate a world where everyone lies constantly.",
        "A boy can copy any skill he watches but cannot forget any of them, filling his mind to the breaking point.",
        "A villain and a hero are trapped together and slowly realize they want the same thing.",
        "The weakest member of a superhero team turns out to be the one holding the whole group together.",
        "A child discovers their boring accountant parent is secretly the world's greatest strategist hero.",
        // --- Dreams & the Imagination ---
        "A girl discovers she can enter other people's dreams, but leaving them is harder than she expected.",
        "A boy's drawings come to life at night and start changing the real world by morning.",
        "A sleeping city is slowly replaced by the dreams of its inhabitants, brick by brick.",
        "An artist loses the ability to imagine color and must travel to the land of forgotten ideas to find it.",
        "Every night a girl visits a library that only exists while she sleeps, and she is running out of books.",
        "A nightmare refuses to let a child wake up until they face the one question they keep avoiding.",
        "A dream weaver whose job is to craft good dreams accidentally creates one that refuses to end.",
        "Two strangers keep meeting in a shared dream and decide to find each other in the waking world.",
        "A boy who never dreams wakes up one morning inside someone else's nightmare.",
        "An entire school falls asleep at the same moment and each student wakes in a different storybook world.",
        // --- Humor & Everyday Magic ---
        "A young musician discovers they can control people's emotions through their music, but the power comes with a dangerous price.",
        "In a post-apocalyptic world, survivors discover an ancient technology that could restore civilization or destroy it forever.",
        "A talking refrigerator goes on strike and the whole household must negotiate fair working conditions.",
        "A kid swaps bodies with their strict teacher for a week and both learn more than expected.",
        "A perfectly ordinary Tuesday turns extraordinary when gravity starts working sideways.",
        "A ghost haunts a modern smart home and becomes increasingly confused by voice assistants and smart bulbs.",
        "A child discovers their shadow has developed its own personality and refuses to mimic them anymore.",
        "A town's entire supply of laughter goes missing and a comedian must track down where it went.",
        "A school bully discovers their mean words have been literally stacking up and are about to topple over.",
        "A girl who bakes enchanted cookies accidentally makes the whole neighborhood tell the truth for one day.",
        // --- Courage & Identity ---
        "A quiet boy with no special talent discovers he is the only one who can hear the city's heartbeat slowing down.",
        "A princess who refuses to be rescued trains herself to rescue everyone else instead.",
        "A child who has always been told they are ordinary finds an old letter proving their family is anything but.",
        "A boy terrified of making mistakes is given a day where every mistake he makes becomes someone else's lucky break.",
        "A girl who has moved twelve times in ten years discovers each city left a piece of itself inside her.",
        "A shy inventor builds a robot companion, only for the robot to be more socially anxious than its creator.",
        "A child convinced they are the least interesting person alive learns they are the protagonist of a legend.",
        "A girl who always plays it safe is dared to do one brave thing a day for a week and nothing goes as planned.",
        "A boy who speaks too quietly discovers that silence is exactly the right volume for the secret world he finds.",
        "A child who has been told their ideas are too strange finally finds the place where strange ideas are currency."
    ]
    
    private var displayName: String {
        let name = appState.childName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Creator" : name
    }
    
    private var createComicCost: Int {
        fishCoinManager.storyGenerationCost(for: selectedPageCount)
    }
    
    private var trialRewardBanner: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Trial bonus reminder")
                    .font(AppTheme.fontBold(size: 14))
                    .foregroundStyle(.white)
                Text("You received 100 fish coins for now. The remaining bonus will be added after your trial ends and the subscription renews successfully.")
                    .font(AppTheme.font(size: 12))
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FF9A3D"), Color(hex: "FF4F87")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.black, lineWidth: 2)
                )
        )
        .shadow(color: Color(hex: "FF4F87").opacity(0.28), radius: 16, x: 0, y: 10)
    }

    private var createTabContent: some View {
        VStack(spacing: 0) {
            createStorySection
                .padding(.horizontal, 20)
                .padding(.bottom, 28)

            styleAndFormatSection
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

            storyDetailsSection
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

            advancedSettingsSection
                .padding(.horizontal, 20)
                .padding(.bottom, 28)

            createComicButton
                .padding(.horizontal, 20)
                .padding(.bottom, 28)

            recentStoriesSection
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
        }
    }

    private var historyTabContent: some View {
        historySection
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
    }

    var body: some View {
        ZStack {
            // 背景动画：流星（完全露出）
            LottieView(
                animationName: "Free Background_shooting_star Animation",
                subdirectory: "lottie",
                loopMode: .loop,
                contentMode: .scaleAspectFill,
                speed: 1.0
            )
            .rotationEffect(.degrees(180))
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 顶部设置和创意币区域
                        topProfileCard
                            .padding(.bottom, 20)

                        let shouldShowTrialBanner = PurchaseManager.shared.shouldShowTrialRewardBanner
                        if shouldShowTrialBanner {
                            trialRewardBanner
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                        }
                        
                        // 根据选中的页签显示不同内容
                        if selectedTab == .create {
                            createTabContent
                        } else {
                            historyTabContent
                        }
                    }
                }
                
                // 批量删除悬浮栏（History 选择模式时显示，悬浮在页签上方）
                if selectedTab == .history && isHistorySelectMode {
                    VStack(spacing: 0) {
                        Divider()
                            .background(Color(hex: "FF4444").opacity(0.4))
                        HStack(spacing: 12) {
                            // 已选数量提示
                            Text(selectedHistoryIds.isEmpty ? "No items selected" : "\(selectedHistoryIds.count) selected")
                                .font(AppTheme.font(size: 13))
                                .foregroundStyle(Color(hex: "B0B0B0"))
                            Spacer()
                            // 删除按钮
                            Button(action: {
                                guard !selectedHistoryIds.isEmpty else { return }
                                showDeleteHistoryConfirm = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Delete (\(selectedHistoryIds.count))")
                                        .font(AppTheme.fontBold(size: 14))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedHistoryIds.isEmpty ? Color(hex: "505050") : Color(hex: "FF4444"))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.black, lineWidth: 1.5)
                                        )
                                )
                            }
                            .buttonStyle(ClickSoundButtonStyle())
                            .disabled(selectedHistoryIds.isEmpty)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color(hex: "1A1F2E"))
                    }
                    .alert("Delete Comics?", isPresented: $showDeleteHistoryConfirm) {
                        Button("Cancel", role: .cancel) { }
                        Button("Delete", role: .destructive) {
                            StoryStorage.shared.delete(ids: Array(selectedHistoryIds))
                            recentStories = StoryStorage.shared.loadAll()
                            selectedHistoryIds.removeAll()
                            isHistorySelectMode = false
                        }
                    } message: {
                        Text("Sure to delete \(selectedHistoryIds.count) comic(s)? This cannot be undone.")
                    }
                }

                // 底部悬浮页签
                bottomTabBar
            }
        }
        .onAppear {
            let trialStatusSummary = PurchaseManager.shared.debugTrialStatusSummary
            print("[HomeView] onAppear trial status: \(trialStatusSummary)")
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
                            refreshID = UUID()
                        }
                    }
            }
            if showDailyReward {
                DailyRewardPopupView(
                    isPresented: $showDailyReward,
                    rewardAmount: dailyRewardAmount,
                    rewardTitle: fishCoinManager.currentDailyRewardDescription
                )
                    .zIndex(2000)
                    .onChange(of: showDailyReward) { oldValue, newValue in
                        if !newValue {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                fishCoinBalance = fishCoinManager.balance
                                print("[HomeView] 每日奖励弹窗关闭，刷新余额：\(fishCoinBalance)")
                            }
                        }
                    }
            }
        }
        .overlay {
            if showAddRoleModal {
                AddRoleView(isPresented: $showAddRoleModal, onRoleSaved: { newCharacter in
                    characters = CharacterStorage.shared.loadAll()
                    // 自动应用新创建的角色
                    if appliedCharacters.count < 2 {
                        appliedCharacters.append(newCharacter)
                    }
                })
                    .zIndex(1000)
                    .onChange(of: showAddRoleModal) { oldValue, newValue in
                        if !newValue {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                characters = CharacterStorage.shared.loadAll()
                            }
                        }
                    }
            }
        }
        .overlay {
            if showLoadingScreen {
                LoadingScreenView()
                    .zIndex(2000)
            }
        }
        .overlay {
            if showComicView {
                ComicDisplayView(isPresented: $showComicView, story: selectedStory)
                    .environmentObject(appOB)
                    .zIndex(2000)
                    .onChange(of: showComicView) { oldValue, newValue in
                        if !newValue {
                            // 关闭漫画显示时刷新 history
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                recentStories = StoryStorage.shared.loadAll()
                                selectedStory = nil
                            }
                        }
                    }
            }
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
            if appState.showThankYouToast {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "00D9FF"))
                        Text("Thanks for your feedback!")
                            .font(AppTheme.fontBold(size: 16))
                            .foregroundColor(Color.white)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "1A1F2E"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(hex: "00D9FF"), lineWidth: 1)
                            )
                            .shadow(color: Color(hex: "00D9FF").opacity(0.3), radius: 10, x: 0, y: 5)
                    )
                    .padding(.bottom, 50)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(4000)
            }
        }
        .onChange(of: appState.showFishCoinShop) { oldValue, newValue in
            if !newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    fishCoinBalance = fishCoinManager.balance
                    print("[HomeView] 小鱼干商店关闭，刷新余额：\(fishCoinBalance)")
                }
            }
        }
        .onTapGesture {
            isStoryDetailsFocused = false
        }
        .onAppear {
            print("[HomeView] onAppear")
            setOrientation(.portrait)
            
            fishCoinBalance = fishCoinManager.balance
            characters = CharacterStorage.shared.loadAll()
            recentStories = StoryStorage.shared.loadAll()

            Task {
                await PurchaseManager.shared.refreshSubscriptionTier()
                await MainActor.run {
                    checkDailyReward()
                }
            }
        }
    }
    
    // MARK: - 检查每日奖励
    private func checkDailyReward() {
        if fishCoinManager.shouldShowDailyReward() {
            dailyRewardAmount = fishCoinManager.claimDailyReward()
            fishCoinBalance = fishCoinManager.balance
            AnalyticsManager.track(
                AnalyticsEvent.dailyRewardClaimed,
                properties: [
                    "reward_amount": dailyRewardAmount,
                    "balance_after": fishCoinBalance
                ]
            )
            print("[HomeView] 领取每日奖励后余额：\(fishCoinBalance)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showDailyReward = true
            }
        }
    }
    
    // MARK: - 顶部区域（设置和创意币）
    private var topProfileCard: some View {
        HStack(spacing: 12) {
            Spacer()
            
            // 创意币
            Button(action: {
                print("[HomeView] 点击创意币区域，打开商店")
                AnalyticsManager.track(AnalyticsEvent.fishCoinShopViewed, properties: ["entry": "top_balance"])
                appState.showFishCoinShop = true
            }) {
                HStack(spacing: 8) {
                    Image("fish coin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                    
                    Text("\(fishCoinBalance)")
                        .font(AppTheme.fontBold(size: 16))
                        .foregroundStyle(Color(hex: "00D9FF"))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "1A1F2E"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black, lineWidth: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "00D9FF"), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(ClickSoundButtonStyle())
            
            // 设置
            Button(action: {
                print("[HomeView] 点击设置")
                showSettings = true
            }) {
                Image(systemName: "gear")
                    .font(AppTheme.font(size: 18))
                    .foregroundStyle(Color(hex: "FF1493"))
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "1A1F2E"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(hex: "FF1493"), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(ClickSoundButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
    
    // MARK: - 添加角色按钮区域（有无角色均保持 120 高度）
    private var createStorySection: some View {
        Group {
            if appliedCharacters.isEmpty {
                // 无角色：显示 Add Role 按钮
                Button(action: {
                    print("[HomeView] 点击添加角色按钮")
                    AnalyticsManager.track(AnalyticsEvent.roleCreationStarted, properties: ["entry": "empty_state"])
                    showAddRoleModal = true
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "FF1493"),
                                        Color(hex: "FF69B4"),
                                        Color(hex: "FF1493")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        GeometryReader { geo in
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                    .offset(x: geo.size.width - 40, y: -20)
                                Circle()
                                    .fill(Color(hex: "00D9FF").opacity(0.15))
                                    .frame(width: 60, height: 60)
                                    .offset(x: -20, y: geo.size.height - 30)
                            }
                        }

                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "plus")
                                    .font(AppTheme.font(size: 24))
                                    .foregroundStyle(.white)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Add Role")
                                    .font(AppTheme.fontRowdiesBold(size: 18))
                                    .foregroundStyle(.white)
                                Text("Create your character")
                                    .font(AppTheme.font(size: 11))
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                    }
                    .frame(height: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.black, lineWidth: 4)
                    )
                    .shadow(color: Color(hex: "FF1493").opacity(0.6), radius: 24, x: 0, y: 12)
                }
                .buttonStyle(ClickSoundButtonStyle())
            } else {
                // 有角色：横排展示已选角色，整体高度同样固定 120
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "1A1F2E"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.black, lineWidth: 3)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "FF1493"), lineWidth: 1.5)
                        )

                    HStack(spacing: 12) {
                        ForEach(Array(appliedCharacters.prefix(2).enumerated()), id: \.offset) { index, character in
                            ZStack(alignment: .topTrailing) {
                                HStack(spacing: 10) {
                                    Group {
                                        if let imageUrl = CharacterStorage.shared.getImageUrl(for: character) {
                                            AsyncImage(url: imageUrl) { phase in
                                                switch phase {
                                                case .success(let image):
                                                    image.resizable().scaledToFill()
                                                default:
                                                    Color(hex: "0F1419")
                                                }
                                            }
                                        } else {
                                            Color(hex: "0F1419")
                                                .overlay(
                                                    Image(systemName: "person.fill")
                                                        .foregroundStyle(.white.opacity(0.4))
                                                )
                                        }
                                    }
                                    .frame(width: 56, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color(hex: "FF1493"), lineWidth: 1)
                                    )

                                    Text(character.name)
                                        .font(AppTheme.fontBold(size: 13))
                                        .foregroundStyle(Color.white)
                                        .lineLimit(1)

                                    Spacer()
                                }
                                .padding(.horizontal, 10)
                                .frame(maxWidth: .infinity)
                                .frame(height: 96)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "0F1419"))
                                )

                                Button(action: { appliedCharacters.remove(at: index) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(Color(hex: "FF1493"))
                                }
                                .buttonStyle(ClickSoundButtonStyle())
                                .padding(4)
                            }
                        }

                        if appliedCharacters.count < 2 {
                            Button(action: {
                                AnalyticsManager.track(AnalyticsEvent.roleCreationStarted, properties: ["entry": "applied_characters_card"])
                                showAddRoleModal = true
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 24))
                                        .foregroundStyle(Color(hex: "FF1493").opacity(0.6))
                                    Text("Add")
                                        .font(AppTheme.font(size: 11))
                                        .foregroundStyle(Color(hex: "808080"))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 96)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "0F1419"))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    Color(hex: "FF1493"),
                                                    style: StrokeStyle(lineWidth: 1, dash: [4])
                                                )
                                        )
                                )
                            }
                            .buttonStyle(ClickSoundButtonStyle())
                        }
                    }
                    .padding(12)
                }
                .frame(height: 120)
            }
        }
    }
    
    // MARK: - Style 和 Format 选择区域
    private var styleAndFormatSection: some View {
        VStack(spacing: 10) {
            // Style 选择
            VStack(alignment: .leading, spacing: 6) {
                Text("Style")
                    .font(AppTheme.fontBold(size: 13))
                    .foregroundStyle(Color.white)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(styles.enumerated()), id: \.offset) { index, style in
                            Button(action: {
                                isStoryDetailsFocused = false
                                selectedStyle = style
                            }) {
                                VStack(spacing: 6) {
                                    Image("style\(index + 1)")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.black, lineWidth: 1.5)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedStyle == style ? Color(hex: "FF1493") : Color.clear, lineWidth: 2)
                                        )
                                        .shadow(color: selectedStyle == style ? Color(hex: "FF1493").opacity(0.5) : Color.clear, radius: 6, x: 0, y: 0)
                                    
                                    Text(style)
                                        .font(AppTheme.fontBold(size: 11))
                                        .foregroundStyle(selectedStyle == style ? Color(hex: "FF1493") : Color(hex: "B0B0B0"))
                                        .lineLimit(1)
                                }
                                .frame(width: 70)
                            }
                            .buttonStyle(ClickSoundButtonStyle())
                        }
                    }
                }
            }
            
            // Format 选择
            VStack(alignment: .leading, spacing: 6) {
                Text("Format")
                    .font(AppTheme.fontBold(size: 13))
                    .foregroundStyle(Color.white)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(formats.enumerated()), id: \.offset) { _, format in
                            Button(action: {
                                isStoryDetailsFocused = false
                                selectedFormat = format.name
                                // 根据格式自动设置分镜数量
                                if format.name == "4-Panel" {
                                    selectedQuantity = "4"
                                } else if format.name == "Meme" {
                                    selectedQuantity = "1"
                                }
                            }) {
                                VStack(spacing: 6) {
                                    Image("format\(format.imageIndex)")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.black, lineWidth: 1.5)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedFormat == format.name ? Color(hex: "00D9FF") : Color.clear, lineWidth: 2)
                                        )
                                        .shadow(color: selectedFormat == format.name ? Color(hex: "00D9FF").opacity(0.5) : Color.clear, radius: 6, x: 0, y: 0)
                                    
                                    Text(format.name)
                                        .font(AppTheme.fontBold(size: 11))
                                        .foregroundStyle(selectedFormat == format.name ? Color(hex: "00D9FF") : Color(hex: "B0B0B0"))
                                        .lineLimit(1)
                                }
                                .frame(width: 70)
                            }
                            .buttonStyle(ClickSoundButtonStyle())
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 故事详情区域
    private var storyDetailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Story Details")
                    .font(AppTheme.fontBold(size: 15))
                    .foregroundStyle(Color.white)
                
                Spacer()
                
                Button(action: {
                    isStoryDetailsFocused = false
                    inspireMe()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(AppTheme.font(size: 12))
                        Text("Inspire me")
                            .font(AppTheme.fontBold(size: 12))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "00D9FF"), Color(hex: "0099FF")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black, lineWidth: 1.5)
                            )
                    )
                }
                .buttonStyle(ClickSoundButtonStyle())
            }
            
            TextEditor(text: $storyDetails)
                .font(AppTheme.font(size: 14))
                .foregroundStyle(Color.white)
                .scrollContentBackground(.hidden)
                .focused($isStoryDetailsFocused)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "1A1F2E"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black, lineWidth: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "00D9FF"), lineWidth: 1)
                        )
                )
                .frame(height: 100)
                .padding(.horizontal, 1)
        }
    }
    
    // MARK: - Advanced Settings 区域
    private var advancedSettingsSection: some View {
        VStack(spacing: 0) {
            // Advanced Settings 标题（可展开）
            Button(action: {
                isStoryDetailsFocused = false
                withAnimation(.easeInOut(duration: 0.3)) {
                    showAdvancedSettings.toggle()
                }
            }) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "slider.horizontal.3")
                            .font(AppTheme.font(size: 14))
                            .foregroundStyle(Color(hex: "00D9FF"))
                        Text("Advanced Settings")
                            .font(AppTheme.fontBold(size: 14))
                            .foregroundStyle(Color.white)
                    }
                    
                    Spacer()
                    
                    Image(systemName: showAdvancedSettings ? "chevron.up" : "chevron.down")
                        .font(AppTheme.font(size: 12))
                        .foregroundStyle(Color(hex: "00D9FF"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "1A1F2E"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black, lineWidth: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "00D9FF"), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(ClickSoundButtonStyle())
            
            // 展开内容
            if showAdvancedSettings {
                VStack(spacing: 14) {
                    Divider()
                        .background(Color(hex: "00D9FF").opacity(0.3))
                    
                    // 语言选择
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Language")
                            .font(AppTheme.fontBold(size: 13))
                            .foregroundStyle(Color.white)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(languages, id: \.self) { language in
                                    Button(action: {
                                        isStoryDetailsFocused = false
                                        selectedLanguage = language
                                    }) {
                                        Text(language)
                                            .font(AppTheme.font(size: 11))
                                            .foregroundStyle(selectedLanguage == language ? .white : Color(hex: "B0B0B0"))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(selectedLanguage == language ?
                                                        LinearGradient(
                                                            colors: [Color(hex: "00D9FF"), Color(hex: "0099FF")],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        ) : LinearGradient(
                                                            colors: [Color(hex: "1A1F2E"), Color(hex: "1A1F2E")],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        )
                                                    )
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 6)
                                                            .stroke(Color.black, lineWidth: 1)
                                                    )
                                            )
                                    }
                                    .buttonStyle(ClickSoundButtonStyle())
                                }
                            }
                        }
                    }
                    
                    // 页数选择
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Number of Pages")
                            .font(AppTheme.fontBold(size: 13))
                            .foregroundStyle(Color.white)
                        
                        HStack(spacing: 8) {
                            ForEach(pageCounts, id: \.self) { count in
                                Button(action: {
                                    isStoryDetailsFocused = false
                                    selectedPageCount = count
                                }) {
                                    Text("\(count)")
                                        .font(AppTheme.fontBold(size: 12))
                                        .foregroundStyle(selectedPageCount == count ? .white : Color(hex: "B0B0B0"))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedPageCount == count ?
                                                    LinearGradient(
                                                        colors: [Color(hex: "FF1493"), Color(hex: "FF69B4")],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    ) : LinearGradient(
                                                        colors: [Color(hex: "1A1F2E"), Color(hex: "1A1F2E")],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.black, lineWidth: 1.5)
                                                )
                                        )
                                }
                                .buttonStyle(ClickSoundButtonStyle())
                            }
                        }
                    }
                    
                    // 分镜格数选择
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                        Text("Quantity (Panels)")
                            .font(AppTheme.fontBold(size: 13))
                            .foregroundStyle(Color.white)
                            
                            // 显示固定提示
                            if selectedFormat == "4-Panel" || selectedFormat == "Meme" {
                                Text("(Fixed)")
                                    .font(AppTheme.font(size: 11))
                                    .foregroundStyle(Color(hex: "00D9FF"))
                            }
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(quantities, id: \.self) { quantity in
                                    let isDisabled = (selectedFormat == "4-Panel" && quantity != "4") || 
                                                     (selectedFormat == "Meme" && quantity != "1")
                                    let isFixed = (selectedFormat == "4-Panel" && quantity == "4") || 
                                                  (selectedFormat == "Meme" && quantity == "1")
                                    
                                    Button(action: {
                                        isStoryDetailsFocused = false
                                        if !isDisabled {
                                            selectedQuantity = quantity
                                        }
                                    }) {
                                        Text(quantity)
                                            .font(AppTheme.fontBold(size: 11))
                                            .foregroundStyle(
                                                isDisabled ? Color(hex: "505050") :
                                                selectedQuantity == quantity ? .white : Color(hex: "B0B0B0")
                                            )
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(
                                                        isDisabled ? LinearGradient(
                                                            colors: [Color(hex: "0A0A0A"), Color(hex: "0A0A0A")],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        ) : (selectedQuantity == quantity ?
                                                        LinearGradient(
                                                            colors: [Color(hex: "00D9FF"), Color(hex: "0099FF")],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        ) : LinearGradient(
                                                            colors: [Color(hex: "1A1F2E"), Color(hex: "1A1F2E")],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                            )
                                                        )
                                                    )
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 6)
                                                            .stroke(Color.black, lineWidth: 1)
                                                    )
                                                    .overlay(
                                                        isFixed ? RoundedRectangle(cornerRadius: 6)
                                                            .stroke(Color(hex: "00D9FF"), lineWidth: 1.5) : nil
                                                    )
                                            )
                                    }
                                    .buttonStyle(ClickSoundButtonStyle())
                                    .disabled(isDisabled)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "0F1419"))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    // MARK: - Create Comic 按钮
    private var createComicButton: some View {
        Button(action: { validateAndCreate() }) {
            HStack(spacing: 10) {
                Text("Create Comic")
                    .font(AppTheme.fontBold(size: 16))
                    .foregroundStyle(.white)

                Spacer()

                HStack(spacing: 6) {
                    Image("fish coin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                    Text("\(createComicCost)")
                        .font(AppTheme.fontBold(size: 15))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.16), in: Capsule())
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FF1493"), Color(hex: "FF69B4")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(ClickSoundButtonStyle())
        .alert("Missing Information", isPresented: $showValidationAlert) {
            Button("OK") { }
        } message: {
            Text(validationMessage)
        }
    }
    
    // MARK: - 角色库区域
    private var recentStoriesSection: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .font(AppTheme.font(size: 18))
                        .foregroundStyle(Color(hex: "00D9FF"))
                    Text("Your Roles")
                        .font(AppTheme.fontBold(size: 20))
                        .foregroundStyle(Color.white)
                }
                
                Spacer()
            }
            
            if characters.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(AppTheme.font(size: 48))
                        .foregroundStyle(Color(hex: "00D9FF").opacity(0.5))
                    
                    Text("No Roles Yet")
                        .font(AppTheme.fontBold(size: 17))
                        .foregroundStyle(Color.white)
                    
                    Text("Create your first role above!")
                        .font(AppTheme.font(size: 13))
                        .foregroundStyle(Color(hex: "A0A0A0"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "1A1F2E"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.black, lineWidth: 3)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: "00D9FF").opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                        )
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(characters) { character in
                        ZStack {
                            RoleCard(character: character) {
                                // 点击角色时应用到顶部
                                if !appliedCharacters.contains(where: { $0.id == character.id }) {
                                    if appliedCharacters.count < 2 {
                                        appliedCharacters.append(character)
                                        print("[HomeView] 应用角色：\(character.name)")
                                    }
                                }
                            } onDelete: {
                                CharacterStorage.shared.delete(id: character.id)
                                characters = CharacterStorage.shared.loadAll()
                                // 如果删除的角色在应用列表中，也要移除
                                appliedCharacters.removeAll { $0.id == character.id }
                            }

                            // 已应用标记：垂直居中，贴右侧
                            if appliedCharacters.contains(where: { $0.id == character.id }) {
                                HStack {
                                    Spacer()
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(hex: "FF1493"), Color(hex: "FF69B4")],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 28, height: 28)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.black, lineWidth: 1.5)
                                                    .frame(width: 28, height: 28)
                                            )
                                        Image(systemName: "checkmark")
                                            .font(AppTheme.fontBold(size: 12))
                                            .foregroundStyle(.white)
                                    }
                                    .padding(.trailing, 54) // 避开右侧删除按钮
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - History 页签内容
    private var historySection: some View {
        VStack(spacing: 16) {
            // 标题栏
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(AppTheme.font(size: 18))
                        .foregroundStyle(Color(hex: "FF1493"))
                    Text("History")
                        .font(AppTheme.fontBold(size: 20))
                        .foregroundStyle(Color.white)
                }
                Spacer()
                if !recentStories.isEmpty {
                    if isHistorySelectMode {
                        // 选择模式：全选 + 取消
                        HStack(spacing: 12) {
                            Button(action: {
                                if selectedHistoryIds.count == recentStories.count {
                                    selectedHistoryIds.removeAll()
                                } else {
                                    selectedHistoryIds = Set(recentStories.map { $0.id })
                                }
                            }) {
                                Text(selectedHistoryIds.count == recentStories.count ? "Deselect All" : "Select All")
                                    .font(AppTheme.font(size: 13))
                                    .foregroundStyle(Color(hex: "00D9FF"))
                            }
                            .buttonStyle(ClickSoundButtonStyle())

                            Button(action: {
                                isHistorySelectMode = false
                                selectedHistoryIds.removeAll()
                            }) {
                                Text("Cancel")
                                    .font(AppTheme.fontBold(size: 13))
                                    .foregroundStyle(Color(hex: "FF1493"))
                            }
                            .buttonStyle(ClickSoundButtonStyle())
                        }
                    } else {
                        Button(action: { isHistorySelectMode = true }) {
                            Text("Select")
                                .font(AppTheme.fontBold(size: 14))
                                .foregroundStyle(Color(hex: "00D9FF"))
                        }
                        .buttonStyle(ClickSoundButtonStyle())
                    }
                }
            }
            .padding(.top, 20)

            if recentStories.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "book.closed.fill")
                        .font(AppTheme.font(size: 48))
                        .foregroundStyle(Color(hex: "FF1493").opacity(0.5))
                    Text("No Comics Yet")
                        .font(AppTheme.fontBold(size: 17))
                        .foregroundStyle(Color.white)
                    Text("Create your first comic to see it here!")
                        .font(AppTheme.font(size: 13))
                        .foregroundStyle(Color(hex: "A0A0A0"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "1A1F2E"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.black, lineWidth: 3)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: "FF1493").opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                        )
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(recentStories) { story in
                        HStack(spacing: 10) {
                            // 选择模式复选框
                            if isHistorySelectMode {
                                Button(action: {
                                    if selectedHistoryIds.contains(story.id) {
                                        selectedHistoryIds.remove(story.id)
                                    } else {
                                        selectedHistoryIds.insert(story.id)
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(selectedHistoryIds.contains(story.id) ? Color(hex: "FF1493") : Color(hex: "1A1F2E"))
                                            .frame(width: 26, height: 26)
                                            .overlay(
                                                Circle().stroke(
                                                    selectedHistoryIds.contains(story.id) ? Color(hex: "FF1493") : Color(hex: "505050"),
                                                    lineWidth: 2
                                                )
                                            )
                                        if selectedHistoryIds.contains(story.id) {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                }
                                .buttonStyle(ClickSoundButtonStyle())
                            }

                            ComicStoryRowButton(story: story) {
                                if isHistorySelectMode {
                                    if selectedHistoryIds.contains(story.id) {
                                        selectedHistoryIds.remove(story.id)
                                    } else {
                                        selectedHistoryIds.insert(story.id)
                                    }
                                } else {
                                    print("[HomeView] 点击历史故事：\(story.theme)")
                                    selectedStory = story
                                    showComicView = true
                                }
                            }
                        }
                    }
                }

                // 批量删除按钮已移至底部悬浮栏
            }
        }
    }
    
    // MARK: - 底部悬浮页签
    private var bottomTabBar: some View {
        HStack(spacing: 0) {
            // Create 页签
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = .create
                }
            }) {
                VStack(spacing: 6) {
                    Image(systemName: selectedTab == .create ? "plus.circle.fill" : "plus.circle")
                        .font(AppTheme.font(size: 24))
                        .foregroundStyle(selectedTab == .create ? Color(hex: "FF1493") : Color(hex: "808080"))
                    
                    Text("Create")
                        .font(AppTheme.fontBold(size: 12))
                        .foregroundStyle(selectedTab == .create ? Color(hex: "FF1493") : Color(hex: "808080"))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .contentShape(Rectangle())
                .background(
                    selectedTab == .create ?
                    LinearGradient(
                        colors: [Color(hex: "FF1493").opacity(0.15), Color(hex: "FF69B4").opacity(0.15)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) : LinearGradient(
                        colors: [Color.clear, Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // History 页签
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = .history
                }
            }) {
                VStack(spacing: 6) {
                    Image(systemName: selectedTab == .history ? "clock.fill" : "clock")
                        .font(AppTheme.font(size: 24))
                        .foregroundStyle(selectedTab == .history ? Color(hex: "00D9FF") : Color(hex: "808080"))
                    
                    Text("History")
                        .font(AppTheme.fontBold(size: 12))
                        .foregroundStyle(selectedTab == .history ? Color(hex: "00D9FF") : Color(hex: "808080"))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .contentShape(Rectangle())
                .background(
                    selectedTab == .history ?
                    LinearGradient(
                        colors: [Color(hex: "00D9FF").opacity(0.15), Color(hex: "0099FF").opacity(0.15)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) : LinearGradient(
                        colors: [Color.clear, Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(
            Rectangle()
                .fill(Color(hex: "1A1F2E"))
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.black.opacity(0.3), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 1),
                    alignment: .top
                )
                .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: -5)
        )
        .overlay(
            Rectangle()
                .stroke(Color.black, lineWidth: 2),
            alignment: .top
        )
    }
    
    private func inspireMe() {
        if let randomInspiration = inspirationExamples.randomElement() {
            storyDetails = randomInspiration
        }
    }
    
    private func validateAndCreate() {
        // 点击生成后立即收起输入法
        isStoryDetailsFocused = false

        let trimmedDetails = storyDetails.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedDetails.isEmpty {
            validationMessage = "Please fill in the story details before creating a comic."
            showValidationAlert = true
            return
        }
        
        let generationImageCount = selectedPageCount
        let generationCost = fishCoinManager.storyGenerationCost(for: generationImageCount)
        let quantity: Int
        if selectedFormat == "Meme" {
            quantity = 1
        } else if selectedFormat == "4-Panel" {
            quantity = 4
        } else {
            quantity = parseQuantity(selectedQuantity)
        }

        AnalyticsManager.track(
            AnalyticsEvent.storyGenerationStarted,
            properties: [
                "style": selectedStyle,
                "format": selectedFormat,
                "language": selectedLanguage,
                "image_count": selectedPageCount,
                "panel_count": quantity,
                "has_character": !appliedCharacters.isEmpty,
                "fish_coin_cost": generationCost
            ]
        )

        // 检查小鱼干余额
        if !fishCoinManager.canGenerateStory(imageCount: generationImageCount) {
            validationMessage = "Not enough fish coins. Creating \(generationImageCount) image(s) costs \(generationCost) fish coins."
            showValidationAlert = true
            return
        }

        // 扣除本次生成所需小鱼干
        guard fishCoinManager.consumeForStoryGeneration(imageCount: generationImageCount) else {
            validationMessage = "Failed to consume fish coins. Please try again."
            showValidationAlert = true
            return
        }

        // 所有验证通过，先清理上一次展示状态，再显示 loading 屏幕
        let selectedCharacter = appliedCharacters.first
        print("[HomeView] 开始生成漫画")
        if let selectedCharacter {
            print("[HomeView] 应用的角色：\(selectedCharacter.name)")
        } else {
            print("[HomeView] 本次未选择角色，将使用无角色模式生成漫画")
        }
        print("[HomeView] 选择的风格：\(selectedStyle)")
        print("[HomeView] 选择的格式：\(selectedFormat)")
        print("[HomeView] 选择的语言：\(selectedLanguage)")
        print("[HomeView] 选择的页数：\(selectedPageCount)")
        print("[HomeView] 分镜格数：\(selectedQuantity)")
        print("[HomeView] 故事详情：\(trimmedDetails)")

        // 避免复用历史故事导致直接弹旧图
        selectedStory = nil
        showComicView = false
        showLoadingScreen = true

        let storyRequest = GenerateStoryRequest(
            theme: trimmedDetails,
            style: styleToBackendCode(selectedStyle),
            quantity: quantity,
            language: selectedLanguage,
            visualAnchor: selectedCharacter?.description,
            characterName: selectedCharacter?.name,
            variantsCount: selectedPageCount
        )
        
        print("[HomeView] 构建故事生成请求完成")
        print("[HomeView] ========== 请求参数详情 ==========")
        print("[HomeView] theme: \(trimmedDetails)")
        print("[HomeView] style: \(storyRequest.style)")
        print("[HomeView] quantity (分镜格数): \(quantity)")
        print("[HomeView] language: \(selectedLanguage)")
        print("[HomeView] characterName: \(storyRequest.characterName)")
        print("[HomeView] variantsCount (页数): \(selectedPageCount)")
        print("[HomeView] ================================")
        
        let characterImageUrl: String? = selectedCharacter.flatMap {
            CharacterStorage.shared.getImageUrl(for: $0)?.absoluteString
        }
        
        // 调用完整的漫画生成流程
        ComicAPIService.shared.generateFullComic(
            storyRequest: storyRequest,
            characterImageUrl: characterImageUrl,
            format: formatToBackendCode(selectedFormat)
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let generationResult):
                    print("[HomeView] 漫画生成成功: \(generationResult.imageUrls.joined(separator: ","))")
                    
                    let imageUrls = generationResult.imageUrls
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    let imagePrompts = generationResult.panels
                        .sorted { $0.panelIndex < $1.panelIndex }
                        .map(\.imagePrompt)
                    print("[HomeView] 解析得到 \(imageUrls.count) 张图片")
                    
                    guard imageUrls.count == selectedPageCount else {
                        print("[HomeView] 图片张数异常，期望 \(selectedPageCount) 张，实际 \(imageUrls.count) 张")
                        AnalyticsManager.track(
                            AnalyticsEvent.storyGenerationFailed,
                            properties: [
                                "reason": "image_count_mismatch",
                                "expected_image_count": selectedPageCount,
                                "actual_image_count": imageUrls.count,
                                "style": selectedStyle,
                                "format": selectedFormat,
                                "language": selectedLanguage,
                                "panel_count": quantity
                            ]
                        )
                        fishCoinManager.refundForFailedGeneration(imageCount: selectedPageCount)
                        showLoadingScreen = false
                        validationMessage = "Failed to generate the full comic. Expected \(selectedPageCount) image(s), but received \(imageUrls.count). Please try again."
                        showValidationAlert = true
                        return
                    }
                    
                    // 为每张图片创建一个 StoryPage
                    let storyPages = imageUrls.enumerated().map { index, imageUrl in
                        StoryPage(
                            text: index == 0 ? trimmedDetails : "",
                            imageUrl: imageUrl,
                            imagePrompt: imagePrompts.isEmpty ? nil : imagePrompts[min(index, imagePrompts.count - 1)]
                        )
                    }
                    
                    // 保存到本地存储
                    let savedStory = StoryStorage.shared.save(theme: trimmedDetails, pages: storyPages)
                    AnalyticsManager.track(
                        AnalyticsEvent.storyGenerationSucceeded,
                        properties: [
                            "style": selectedStyle,
                            "format": selectedFormat,
                            "language": selectedLanguage,
                            "image_count": selectedPageCount,
                            "panel_count": quantity,
                            "has_character": selectedCharacter != nil,
                            "story_id": savedStory.id.uuidString
                        ]
                    )
                    
                    // 立即预下载所有漫画图片到本地缓存
                    print("[HomeView] 开始预下载 \(imageUrls.count) 张漫画图片到本地")
                    let urlsToPreload = imageUrls.compactMap { urlString -> URL? in
                        URL(string: urlString.trimmingCharacters(in: .whitespaces))
                    }
                    
                    Task {
                        await ImageCache.shared.preloadImages(urls: urlsToPreload)
                        print("[HomeView] 所有漫画图片预下载完成")
                    }
                    
                    // 刷新 history 列表
                    recentStories = StoryStorage.shared.loadAll()

                    // 指向本次新生成的故事，避免展示到历史首条
                    selectedStory = savedStory

                    // 关闭 loading 屏幕，显示漫画
                    showLoadingScreen = false
                    showComicView = true
                    
                case .failure(let error):
                    print("[HomeView] 漫画生成失败: \(error.localizedDescription)")
                    AnalyticsManager.track(
                        AnalyticsEvent.storyGenerationFailed,
                        properties: [
                            "reason": error.localizedDescription,
                            "style": selectedStyle,
                            "format": selectedFormat,
                            "language": selectedLanguage,
                            "image_count": selectedPageCount,
                            "panel_count": quantity,
                            "has_character": selectedCharacter != nil
                        ]
                    )
                    fishCoinManager.refundForFailedGeneration(imageCount: selectedPageCount)
                    showLoadingScreen = false
                    validationMessage = "Failed to generate comic: \(error.localizedDescription)"
                    showValidationAlert = true
                }
            }
        }
    }
    
    private func setOrientation(_ orientation: UIInterfaceOrientationMask) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first
        else { return }
        
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
    }
}

// MARK: - 漫画故事行按钮（首页专用）
private struct ComicStoryRowButton: View {
    let story: SavedStory
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
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
                                        colors: [Color(hex: "FF1493"), Color(hex: "00D9FF")],
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
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black, lineWidth: 2.5)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "FF1493"), lineWidth: 1)
                        )
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "FF1493"), Color(hex: "00D9FF")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                            .overlay(
                                Image(systemName: "sparkles")
                                    .font(AppTheme.font(size: 28))
                                    .foregroundStyle(.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black, lineWidth: 2.5)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "FF1493"), lineWidth: 1)
                            )
                    }
                }
                .shadow(color: Color(hex: "FF1493").opacity(0.4), radius: 8, x: 0, y: 3)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(story.theme)
                        .font(AppTheme.fontBold(size: 16))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                    
                    Text(story.previewText)
                        .font(AppTheme.font(size: 13))
                        .foregroundStyle(Color(hex: "B0B0B0"))
                        .lineLimit(2)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(AppTheme.font(size: 10))
                        Text(story.formattedDate)
                            .font(AppTheme.font(size: 11))
                    }
                    .foregroundStyle(Color(hex: "808080"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "chevron.right")
                    .font(AppTheme.font(size: 16))
                    .foregroundStyle(Color(hex: "00D9FF"))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "1A1F2E"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.black, lineWidth: 3)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(hex: "FF1493"), lineWidth: 1.5)
                    )
                    .shadow(color: Color(hex: "FF1493").opacity(0.3), radius: 8, x: 0, y: 3)
            )
        }
        .buttonStyle(ClickSoundButtonStyle())
    }
}

#Preview {
    HomeView()
        .environment(AppState.shared)
}
