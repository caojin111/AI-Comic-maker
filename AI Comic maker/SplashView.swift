//
//  SplashView.swift
//  AI Comic maker
//

import SwiftUI

struct SplashView: View {
    @Environment(AppState.self) private var appState
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0

    var body: some View {
        ZStack {
            // 纯白背景
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // App Logo
                Image("applogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Spacer()

                // 底部信息
                VStack(spacing: 8) {
                    Text("made by LazyCat")
                        .font(AppTheme.font(size: 14))
                        .foregroundColor(Color(hex: "8B7355"))
                        .opacity(textOpacity)

                    Text("Version 1.0.0")
                        .font(AppTheme.font(size: 12))
                        .foregroundColor(Color(hex: "A0826D"))
                        .opacity(textOpacity)
                }
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .onAppear {
            print("[SplashView] onAppear, 开始动画")
            startAnimation()
            playSplashSounds()

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                appState.onSplashComplete()
            }
        }
    }

    private func playSplashSounds() {
        AppSoundManager.shared.playSoundEffect(fileName: "mixkit-cartoon-toy-whistle-616", ext: "wav", subdirectory: "sound", volume: 0.7)
        print("[SplashView] 播放口哨音效")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            AppSoundManager.shared.playSoundEffect(fileName: "mixkit-kids-cartoon-close-bells-2256", ext: "wav", subdirectory: "sound", volume: 0.7)
            print("[SplashView] 播放铃铛音效")
        }
    }

    private func startAnimation() {
        // 第一阶段：从小淡入弹出到略大（弹性 overshoot）
        withAnimation(.spring(response: 0.5, dampingFraction: 0.55, blendDuration: 0)) {
            logoScale = 1.08
            logoOpacity = 1.0
        }

        // 第二阶段：回弹收缩到正常大小
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7).delay(0.5)) {
            logoScale = 1.0
        }

        // 文字淡入
        withAnimation(.easeIn(duration: 0.4).delay(0.6)) {
            textOpacity = 1.0
        }
    }
}

#Preview {
    SplashView()
        .environment(AppState.shared)
}
