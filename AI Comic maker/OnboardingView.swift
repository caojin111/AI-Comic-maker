//
//  OnboardingView.swift
//  AI Comic maker
//

import SwiftUI
import Lottie

// MARK: - OB 返回按钮（Lottie）

private struct OBBackButtonLottieView: View {
    let action: () -> Void
    var body: some View {
        Button(action: {
            AppSoundManager.shared.playClick()
            action()
        }) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 4)

                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.black)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .frame(width: 56, height: 56)
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

    func makeCoordinator() -> Coordinator { Coordinator(action: action) }

    final class Coordinator: NSObject {
        var action: () -> Void
        weak var animationView: LottieAnimationView?
        var isAnimating = false
        init(action: @escaping () -> Void) { self.action = action }

        @objc func didTap() {
            guard let animationView = animationView, !isAnimating else { return }
            isAnimating = true
            AppSoundManager.shared.playClick()
            animationView.play { [weak self] _ in
                DispatchQueue.main.async {
                    self?.isAnimating = false
                    self?.action()
                }
            }
        }
    }
}

// MARK: - OB 主按钮

struct OBPrimaryButton: View {
    let title: String
    let action: () -> Void
    @State private var isProcessing = false

    var body: some View {
        Button {
            guard !isProcessing else { return }
            isProcessing = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isProcessing = false
            }
        } label: {
            Text(title)
                .font(AppTheme.font(size: 23))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(isProcessing ? AppTheme.primary.opacity(0.6) : AppTheme.primary, in: Capsule())
        }
        .buttonStyle(ClickSoundButtonStyle())
        .disabled(isProcessing)
    }
}

// MARK: - OB 文字底框（白色卡片 + 漫画黑色粗描边）

struct OBTextCard<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        content()
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // 漫画阴影：偏移实色黑块
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black)
                        .offset(x: 4, y: 5)
                    // 白色底
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.95))
                    // 黑色描边
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.black, lineWidth: 3)
                }
            )
    }
}

// MARK: - OB 内容区滑入包装

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
                withAnimation(.easeInOut(duration: 0.35)) { offset = 0 }
            }
    }
}

// MARK: - OB 第 1 页：Unleash Your Imagination

struct OBGetStartedContent: View {
    @Environment(AppState.self) private var appState
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 12) {
                // ob_1.json 动画（占满剩余空间）
                LottieView(
                    animationName: "ob_1",
                    subdirectory: "lottie",
                    loopMode: .loop,
                    contentMode: .scaleAspectFit
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(1.2)
                .padding(.horizontal, 32)

            OBTextCard {
                VStack(spacing: 12) {
                    Text("Unleash Your\nImagination")
                        .font(AppTheme.fontBold(size: 28))
                        .foregroundStyle(Color(hex: "1A1A2E"))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Turn your wildest stories into stunning visual comics. Type your plot or let our AI suggest a random adventure for you.")
                        .font(AppTheme.font(size: 16))
                        .foregroundStyle(Color(hex: "3A3A4A"))
                        .multilineTextAlignment(.center)
                }
            }
            OBPrimaryButton(title: "Get Started") {
                print("[OBGetStartedContent] Get Started tapped")
                appState.nextOnboardingPage()
            }
        }
            .padding(.top, 60)
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - OB 第 2 页：Your Characters, Your World

struct OBPage2Content: View {
    @Environment(AppState.self) private var appState
    @State private var show1 = false
    @State private var show2 = false
    @State private var show3 = false
    @State private var show4 = false

    @ViewBuilder
    private func comicStrip2(width: CGFloat) -> some View {
        VStack(spacing: 0) {
            Image("ob2_1")
                .resizable()
                .scaledToFill()
                .frame(width: width)
                .clipped()
                .opacity(show1 ? 1 : 0)
                .offset(y: show1 ? 0 : -40)
                .animation(.spring(response: 0.45, dampingFraction: 0.7).delay(0.35), value: show1)
            Image("ob2_2")
                .resizable()
                .scaledToFill()
                .frame(width: width)
                .clipped()
                .padding(.top, -20)
                .opacity(show2 ? 1 : 0)
                .offset(y: show2 ? 0 : -40)
                .animation(.spring(response: 0.45, dampingFraction: 0.7).delay(0.5), value: show2)
            Image("ob2_3")
                .resizable()
                .scaledToFill()
                .frame(width: width)
                .clipped()
                .padding(.top, -20)
                .opacity(show3 ? 1 : 0)
                .offset(y: show3 ? 0 : -40)
                .animation(.spring(response: 0.45, dampingFraction: 0.7).delay(0.65), value: show3)
            Image("ob2_4")
                .resizable()
                .scaledToFill()
                .frame(width: width)
                .clipped()
                .padding(.top, -20)
                .opacity(show4 ? 1 : 0)
                .offset(y: show4 ? 0 : -40)
                .animation(.spring(response: 0.45, dampingFraction: 0.7).delay(0.8), value: show4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.4), radius: 0, x: 4, y: 5)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                let stripW = geo.size.width - 64
                let stripH: CGFloat = 320
                comicStrip2(width: stripW)
                    .scaleEffect(1.0 / 1.2, anchor: .center)
                    .frame(width: stripW, height: stripH)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2 - 80)

                // 对话框 + 按钮
                VStack(spacing: 12) {
            Spacer()
            OBTextCard {
                VStack(spacing: 12) {
                    Text("Your Characters, Your World")
                        .font(AppTheme.fontBold(size: 28))
                        .foregroundStyle(Color(hex: "1A1A2E"))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Design your own heroes, villains, or sidekicks. Choose from Manga, Western Comic, Manhwa, or create your own custom art style.")
                        .font(AppTheme.font(size: 16))
                        .foregroundStyle(Color(hex: "3A3A4A"))
                        .multilineTextAlignment(.center)
                }
            }
            OBPrimaryButton(title: "Continue") {
                appState.nextOnboardingPage()
            }
        }
                .padding(.top, 60)
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                show1 = false; show2 = false; show3 = false; show4 = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    show1 = true; show2 = true; show3 = true; show4 = true
                }
            }
            .onDisappear { show1 = false; show2 = false; show3 = false; show4 = false }
        }
    }
}

