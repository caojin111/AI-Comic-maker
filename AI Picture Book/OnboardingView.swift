//
//  OnboardingView.swift
//  AI Picture Book
//
//  OB 第 1、2、3、4 页
//

import SwiftUI
import Lottie

// MARK: - OB 返回按钮（Lottie：首帧静止，点击播一次后执行返回）

private struct OBBackButtonLottieView: View {
    let action: () -> Void

    var body: some View {
        OBBackButtonLottieRepresentable(action: action)
            .frame(width: 88, height: 88)
    }
}

private struct OBBackButtonLottieRepresentable: UIViewRepresentable {
    let action: () -> Void

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        let url = Bundle.main.url(forResource: "back-button-animation_7516382", withExtension: "json", subdirectory: "lottie")
            ?? Bundle.main.url(forResource: "back-button-animation_7516382", withExtension: "json")
        guard let resolvedURL = url,
              let animation = LottieAnimation.filepath(resolvedURL.path) else {
            print("[OBBackButtonLottie] 未找到 back-button-animation_7516382.json")
            return container
        }
        let animationView = LottieAnimationView(animation: animation)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .playOnce
        animationView.animationSpeed = 4.0
        animationView.currentProgress = 0
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: container.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.didTap))
        container.addGestureRecognizer(tap)
        container.isUserInteractionEnabled = true
        context.coordinator.animationView = animationView
        context.coordinator.action = action
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.action = action
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    final class Coordinator: NSObject {
        var action: () -> Void
        weak var animationView: LottieAnimationView?
        var isAnimating = false

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func didTap() {
            guard let animationView = animationView else { return }
            if isAnimating { return }
            isAnimating = true
            AppSoundManager.shared.playClick()
            animationView.play { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.isAnimating = false
                    self.action()
                }
            }
        }
    }
}

// MARK: - OB 进度条

struct OBProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    private var progress: CGFloat {
        guard totalSteps > 0 else { return 0 }
        return CGFloat(currentStep) / CGFloat(totalSteps)
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 999)
                    .fill(Color.black.opacity(0.2))
                
                RoundedRectangle(cornerRadius: 999)
                    .fill(AppTheme.primary)
                    .frame(width: geo.size.width * progress)
            }
        }
        .frame(height: 16)
    }
}

// MARK: - OB 主按钮

struct OBPrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.font(size: 23))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(AppTheme.primary, in: Capsule())
        }
        .buttonStyle(ClickSoundButtonStyle())
    }
}

// MARK: - OB Get Started 页：展示 AI + 儿童绘本结合与好处

struct OBGetStartedContent: View {
    @Environment(AppState.self) private var appState
    var body: some View {
        VStack(spacing: 24) {
            Text("AI meets children's picture books")
                .font(AppTheme.fontBold(size: 28))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
            
            Text("Personalized stories powered by AI help spark imagination, build early literacy, and create moments you and your child will love.")
                .font(AppTheme.font(size: 16))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
            
            Spacer()
            OBPrimaryButton(title: "Get Started") {
                print("[OBGetStartedContent] Get Started tapped, go to team intro")
                appState.nextOnboardingPage()
            }
        }
        .padding(.top, 400)
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
    }
}

// MARK: - OB 各页「仅内容」视图（供 OBFlowContainer 翻页用，背景与顶栏不重置）

