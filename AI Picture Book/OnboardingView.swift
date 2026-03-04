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
            (Text("How old").font(AppTheme.fontRowdiesBold(size: 28)).foregroundStyle(Color(hex: "FF6A88")) + Text(" is your child?").font(AppTheme.fontBold(size: 28)).foregroundStyle(AppTheme.textOnLight))
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
                    .foregroundStyle(AppTheme.textOnLight)
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
            (Text("What is your child's ").font(AppTheme.fontBold(size: 28)).foregroundStyle(AppTheme.textOnLight) + Text("gender").font(AppTheme.fontRowdiesBold(size: 28)).foregroundStyle(Color(hex: "FF6A88")) + Text("?").font(AppTheme.fontBold(size: 28)).foregroundStyle(AppTheme.textOnLight))
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
            (Text("Choose your child's ").font(AppTheme.fontBold(size: 28)).foregroundStyle(AppTheme.textOnLight) + Text("avatar").font(AppTheme.fontRowdiesBold(size: 28)).foregroundStyle(Color(hex: "FF6A88")))
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
            (Text("Your child's ").font(AppTheme.fontBold(size: 28)).foregroundStyle(AppTheme.textOnLight) + Text("name").font(AppTheme.fontRowdiesBold(size: 28)).foregroundStyle(Color(hex: "FF6A88")))
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
    @State private var imageScale: CGFloat = 0.5
    @State private var imageOpacity: Double = 0
    
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
                    .scaleEffect(1.5 * imageScale)
                    .opacity(imageOpacity)
                    .offset(y: -30)
                    .onAppear {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            imageScale = 1.0
                            imageOpacity = 1.0
                        }
                    }
                
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
                
                (Text("Get ready for ").font(AppTheme.fontBold(size: 26)).foregroundStyle(AppTheme.textOnLight) + Text("\(childName)").font(AppTheme.fontRowdiesBold(size: 26)).foregroundStyle(Color(hex: "FF6A88")) + Text("'s reading journey!").font(AppTheme.fontBold(size: 26)).foregroundStyle(AppTheme.textOnLight))
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
    /// 是否已播放碰撞音效
    @State private var hasPlayedCollisionSound: Bool = false

    private var childName: String {
        let name = appState.childName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "your child" : name
    }
    private var relationshipText: String {
        guard let rel = appState.childRelationship else { return "Parent" }
        return rel == .other ? "You" : rel.rawValue
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
    
    private var parentRotation: Angle {
        switch avatarPhase {
        case 2: return .degrees(-20)
        default: return .degrees(0)
        }
    }
    
    private var childRotation: Angle {
        switch avatarPhase {
        case 2: return .degrees(20)
        default: return .degrees(0)
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
                    .rotationEffect(parentRotation)
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
                        .rotationEffect(childRotation)
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
                        .rotationEffect(childRotation)
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
                // 在两个头像相撞的一瞬间（phase 1 达到时）播放音效
                DispatchQueue.main.asyncAfter(deadline: .now() + pageFlipDuration + 0.7) {
                    if !hasPlayedCollisionSound {
                        hasPlayedCollisionSound = true
                        AppSoundManager.shared.playSoundEffect(fileName: "OBxandy", ext: "wav", subdirectory: "sound", volume: 0.8)
                        print("[OBRelationshipMotivation] 播放头像碰撞音效")
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
            (Text(relationshipText).foregroundStyle(Color(hex: "F85162")) + Text(" and ").foregroundStyle(AppTheme.textOnLight) + Text(childName).foregroundStyle(Color(hex: "F85162")))
                .font(AppTheme.fontBold(size: 14))
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

// MARK: - OB Personalizing 页：四段进度条 + Did You Know 区域

private let personalizingStepDuration: TimeInterval = 2.0
private let personalizingTotalDuration: TimeInterval = 8.2

struct OBPersonalizingPage: View {
    @Environment(AppState.self) private var appState
    @State private var progress1: Double = 0
    @State private var progress2: Double = 0
    @State private var progress3: Double = 0
    @State private var progress4: Double = 0

    var body: some View {
        ZStack {
            Color(hex: "FFFFFF")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Text("Personalizing...")
                    .font(AppTheme.fontBold(size: 28))
                    .foregroundStyle(AppTheme.textOnLight)
                    .padding(.top, 40)
                    .padding(.bottom, 24)
                VStack(alignment: .leading, spacing: 20) {
                    OBPersonalizingProgressRow(title: "Analyzing goals", progress: progress1)
                    OBPersonalizingProgressRow(title: "Analyzing profile", progress: progress2)
                    OBPersonalizingProgressRow(title: "Connecting AI", progress: progress3)
                    OBPersonalizingProgressRow(title: "Personalization", progress: progress4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
                
                Spacer(minLength: 16)
                
                VStack(spacing: 16) {
                    LottieView(
                        animationName: "loading-animation_4330190",
                        subdirectory: "lottie",
                        contentMode: .scaleAspectFit
                    )
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    Text("Did You Know?")
                        .font(AppTheme.fontBold(size: 22))
                        .foregroundStyle(AppTheme.textOnLight)
                    Text("Children are 19x more likely to read from an app when using it with a parent.")
                        .font(AppTheme.font(size: 16))
                        .foregroundStyle(AppTheme.obBodyText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            setOrientation(.portrait)
            runSequentialProgress()
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
    
    private func runSequentialProgress() {
        let appearDelay: TimeInterval = 0.2
        let segment1Duration: TimeInterval = 0.4
        let segment2Duration: TimeInterval = 1.0
        let segment3Duration: TimeInterval = 0.6
        let barTotal: TimeInterval = segment1Duration + segment2Duration + segment3Duration

        func runBarSegments(setProgress: @escaping (Double) -> Void, startAt: TimeInterval) {
            DispatchQueue.main.asyncAfter(deadline: .now() + startAt) {
                withAnimation(.linear(duration: segment1Duration)) { setProgress(0.35) }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + startAt + segment1Duration) {
                withAnimation(.linear(duration: segment2Duration)) { setProgress(0.72) }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + startAt + segment1Duration + segment2Duration) {
                withAnimation(.linear(duration: segment3Duration)) { setProgress(1.0) }
            }
        }

        runBarSegments(setProgress: { progress1 = $0 }, startAt: appearDelay)
        runBarSegments(setProgress: { progress2 = $0 }, startAt: appearDelay + barTotal)
        runBarSegments(setProgress: { progress3 = $0 }, startAt: appearDelay + barTotal * 2)
        runBarSegments(setProgress: { progress4 = $0 }, startAt: appearDelay + barTotal * 3)
        DispatchQueue.main.asyncAfter(deadline: .now() + personalizingTotalDuration) {
            appState.nextOnboardingPage()
        }
    }
}

private struct OBPersonalizingProgressRow: View {
    let title: String
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTheme.font(size: 16))
                .foregroundStyle(AppTheme.textOnLight)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.1))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppTheme.primary)
                        .frame(width: geo.size.width * CGFloat(progress), height: 10)
                }
            }
            .frame(height: 10)
        }
    }
}

// MARK: - OB All Set Up 页：头像+名字 + Woohoo! + Continue → Paywall

struct OBAllSetUpPage: View {
    @Environment(AppState.self) private var appState
    @State private var hasPlayedApplauseSound: Bool = false
    
    private var childName: String {
        let name = appState.childName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "your child" : name
    }
    
    var body: some View {
        ZStack {
            Color(hex: "FFFFFF")
                .ignoresSafeArea()
            GeometryReader { geo in
                VStack(spacing: 0) {
                    ZStack {
                        LottieView(
                            animationName: "confetti-animation_4560441",
                            subdirectory: "lottie",
                            contentMode: .scaleAspectFit
                        )
                        .frame(width: geo.size.width, height: geo.size.height * 0.5)
                        .allowsHitTesting(false)
                        .onAppear {
                            // 彩带动画出现时播放掌声音效
                            if !hasPlayedApplauseSound {
                                hasPlayedApplauseSound = true
                                AppSoundManager.shared.playSoundEffect(fileName: "mixkit-animated-small-group-applause-523", ext: "wav", subdirectory: "sound", volume: 0.7)
                                print("[OBAllSetUp] 播放掌声音效")
                            }
                        }
                    }
                    .frame(height: geo.size.height * 0.5)
                    Spacer(minLength: 0)
                }
            }
            .ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer(minLength: 0)
                VStack(spacing: 12) {
                    if let avatar = appState.childAvatar {
                        ZStack {
                            Circle()
                                .fill(Color(hex: avatar.color))
                            LottieView(
                                animationName: avatar.lottieAnimationName,
                                subdirectory: "lottie",
                                contentMode: .scaleAspectFit
                            )
                            .frame(width: 134, height: 134)
                        }
                        .frame(width: 112, height: 112)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(AppTheme.secondary.opacity(0.6))
                            .frame(width: 112, height: 112)
                            .overlay(
                                Image(systemName: "face.smiling")
                                    .font(AppTheme.font(size: 48))
                                    .foregroundStyle(AppTheme.textOnLight)
                            )
                    }
                }
                .offset(y: -80)
                Text("Woohoo!")
                    .font(AppTheme.fontBold(size: 28))
                    .foregroundStyle(AppTheme.textOnLight)
                (Text(childName).foregroundStyle(Color(hex: "F85162")) + Text("'s profile is all set up.").foregroundStyle(AppTheme.obBodyText))
                    .font(AppTheme.font(size: 16))
                    .multilineTextAlignment(.center)
                Spacer(minLength: 0)
                OBPrimaryButton(title: "Continue") {
                    appState.nextOnboardingPage()
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            setOrientation(.portrait)
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

// MARK: - OB 折线图激励页：6 节点快增长折线，x 轴 4 个短描述，第 4 节点展示头像

/// 第 5、6 节点更高，形成更陡峭的“一飞冲天”曲线
private let chartMotivationYValues: [CGFloat] = [0, 0.1, 0.22, 0.38, 0.68, 1.0]
private let chartXAxisLabels = ["Start", "3 stories", "6 stories", "First book"]
/// 前 4 节点几乎占满屏幕宽度，5～6 在右侧收尾
private let chartMotivationXRatios: [CGFloat] = [0, 0.25, 0.5, 0.75, 0.88, 1.0]

struct OBChartMotivationPage: View {
    @Environment(AppState.self) private var appState

    private var childName: String {
        let name = appState.childName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "your child" : name
    }

    private var readingPronoun: String {
        appState.childGender == .girl ? "her" : "his"
    }

    var body: some View {
        ZStack {
            Color(hex: "FFFFFF")
                .ignoresSafeArea()
            GeometryReader { geo in
                let chartHeight: CGFloat = 320
                let titleAreaHeight: CGFloat = 80
                let topOffset = max(0, geo.size.height * 0.5 - chartHeight * 0.5 - titleAreaHeight)
                VStack(spacing: 24) {
                    Spacer(minLength: 0)
                        .frame(height: topOffset)
                    (Text("In just 10 picture book accompany, ").font(AppTheme.fontBold(size: 20)).foregroundStyle(AppTheme.textOnLight) + Text(childName).font(AppTheme.fontBold(size: 20)).foregroundStyle(Color(hex: "F85162")) + Text(" will be reading \(readingPronoun) first book!").font(AppTheme.fontBold(size: 20)).foregroundStyle(AppTheme.textOnLight))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    OBChartMotivationChartView(showAvatarAtIndex: 3)
                        .environment(appState)
                        .frame(height: chartHeight)
                        .padding(.horizontal, 16)
                    Spacer(minLength: 0)
                    OBPrimaryButton(title: "Continue") {
                        appState.nextOnboardingPage()
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear {
            setOrientation(.portrait)
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

private struct OBChartMotivationChartView: View {
    @Environment(AppState.self) private var appState
    var showAvatarAtIndex: Int

    private let padding: CGFloat = 24
    private let labelHeight: CGFloat = 48

    @State private var chartOpacity: Double = 0
    @State private var barsOpacity: Double = 0
    @State private var barProgress: [CGFloat] = [0, 0, 0, 0]
    @State private var barOpacities: [Double] = [0, 0, 0, 0]
    @State private var lineTrim: CGFloat = 0
    @State private var showLineAndAvatar: Bool = false

    var body: some View {
        GeometryReader { geo in
            chartContent(size: geo.size)
                .opacity(chartOpacity)
                .onAppear {
                    runChartEntranceAnimation()
                }
        }
    }

    private static func makePoints(size: CGSize, padding: CGFloat, labelHeight: CGFloat) -> [CGPoint] {
        let w = size.width - padding * 2
        let h = size.height - padding - labelHeight
        let ratios = chartMotivationXRatios
        return zip(chartMotivationYValues, ratios).map { yVal, xRatio in
            CGPoint(x: padding + xRatio * w, y: padding + (1 - yVal) * h)
        }
    }

    private func runChartEntranceAnimation() {
        print("[OBChartMotivation] 开始折线图入场动画")
        withAnimation(.easeInOut(duration: 0.4)) {
            chartOpacity = 1
        }
        let barDelay: TimeInterval = 0.24
        let fadeInDelay: TimeInterval = 0.4
        let barFadeInDuration: TimeInterval = 0.3
        let barGrowDuration: TimeInterval = 0.5
        
        for i in 0..<4 {
            let startTime = fadeInDelay + barDelay * Double(i)
            // 先渐入透明度
            DispatchQueue.main.asyncAfter(deadline: .now() + startTime) {
                withAnimation(.easeIn(duration: barFadeInDuration)) {
                    var next = barOpacities
                    next[i] = 1
                    barOpacities = next
                }
            }
            // 稍后开始高度增长
            DispatchQueue.main.asyncAfter(deadline: .now() + startTime + barFadeInDuration * 0.3) {
                withAnimation(.easeOut(duration: barGrowDuration)) {
                    var next = barProgress
                    next[i] = 1
                    barProgress = next
                }
            }
        }
        let lineStart = fadeInDelay + barDelay * 4 + barFadeInDuration + barGrowDuration
        DispatchQueue.main.asyncAfter(deadline: .now() + lineStart) {
            withAnimation(.easeOut(duration: 1.2)) {
                lineTrim = 1
            }
            // 折线出场时播放 funnel_1.wav
            AppSoundManager.shared.playSoundEffect(fileName: "funnel_1", ext: "wav", subdirectory: "sound", volume: 0.6)
            print("[OBChartMotivation] 播放折线出场音效 funnel_1.wav")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + lineStart + 0.7) {
            withAnimation(.easeOut(duration: 0.5)) {
                showLineAndAvatar = true
            }
            // 孩子头像出场时播放 funnel_2.wav
            AppSoundManager.shared.playSoundEffect(fileName: "funnel_2", ext: "wav", subdirectory: "sound", volume: 0.6)
            print("[OBChartMotivation] 播放头像出场音效 funnel_2.wav")
        }
    }

    @ViewBuilder
    private func chartContent(size: CGSize) -> some View {
        let points = Self.makePoints(size: size, padding: padding, labelHeight: labelHeight)
        let w = size.width - padding * 2
        let h = size.height - padding - labelHeight
        let bottomY = padding + h
        let barWidth = (w * 0.25) * 0.48
        let firstFour = Array(points.prefix(4))
        ZStack(alignment: .topLeading) {
            ForEach(0..<4, id: \.self) { i in
                if i < firstFour.count {
                    ChartBarsShape(points: [firstFour[i]], bottomY: bottomY, barWidth: barWidth, barProgress: [barProgress[i]])
                        .fill(AppTheme.secondary.opacity(0.4))
                        .overlay(
                            ChartBarsShape(points: [firstFour[i]], bottomY: bottomY, barWidth: barWidth, barProgress: [barProgress[i]])
                                .stroke(AppTheme.secondary, lineWidth: 2.5)
                        )
                        .shadow(color: AppTheme.shadowColor.opacity(0.15), radius: 2, x: 0, y: 1)
                        .opacity(barOpacities[i])
                }
            }
            ChartLinePath(points: points)
                .trim(from: 0, to: lineTrim)
                .stroke(AppTheme.primary, style: StrokeStyle(lineWidth: 4.5, lineCap: .round, lineJoin: .round))
                .shadow(color: AppTheme.primary.opacity(0.3), radius: 1, x: 0, y: 0)
            if showLineAndAvatar {
                ForEach(Array(points.enumerated()), id: \.offset) { _, pt in
                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(AppTheme.textOnLight.opacity(0.4), lineWidth: 2))
                        .position(x: pt.x, y: pt.y)
                }
                if showAvatarAtIndex < points.count {
                    let pt = points[showAvatarAtIndex]
                    avatarView
                        .frame(width: 48, height: 48)
                        .position(x: pt.x, y: pt.y)
                }
            }
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                ZStack(alignment: .leading) {
                    ForEach(0..<4, id: \.self) { i in
                        Text(chartXAxisLabels[i])
                            .font(AppTheme.font(size: 12))
                            .foregroundStyle(AppTheme.obBodyText)
                            .multilineTextAlignment(.center)
                            .frame(width: 64)
                            .position(x: points[i].x, y: labelHeight / 2)
                    }
                }
                .frame(height: labelHeight)
                .frame(width: size.width)
            }
        }
    }

    private var avatarView: some View {
        Group {
            if let avatar = appState.childAvatar {
                ZStack {
                    Circle()
                        .fill(Color(hex: avatar.color))
                    LottieView(
                        animationName: avatar.lottieAnimationName,
                        subdirectory: "lottie",
                        contentMode: .scaleAspectFit
                    )
                    .frame(width: 80, height: 80)
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(AppTheme.secondary.opacity(0.6))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "face.smiling")
                            .font(AppTheme.font(size: 22))
                            .foregroundStyle(AppTheme.textOnLight)
                    )
            }
        }
    }
}

private struct ChartLinePath: Shape {
    var points: [CGPoint]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for p in points.dropFirst() { path.addLine(to: p) }
        return path
    }
}

/// 前 4 个节点向 X 轴下垂的柱状条（圆角顶，卡通感）；barProgress 控制每根柱子高度比例用于入场动画
private struct ChartBarsShape: Shape {
    var points: [CGPoint]
    var bottomY: CGFloat
    var barWidth: CGFloat
    var barProgress: [CGFloat] = [1, 1, 1, 1]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerRadius: CGFloat = min(8, barWidth / 2)
        for (i, pt) in points.enumerated() {
            let progress = i < barProgress.count ? barProgress[i] : 1
            let fullHeight = bottomY - pt.y
            let barHeight = fullHeight * progress
            guard barHeight > 0 else { continue }
            let r = CGRect(x: pt.x - barWidth / 2, y: bottomY - barHeight, width: barWidth, height: barHeight)
            path.addRoundedRect(in: r, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        }
        return path
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
    @State private var hasStartedOBMusic = false
    
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
        .onAppear {
            setOrientation(.portrait)
            // 启动 OB 背景音乐
            if !hasStartedOBMusic {
                hasStartedOBMusic = true
                BackgroundMusicManager.shared.playMusic(fileName: "mixkit-be-happy-2-823", ext: "mp3", subdirectory: "music", volume: 0.25, loops: true)
                print("[OBFlowContainer] 开始播放 OB 背景音乐")
            }
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
                        .stroke(isSelected ? Color(hex: "FF6A88") : Color.clear, lineWidth: 3)
                )
                .shadow(color: AppTheme.shadowColor, radius: 12, x: 0, y: 2)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(AppTheme.font(size: 24))
                        .foregroundStyle(.white)
                        .background(Color(hex: "FF6A88"), in: Circle())
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