// MARK: - OB 第 3 页：Your Photo, Your Comic Universe

struct OBPage3Content: View {
    @Environment(AppState.self) private var appState
    @State private var show1 = false
    @State private var show2 = false
    @State private var show3 = false
    @State private var showFrame = false

    @ViewBuilder
    private func comicStrip(width: CGFloat) -> some View {
        ZStack {
            VStack(spacing: 0) {
                Image("ob3_1")
                    .resizable()
                    .scaledToFill()
                    .frame(width: width)
                    .clipped()
                    .opacity(show1 ? 1 : 0)
                    .offset(y: show1 ? 0 : -40)
                    .animation(.spring(response: 0.45, dampingFraction: 0.7).delay(0.35), value: show1)
                Image("ob3_2")
                    .resizable()
                    .scaledToFill()
                    .frame(width: width)
                    .clipped()
                    .padding(.top, -35)
                    .opacity(show2 ? 1 : 0)
                    .offset(y: show2 ? 0 : -40)
                    .animation(.spring(response: 0.45, dampingFraction: 0.7).delay(0.5), value: show2)
                Image("ob3_3")
                    .resizable()
                    .scaledToFill()
                    .frame(width: width)
                    .clipped()
                    .padding(.top, -75)
                    .opacity(show3 ? 1 : 0)
                    .offset(y: show3 ? 0 : -40)
                    .animation(.spring(response: 0.45, dampingFraction: 0.7).delay(0.65), value: show3)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))

            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.black, lineWidth: 4)
                .opacity(showFrame ? 1 : 0)
                .animation(.easeInOut(duration: 0.18), value: showFrame)
        }
        .shadow(color: showFrame ? Color.black.opacity(0.8) : .clear, radius: 0, x: 5, y: 6)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                let stripW = geo.size.width - 64
                let stripH: CGFloat = 320
                comicStrip(width: stripW)
                    .scaleEffect(1.0 / 1.44, anchor: .center)
                    .frame(width: stripW, height: stripH)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2 - 180)

                // 对话框 + 按钮
                VStack(spacing: 12) {
            Spacer()
            OBTextCard {
                VStack(spacing: 12) {
                    Text("Your Photo, Your Comic Universe")
                        .font(AppTheme.fontBold(size: 28))
                        .foregroundStyle(Color(hex: "1A1A2E"))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Our advanced AI generates the script, panels, and images for you — creating personalized comics inspired by your own photos.")
                        .font(AppTheme.font(size: 16))
                        .foregroundStyle(Color(hex: "3A3A4A"))
                        .multilineTextAlignment(.center)
                }
            }
            OBPrimaryButton(title: "Continue") {
                appState.nextOnboardingPage()
            }
        }
                .padding(.top, 60)
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                show1 = false; show2 = false; show3 = false; showFrame = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    show1 = true; show2 = true; show3 = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) {
                    showFrame = true
                }
            }
            .onDisappear {
                show1 = false; show2 = false; show3 = false; showFrame = false
            }
        }
    }
}