struct OBTeamIntroContent: View {
    @Environment(AppState.self) private var appState
    var body: some View {
        VStack(spacing: 24) {
            LottieView(
                animationName: "cat-family-animation_4822899",
                subdirectory: "lottie",
                contentMode: .scaleAspectFit
            )
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            
            Text("Let's learn about your team!")
                .font(AppTheme.fontBold(size: 32))
                .foregroundStyle(AppTheme.textOnLight)
                .multilineTextAlignment(.center)
            
            Text("So glad you're here! We'll get to know you and your child to personalize your journey.")
                .font(AppTheme.font(size: 16))
                .foregroundStyle(AppTheme.obBodyText)
                .multilineTextAlignment(.center)
            
            Spacer()
            OBPrimaryButton(title: "Continue") { appState.requestOBNextPage() }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
    }
}

struct OBTeamIntroPage: View {
    var body: some View {
        OBPageLayout(currentStep: 2, totalSteps: 11, showBackButton: true) { OBTeamIntroContent() }
    }
}

// MARK: - OB 第 2 页：年龄

struct OBAgeContent: View {
    @Environment(AppState.self) private var appState
    @State private var selectedAge: ChildAge?
    var body: some View {
        VStack(spacing: 32) {
            (Text("How old").font(AppTheme.fontRowdiesBold(size: 28)).foregroundStyle(AppTheme.obHighlightColor) + Text(" is your child?").font(AppTheme.fontBold(size: 28)).foregroundStyle(AppTheme.textOnLight))
                .multilineTextAlignment(.center)
                .padding(.top, 24)
            VStack(spacing: 16) {
                ForEach(ChildAge.allCases, id: \.self) { age in
                    OBSelectableRow(title: age.rawValue, isSelected: selectedAge == age) {
                        selectedAge = age
                        appState.childAge = age
                        appState.requestOBNextPage()
                    }
                }
            }
            Spacer()
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 32)
    }
}

struct OBAgePage: View {
    var body: some View {
        OBPageLayout(currentStep: 3, totalSteps: 11) { OBAgeContent() }
    }
}

// MARK: - OB Age Motivation 页：根据年龄显示不同激励文案

struct OBAgeMotivationContent: View {
    @Environment(AppState.self) private var appState
    private var motivationText: String {
        guard let age = appState.childAge else { return "Let's start the journey!" }
        switch age {
        case .under3: return "Perfect time to spark imagination and early learning!"
        case .age3_5: return "Great age for storytelling adventures and creativity!"
        case .age6_7: return "Ready for exciting stories and reading exploration!"
        case .age8Plus: return "Time for engaging stories that inspire and challenge!"
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)
            // 动画 1.5 倍 + 靠左；动画与文案整体向左下区域居中（上留白多、下留白少）
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .top, spacing: 0) {
                    LottieView(
                        animationName: "podcast-cat-animation_13849649",
                        subdirectory: "lottie",
                        contentMode: .scaleAspectFit
                    )
                    .frame(width: 300, height: 300, alignment: .topLeading)
                    Spacer(minLength: 0)
                }
                Text(motivationText)
                    .font(AppTheme.fontBold(size: 24))
                    .foregroundStyle(AppTheme.obBodyText)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 24)
            OBPrimaryButton(title: "Continue") { appState.requestOBNextPage() }
                .padding(.bottom, 32)
        }
        .padding(.horizontal, 32)
    }
}

struct OBAgeMotivationPage: View {
    var body: some View {
        OBPageLayout(currentStep: 4, totalSteps: 11) { OBAgeMotivationContent() }
    }
}

// MARK: - OB 第 3 页：性别

struct OBGenderContent: View {
    @Environment(AppState.self) private var appState
    @State private var selectedGender: ChildGender?
    var body: some View {
        VStack(spacing: 32) {
            (Text("What is your child's ").font(AppTheme.fontBold(size: 28)).foregroundStyle(AppTheme.textOnLight) + Text("gender").font(AppTheme.fontRowdiesBold(size: 28)).foregroundStyle(AppTheme.obHighlightColor) + Text("?").font(AppTheme.fontBold(size: 28)).foregroundStyle(AppTheme.textOnLight))
                .multilineTextAlignment(.center)
                .padding(.top, 24)
            HStack(spacing: 16) {
                OBGenderCard(title: "Boy", icon: "person.fill", iconColor: Color(hex: "4ECDC4"), lottieAnimationName: "kid-waving-hand-animation_4805793", isSelected: selectedGender == .boy) {
                    selectedGender = .boy
                    appState.childGender = .boy
                    appState.requestOBNextPage()
                }
                OBGenderCard(title: "Girl", icon: "heart.fill", iconColor: Color(hex: "FF6B9D"), lottieAnimationName: "little-girl-animation_4805795", isSelected: selectedGender == .girl) {
                    selectedGender = .girl
                    appState.childGender = .girl
                    appState.requestOBNextPage()
                }
            }
            Spacer()
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 32)
    }
}

struct OBGenderPage: View {
    var body: some View {
        OBPageLayout(currentStep: 5, totalSteps: 11) { OBGenderContent() }
    }
}

// MARK: - OB 第 4 页：头像

struct OBAvatarContent: View {
    @Environment(AppState.self) private var appState
    @State private var selectedAvatar: AvatarOption?
    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
    var body: some View {
        VStack(spacing: 32) {
            (Text("Choose your child's ").font(AppTheme.fontBold(size: 28)).foregroundStyle(AppTheme.textOnLight) + Text("avatar").font(AppTheme.fontRowdiesBold(size: 28)).foregroundStyle(AppTheme.obHighlightColor))
                .multilineTextAlignment(.center)
                .padding(.top, 24)
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(AvatarOption.allCases, id: \.self) { avatar in
                    OBAvatarCell(avatar: avatar, isSelected: selectedAvatar == avatar) {
                        selectedAvatar = avatar
                        appState.childAvatar = avatar
                        appState.requestOBNextPage()
                    }
                }
            }
            .frame(height: 230)
            Spacer()
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 32)
    }
}

struct OBAvatarPage: View {
    var body: some View {
        OBPageLayout(currentStep: 6, totalSteps: 11) { OBAvatarContent() }
    }
}

// MARK: - OB 第 5 页：名字

struct OBNameContent: View {
    @Environment(AppState.self) private var appState
    @State private var nameText: String = ""
    var body: some View {
        VStack(spacing: 32) {
            (Text("Your child's ").font(AppTheme.fontBold(size: 28)).foregroundStyle(AppTheme.textOnLight) + Text("name").font(AppTheme.fontRowdiesBold(size: 28)).foregroundStyle(AppTheme.obHighlightColor))
                .multilineTextAlignment(.center)
                .padding(.top, 24)
            TextField("Child's first name or nickname", text: $nameText)
                .font(AppTheme.font(size: 16))
                .foregroundStyle(AppTheme.obBodyText)
                .padding(.horizontal, 20)
                .frame(height: 56)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 24))
                .shadow(color: AppTheme.shadowColor, radius: 12, x: 0, y: 2)
                .colorScheme(.light)
            Text("We never share or sell any information!")
                .font(AppTheme.font(size: 13))
                .foregroundStyle(AppTheme.obBodyText)
                .multilineTextAlignment(.center)
            Spacer()
            OBPrimaryButton(title: "Continue") {
                appState.childName = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { appState.requestOBNextPage() }
            }
            .disabled(nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 32)
    }
}

struct OBNamePage: View {
    var body: some View {
        OBPageLayout(currentStep: 7, totalSteps: 11) { OBNameContent() }
    }
}

// MARK: - OB Name Motivation 页：Get ready for x's reading journey!

struct OBNameMotivationContent: View {
    @Environment(AppState.self) private var appState
    private var childName: String {
        let name = appState.childName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "your child" : name
    }
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack(spacing: 24) {
                Image("reading journey")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .scaleEffect(1.5)
                    .offset(y: -30)
                
                HStack(spacing: 12) {
                    if let avatar = appState.childAvatar {
                        ZStack {
                            Circle()
                                .fill(Color(hex: avatar.color))
                            LottieView(
                                animationName: avatar.lottieAnimationName,
                                subdirectory: "lottie",
                                contentMode: .scaleAspectFit
                            )
                            .frame(width: 67, height: 67)
                        }
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(AppTheme.secondary.opacity(0.6))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "face.smiling")
                                    .font(AppTheme.font(size: 24))
                                    .foregroundStyle(AppTheme.textOnLight)
                            )
                    }
                    Text(childName)
                        .font(AppTheme.fontBold(size: 24))
                        .foregroundStyle(AppTheme.textOnLight)
                }
                
                Text("Get ready for \(childName)'s reading journey!")
                    .font(AppTheme.fontBold(size: 26))
                    .foregroundStyle(AppTheme.textOnLight)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.top, 56)
            Spacer(minLength: 0)
            OBPrimaryButton(title: "Continue") { appState.requestOBNextPage() }
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 32)
    }
}