// MARK: - OB 第 4 页：选择你的漫画风格

struct OBPage4Content: View {
    @Environment(AppState.self) private var appState
    @State private var selectedStyles: Set<String> = []

    private let styles: [(key: String, label: String, imgIndex: Int)] = [
        ("comic",   "Comic",  1),
        ("manga",   "Manga",  2),
        ("chibi",   "Chibi",  3),
        ("retro",   "Retro",  4),
    ]

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            OBTextCard {
                VStack(spacing: 14) {
                    Text("Pick Your Art Style")
                        .font(AppTheme.fontBold(size: 28))
                        .foregroundStyle(Color(hex: "1A1A2E"))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Choose the visual style for your comic. You can always change it later.")
                        .font(AppTheme.font(size: 16))
                        .foregroundStyle(Color(hex: "3A3A4A"))
                        .multilineTextAlignment(.center)

                    VStack(spacing: 10) {
                        ForEach(styles, id: \.key) { style in
                            let isSelected = selectedStyles.contains(style.key)
                            Button {
                                if isSelected {
                                    selectedStyles.remove(style.key)
                                } else {
                                    selectedStyles.insert(style.key)
                                }
                                AppSoundManager.shared.playClick()
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack(alignment: .topTrailing) {
                                        Image("style\(style.imgIndex)")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 44, height: 44)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(isSelected ? AppTheme.primary : Color.black.opacity(0.2), lineWidth: isSelected ? 3 : 1.5)
                                            )
                                            .shadow(color: isSelected ? AppTheme.primary.opacity(0.6) : Color.clear, radius: 6)
                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundStyle(AppTheme.primary)
                                                .background(Circle().fill(Color.white).padding(2))
                                                .offset(x: 4, y: -4)
                                        }
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(style.label)
                                            .font(AppTheme.fontBold(size: 16))
                                            .foregroundStyle(isSelected ? Color.white : Color(hex: "1A1A2E"))
                                        Text("Original comic rendering")
                                            .font(AppTheme.font(size: 13))
                                            .foregroundStyle(isSelected ? Color.white.opacity(0.85) : Color(hex: "5A5A6A"))
                                    }
                                    Spacer()
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.white)
                                            .font(.system(size: 20))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.black)
                                            .offset(x: 3, y: 3)
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(isSelected ? AppTheme.primary : Color.white)
                                        RoundedRectangle(cornerRadius: 14)
                                            .strokeBorder(Color.black, lineWidth: 2.5)
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            OBPrimaryButton(title: "Continue") {
                appState.nextOnboardingPage()
            }
            .opacity(selectedStyles.isEmpty ? 0.5 : 1.0)
            .disabled(selectedStyles.isEmpty)
        }
        .padding(.top, 60)
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
    }
}

// MARK: - OB 第 5 页：选择你的漫画格式

// 田字格图标已废弃，OB5 改用 format 图片

struct OBPage5Content: View {
    @Environment(AppState.self) private var appState
    @State private var selectedFormats: Set<String> = []