struct OBNameMotivationPage: View {
    var body: some View {
        OBPageLayout(currentStep: 8, totalSteps: 11) { OBNameMotivationContent() }
    }
}

// MARK: - OB 第 6 页：Who are you to (child name)?

struct OBRelationshipContent: View {
    @Environment(AppState.self) private var appState
    @State private var selectedRelationship: ChildRelationship?
    private var childName: String {
        let name = appState.childName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "your child" : name
    }
    var body: some View {
        VStack(spacing: 32) {
            Text("Who are you to \(childName)?")
                .font(AppTheme.fontBold(size: 28))
                .foregroundStyle(AppTheme.textOnLight)
                .multilineTextAlignment(.center)
                .padding(.top, 24)
            VStack(spacing: 16) {
                ForEach(ChildRelationship.allCases, id: \.self) { rel in
                    OBSelectableRow(title: rel.rawValue, isSelected: selectedRelationship == rel) {
                        selectedRelationship = rel
                        appState.childRelationship = rel
                        appState.requestOBNextPage()
                    }
                }
            }
            Spacer()
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 32)
    }
}

struct OBRelationshipPage: View {
    var body: some View {
        OBPageLayout(currentStep: 9, totalSteps: 11) { OBRelationshipContent() }
    }
}

// MARK: - OB Relationship Motivation 页：展示大人和小孩图标，文案 x and x

struct OBRelationshipMotivationContent: View {
    @Environment(AppState.self) private var appState
    /// 0=初始(左右场外) 1=几乎重叠(80%) 2=最终(重叠10%)
    @State private var avatarPhase: Int = 0
    @State private var showFirework: Bool = false
    /// 入场动画开始前隐藏头像，避免翻页时穿帮
    @State private var avatarsVisible: Bool = false
    /// 头像移动完成后才显示 x and y 文案
    @State private var showXAndYText: Bool = false

    private var childName: String {
        let name = appState.childName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "your child" : name
    }
    private var relationshipText: String {
        guard let rel = appState.childRelationship else { return "Parent" }
        return rel.rawValue
    }
    private let avatarCircleSize: CGFloat = 80
    private var childLottieSize: CGFloat { avatarCircleSize * 1.2 }

    private var parentOffsetX: CGFloat {
        switch avatarPhase {
        case 0: return -350
        case 1: return 48
        case 2: return 20
        default: return 20
        }
    }
    private var childOffsetX: CGFloat {
        switch avatarPhase {
        case 0: return 350
        case 1: return -48
        case 2: return -20
        default: return -20
        }
    }

    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            VStack(spacing: 2) {
            ZStack(alignment: .center) {
                if showFirework {
                    LottieView(
                        animationName: "firework-animation_6102770",
                        subdirectory: "lottie",
                        contentMode: .scaleAspectFit
                    )
                    .frame(width: 200, height: 120)
                    .offset(y: -70)
                    .allowsHitTesting(false)
                }
                HStack(spacing: 32) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                        Image("fullbody")
                            .resizable()
                            .scaledToFill()
                            .frame(width: avatarCircleSize / 1.8, height: avatarCircleSize / 1.8)
                    }
                    .frame(width: avatarCircleSize, height: avatarCircleSize)
                    .clipShape(Circle())
                    .offset(x: parentOffsetX)
                    .opacity(avatarsVisible ? 1 : 0)
                    if let avatar = appState.childAvatar {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                            LottieView(
                                animationName: avatar.lottieAnimationName,
                                subdirectory: "lottie",
                                contentMode: .scaleAspectFit
                            )
                            .frame(width: childLottieSize, height: childLottieSize)
                        }
                        .frame(width: avatarCircleSize, height: avatarCircleSize)
                        .clipShape(Circle())
                        .offset(x: childOffsetX)
                        .opacity(avatarsVisible ? 1 : 0)
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                            Image(systemName: "face.smiling")
                                .font(AppTheme.font(size: 40))
                                .foregroundStyle(Color(hex: "FF6B9D"))
                        }
                        .frame(width: avatarCircleSize, height: avatarCircleSize)
                        .offset(x: childOffsetX)
                        .opacity(avatarsVisible ? 1 : 0)
                    }
                }
            }
            .frame(height: 120)
            .onAppear {
                guard avatarPhase == 0 else { return }
                let pageFlipDuration: TimeInterval = 0.45
                DispatchQueue.main.asyncAfter(deadline: .now() + pageFlipDuration) {
                    avatarsVisible = true
                    withAnimation(.easeIn(duration: 0.7)) {
                        avatarPhase = 1
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + pageFlipDuration + 0.75) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        avatarPhase = 2
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + pageFlipDuration + 1.3) {
                    showFirework = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + pageFlipDuration + 0.75 + 0.5) {
                    showXAndYText = true
                }
            }
            Text("\(relationshipText) and \(childName)")
                .font(AppTheme.fontBold(size: 14))
                .foregroundStyle(AppTheme.textOnLight)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(hex: "F0EDF8"), in: RoundedRectangle(cornerRadius: 8))
                .scaleEffect(showXAndYText ? 1 : 0.3)
                .opacity(showXAndYText ? 1 : 0)
                .animation(.spring(response: 0.45, dampingFraction: 0.65), value: showXAndYText)
            }
            Text("What a team!!\nWe're rooting for you.")
                .font(AppTheme.fontBold(size: 22))
                .foregroundStyle(AppTheme.textOnLight)
                .multilineTextAlignment(.center)
            Text("Now let's set you and \(childName) up for success!")
                .font(AppTheme.font(size: 16))
                .foregroundStyle(AppTheme.obBodyText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer()
            OBPrimaryButton(title: "Continue") { appState.requestOBNextPage() }
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 32)
    }
}

struct OBRelationshipMotivationPage: View {
    var body: some View {
        OBPageLayout(currentStep: 10, totalSteps: 11) { OBRelationshipMotivationContent() }
    }
}

// MARK: - OB Personalizing 页：进度条 0-100%

struct OBPersonalizingPage: View {
    @Environment(AppState.self) private var appState
    @State private var progress: Double = 0.0
    
    var body: some View {
        ZStack {
            AppTheme.bgPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                Text("Personalizing...")
                    .font(AppTheme.fontBold(size: 28))
                    .foregroundStyle(AppTheme.textPrimary)
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.secondary.opacity(0.3))
                            .frame(height: 12)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.primary)
                            .frame(width: geo.size.width * CGFloat(progress), height: 12)
                    }
                }
                .frame(height: 12)
                .frame(width: 280)
                
                Text("\(Int(progress * 100))%")
                    .font(AppTheme.font(size: 18))
                    .foregroundStyle(AppTheme.textSecondary)
                
                Spacer()
            }
            .padding(32)
        }
        .onAppear {
            withAnimation(.linear(duration: 2.5)) {
                progress = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                appState.nextOnboardingPage()
            }
        }
    }
}

// MARK: - OB 内容区滑入包装（用 offset 保证每次翻页都可见，避免 transition 首帧不生效）

private struct OBContentSlideWrapper<Content: View>: View {
    let screenWidth: CGFloat
    let forward: Bool
    @ViewBuilder let content: () -> Content
    @State private var offset: CGFloat?

    var body: some View {
        content()
            .offset(x: offset ?? (forward ? screenWidth : -screenWidth))
            .onAppear {
                guard offset == nil else { return }
                withAnimation(.easeInOut(duration: 0.35)) {
                    offset = 0
                }
            }
    }
}

// MARK: - 进度条当前节点上的 sparkles 动画（播完后回调）

private struct OBProgressSparklesOverlay: View {
    let currentStep: Int
    let totalSteps: Int
    let onComplete: () -> Void