    private let formats: [(key: String, label: String, desc: String, imgIndex: Int)] = [
        ("manga",   "Manga",   "Japanese comic style",      1),
        ("4-panel", "4-Panel", "2×2 grid, timeless layout", 2),
        ("meme",    "Meme",    "Fun & shareable format",    3),
        ("webtoon", "Webtoon", "Vertical scroll style",     4),
    ]

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            OBTextCard {
                VStack(spacing: 14) {
                    Text("Choose Your Format")
                        .font(AppTheme.fontBold(size: 28))
                        .foregroundStyle(Color(hex: "1A1A2E"))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("How do you want your comic panels laid out?")
                        .font(AppTheme.font(size: 16))
                        .foregroundStyle(Color(hex: "3A3A4A"))
                        .multilineTextAlignment(.center)

                    VStack(spacing: 10) {
                        ForEach(formats, id: \.key) { fmt in
                            let isSelected = selectedFormats.contains(fmt.key)
                            Button {
                                if isSelected {
                                    selectedFormats.remove(fmt.key)
                                } else {
                                    selectedFormats.insert(fmt.key)
                                }
                                AppSoundManager.shared.playClick()
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack(alignment: .topTrailing) {
                                        Image("format\(fmt.imgIndex)")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 44, height: 44)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(isSelected ? AppTheme.primary : Color.black.opacity(0.2), lineWidth: isSelected ? 3 : 1.5)
                                            )
                                            .shadow(color: isSelected ? AppTheme.primary.opacity(0.6) : Color.clear, radius: 6)
                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundStyle(AppTheme.primary)
                                                .background(Circle().fill(Color.white).padding(2))
                                                .offset(x: 4, y: -4)
                                        }
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(fmt.label)
                                            .font(AppTheme.fontBold(size: 16))
                                            .foregroundStyle(isSelected ? Color.white : Color(hex: "1A1A2E"))
                                        Text(fmt.desc)
                                            .font(AppTheme.font(size: 13))
                                            .foregroundStyle(isSelected ? Color.white.opacity(0.85) : Color(hex: "5A5A6A"))
                                    }
                                    Spacer()
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.white)
                                            .font(.system(size: 20))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.black)
                                            .offset(x: 3, y: 3)
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(isSelected ? AppTheme.primary : Color.white)
                                        RoundedRectangle(cornerRadius: 14)
                                            .strokeBorder(Color.black, lineWidth: 2.5)
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            OBPrimaryButton(title: "Continue") {
                appState.nextOnboardingPage()
            }
            .opacity(selectedFormats.isEmpty ? 0.5 : 1.0)
            .disabled(selectedFormats.isEmpty)
        }
        .padding(.top, 60)
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
    }
}

// MARK: - OB 第 6 页：Get Started（→ Paywall）

struct OBPage6Content: View {
    @Environment(AppState.self) private var appState
    @State private var showChar1 = false  // start_2 右上角角色
    @State private var showChar2 = false  // start_3 底部角色
    @State private var showFX    = false  // start_4 爆炸特效
    @State private var floatChar1 = false
    @State private var floatChar2 = false
    @State private var floatFX = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 层级从下到上：start_1 / start_4 / start_2 / start_3

                // start_1：背景，撑满整个画布不裁切
                Image("start_1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 0.75)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.black, lineWidth: 4)
                    )
                    .shadow(color: Color.black.opacity(0.8), radius: 0, x: 5, y: 6)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.35 - 30)

                // start_4：爆炸特效，画布底部 1/2 处
                Image("start_4")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 0.5625)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.5 - 30 + 20)
                    .opacity(showFX ? 1 : 0)
                    .scaleEffect(showFX ? (floatFX ? 1.05 : 0.97) : 0.4, anchor: .center)
                    .offset(x: floatFX ? 8 : -8, y: floatFX ? -6 : 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.2), value: showFX)
                    .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: floatFX)

                // start_2：右上角 1/4 处の角色
                Image("start_2")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 0.61875)
                    .position(x: geo.size.width * 0.72 - 100, y: geo.size.height * 0.25 - 70)
                    .opacity(showChar1 ? 1 : 0)
                    .offset(x: floatChar1 ? 10 : -10, y: showChar1 ? (floatChar1 ? -8 : 8) : -60)
                    .rotationEffect(.degrees(floatChar1 ? 1.8 : -1.8))
                    .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.45), value: showChar1)
                    .animation(.easeInOut(duration: 2.1).repeatForever(autoreverses: true), value: floatChar1)

                // start_3：底部 2/3 处の角色
                Image("start_3")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 0.75)
                    .position(x: geo.size.width * 0.45 - 10, y: geo.size.height * 0.67 + 10 - 110)
                    .opacity(showChar2 ? 1 : 0)
                    .offset(x: floatChar2 ? -12 : 12, y: showChar2 ? (floatChar2 ? 10 : -10) : 60)
                    .rotationEffect(.degrees(floatChar2 ? -1.4 : 1.4))
                    .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.65), value: showChar2)
                    .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: floatChar2)

                // 文字卡片 + 按钮（底部）
        VStack(spacing: 16) {
            Spacer()
            OBTextCard {
                VStack(spacing: 12) {
                    Text("You're All Set! 🎉")
                        .font(AppTheme.fontBold(size: 28))
                        .foregroundStyle(Color(hex: "1A1A2E"))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Your personalized comic adventure is ready to begin. Start creating stories that are uniquely yours.")
                        .font(AppTheme.font(size: 16))
                        .foregroundStyle(Color(hex: "3A3A4A"))
                        .multilineTextAlignment(.center)
                }
            }
            OBPrimaryButton(title: "Start Creating!") {
                appState.nextOnboardingPage()
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                showChar1 = false
                showChar2 = false
                showFX    = false
                floatChar1 = false
                floatChar2 = false
                floatFX = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    showFX    = true
                    showChar1 = true
                    showChar2 = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
                    floatFX = true
                    floatChar1 = true
                    floatChar2 = true
                }
            }
            .onDisappear {
                showChar1 = false
                showChar2 = false
                showFX    = false
                floatChar1 = false
                floatChar2 = false
                floatFX = false
            }
        }
    }
}