    var body: some View {
        GeometryReader { geo in
            let barWidth = max(0, geo.size.width - 64)
            let progress = totalSteps > 0 ? CGFloat(currentStep) / CGFloat(totalSteps) : 0
            let centerX = 32 + barWidth * progress
            LottieView(
                animationName: "sparkles-animation_10647751",
                subdirectory: "lottie",
                loopMode: .playOnce,
                contentMode: .scaleAspectFit,
                speed: 4.0,
                onComplete: onComplete
            )
            .frame(width: 108, height: 108)
            .position(x: centerX, y: geo.size.height / 2)
        }
        .frame(height: 40)
        .allowsHitTesting(false)
    }
}

// MARK: - OB 统一容器：背景与顶栏不重置，仅内容区翻页滑入

struct OBFlowContainerView: View {
    @Environment(AppState.self) private var appState
    
    private static func stepAndBack(for page: AppPage) -> (step: Int, showBack: Bool) {
        switch page {
        case .obGetStarted: return (1, false)
        case .obTeamIntro: return (2, true)
        case .obAge: return (3, true)
        case .obAgeMotivation: return (4, true)
        case .obGender: return (5, true)
        case .obAvatar: return (6, true)
        case .obName: return (7, true)
        case .obNameMotivation: return (8, true)
        case .obRelationship: return (9, true)
        case .obRelationshipMotivation: return (10, true)
        default: return (1, false)
        }
    }
    