// MARK: - OB Lottie 背景动画

private struct OBBackgroundLottieView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(red: 0x1C / 255.0, green: 0x20 / 255.0, blue: 0x33 / 255.0, alpha: 1.0)
        
        let url = Bundle.main.url(forResource: "background-noise-effect-animation_11986462", withExtension: "json", subdirectory: "lottie")
            ?? Bundle.main.url(forResource: "background-noise-effect-animation_11986462", withExtension: "json")
        guard let resolvedURL = url,
              let animation = LottieAnimation.filepath(resolvedURL.path) else {
            print("[OBBackgroundLottie] 未找到 background-noise-effect-animation_11986462.json")
            return container
        }
        
        let animationView = LottieAnimationView(animation: animation)
        animationView.contentMode = .scaleAspectFill
        animationView.loopMode = .loop
        animationView.animationSpeed = 1.0
        animationView.backgroundBehavior = .pauseAndRestore
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: container.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        animationView.play()
        return container
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - OB 统一容器

struct OBFlowContainerView: View {
    @Environment(AppState.self) private var appState
    @State private var hasStartedOBMusic = false

    private static func showBackButton(for page: AppPage) -> Bool {
        switch page {
        case .obGetStarted: return false
        default:            return true
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Lottie 背景动画（全屏适配）
            OBBackgroundLottieView()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()

            GeometryReader { geo in
                ScrollView {
                    OBContentSlideWrapper(screenWidth: geo.size.width, forward: appState.obNavigationForward) {
                        Group {
                            switch appState.currentPage {
                            case .obGetStarted: OBGetStartedContent()
                            case .obPage2:      OBPage2Content()
                            case .obPage3:      OBPage3Content()
                            case .obPage4:      OBPage4Content()
                            case .obPage5:      OBPage5Content()
                            case .obPage6:      OBPage6Content()
                            default:            OBGetStartedContent()
                            }
                        }
                        .frame(minHeight: geo.size.height)
                        .frame(maxWidth: .infinity)
                    }
                    .id(appState.currentPage)
                }
                .clipped()
            }

            if Self.showBackButton(for: appState.currentPage) {
                OBBackButtonLottieView(action: { appState.previousOnboardingPage() })
                    .padding(.leading, 10)
                    .padding(.top, 16)
                    .zIndex(10)
            }
        }
        .onAppear {
            setOrientation(.portrait)
            if !hasStartedOBMusic {
                hasStartedOBMusic = true
                BackgroundMusicManager.shared.playMusic(
                    fileName: "mixkit-island-beat-250",
                    ext: "mp3",
                    subdirectory: "music",
                    volume: 0.25,
                    loops: true
                )
                print("[OBFlowContainer] 开始播放 OB 背景音乐")
            }
        }
    }

    private func setOrientation(_ orientation: UIInterfaceOrientationMask) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first
        else { return }
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
    }
}

#Preview {
    OBFlowContainerView()
        .environment(AppState.shared)
}