    var body: some View {
        let (step, showBack) = Self.stepAndBack(for: appState.currentPage)
        ZStack {
            if appState.currentPage == .obGetStarted {
                Image("Get started bg")
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()
                    .ignoresSafeArea()
            } else {
                Color(hex: "FFFFFF")
                    .ignoresSafeArea()
                GeometryReader { geo in
                    let side = max(geo.size.width, geo.size.height)
                    ZStack {
                        LottieView(
                            animationName: "abstract-background-animation_9572483",
                            subdirectory: "lottie",
                            contentMode: .scaleAspectFill,
                            speed: 0.3
                        )
                        .frame(width: side, height: side)
                        .rotationEffect(.degrees(90))
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
            
            VStack(spacing: 0) {
                if appState.currentPage != .obGetStarted {
                    VStack(spacing: 0) {
                        HStack {
                            if showBack {
                                OBBackButtonLottieView(action: { appState.previousOnboardingPage() })
                            }
                            Spacer()
                        }
                        .padding(.leading, 10)
                        .padding(.trailing, 32)
                        .padding(.top, 16)
                        .frame(height: 60)
                        ZStack(alignment: .leading) {
                            OBProgressBar(currentStep: step, totalSteps: 11)
                                .padding(.horizontal, 32)
                                .padding(.bottom, 24)
                                .frame(height: 40)
                            if appState.obPendingSparkles {
                                OBProgressSparklesOverlay(
                                    currentStep: step,
                                    totalSteps: 11,
                                    onComplete: {
                                        guard appState.obPendingSparkles else { return }
                                        appState.obPendingSparkles = false
                                        appState.nextOnboardingPage()
                                        print("[OBFlowContainer] sparkles 完成，已跳转下一页")
                                    }
                                )
                            }
                        }
                        .frame(height: 40)
                    }
                    .frame(height: 100)
                }
                
                GeometryReader { geo in
                    ScrollView {
                        OBContentSlideWrapper(screenWidth: geo.size.width, forward: appState.obNavigationForward) {
                            Group {
                                switch appState.currentPage {
                                case .obGetStarted: OBGetStartedContent()
                                case .obTeamIntro: OBTeamIntroContent()
                                case .obAge: OBAgeContent()
                                case .obAgeMotivation: OBAgeMotivationContent()
                                case .obGender: OBGenderContent()
                                case .obAvatar: OBAvatarContent()
                                case .obName: OBNameContent()
                                case .obNameMotivation: OBNameMotivationContent()
                                case .obRelationship: OBRelationshipContent()
                                case .obRelationshipMotivation: OBRelationshipMotivationContent()
                                default: OBGetStartedContent()
                                }
                            }
                            .frame(minHeight: geo.size.height)
                            .frame(maxWidth: .infinity)
                        }
                        .id(appState.currentPage)
                    }
                }
                .clipped()
            }
        }
    }
}

// MARK: - 通用布局

struct OBPageLayout<Content: View>: View {
    let currentStep: Int
    var totalSteps: Int = 11
    var showBackButton: Bool = true
    @Environment(AppState.self) private var appState
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        ZStack {
            Color(hex: "FFFFFF")
                .ignoresSafeArea()
            GeometryReader { geo in
                let side = max(geo.size.width, geo.size.height)
                ZStack {
                    LottieView(
                        animationName: "abstract-background-animation_9572483",
                        subdirectory: "lottie",
                        contentMode: .scaleAspectFill,
                        speed: 0.3
                    )
                    .frame(width: side, height: side)
                    .rotationEffect(.degrees(90))
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            
            VStack(spacing: 0) {
                // 顶部固定区域：返回按钮 + 进度条
                VStack(spacing: 0) {
                    HStack {
                        if showBackButton {
                            OBBackButtonLottieView(action: { appState.previousOnboardingPage() })
                        }
                        Spacer()
                    }
                    .padding(.leading, 10)
                    .padding(.trailing, 32)
                    .padding(.top, 16)
                    .frame(height: 60)
                    
                    OBProgressBar(currentStep: currentStep, totalSteps: totalSteps)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 24)
                        .frame(height: 40)
                }
                .frame(height: 100)
                
                // 主视觉区域：统一高度，内容居中
                GeometryReader { geo in
                    ScrollView {
                        content()
                            .frame(minHeight: geo.size.height)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

// MARK: - 可选行（年龄）

struct OBSelectableRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(AppTheme.font(size: 18))
                    .foregroundStyle(AppTheme.textOnLight)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(AppTheme.font(size: 24))
                        .foregroundStyle(AppTheme.primary)
                }
            }
            .padding(.horizontal, 24)
            .frame(height: 64)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(isSelected ? AppTheme.primary : Color.clear, lineWidth: 2)
            )
            .shadow(color: AppTheme.shadowColor, radius: 12, x: 0, y: 2)
        }
        .buttonStyle(ClickSoundButtonStyle())
    }
}

// MARK: - 性别卡片（支持 Lottie 动画或 SF Symbol）

struct OBGenderCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    var lottieAnimationName: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                if let name = lottieAnimationName {
                    LottieView(
                        animationName: name,
                        subdirectory: "lottie",
                        contentMode: .scaleAspectFit
                    )
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                } else {
                    Image(systemName: icon)
                        .font(AppTheme.font(size: 64))
                        .foregroundStyle(iconColor)
                }
                Text(title)
                    .font(AppTheme.font(size: 18))
                    .foregroundStyle(AppTheme.textOnLight)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 210)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(isSelected ? AppTheme.primary : Color.clear, lineWidth: 3)
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(AppTheme.font(size: 28))
                        .foregroundStyle(AppTheme.primary)
                        .background(Color.white, in: Circle())
                        .offset(x: -12, y: 12)
                }
            }
            .shadow(color: AppTheme.shadowColor, radius: 12, x: 0, y: 2)
        }
        .buttonStyle(ClickSoundButtonStyle())
    }
}

// MARK: - 头像单元格

struct OBAvatarCell: View {
    let avatar: AvatarOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(Color(hex: avatar.color))
                    LottieView(
                        animationName: avatar.lottieAnimationName,
                        subdirectory: "lottie",
                        contentMode: .scaleAspectFit
                    )
                    .frame(width: 96, height: 96)
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? AppTheme.primary : Color.clear, lineWidth: 3)
                )
                .shadow(color: AppTheme.shadowColor, radius: 12, x: 0, y: 2)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(AppTheme.font(size: 24))
                        .foregroundStyle(.white)
                        .background(AppTheme.primary, in: Circle())
                        .offset(x: 4, y: 4)
                }
            }
        }
        .buttonStyle(ClickSoundButtonStyle())
    }
}

#Preview("OB Age") {
    OBAgePage()
        .environment(AppState.shared)
}
