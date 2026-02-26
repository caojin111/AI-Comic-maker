//
//  SplashView.swift
//  AI Picture Book
//
//  启动页：Lottie 动画 + 标题
//

import SwiftUI
import Lottie

struct SplashView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width * splashAnimationWidthRatio
            let h = w * (splashAnimationDesignHeight / splashAnimationDesignWidth)
            
            ZStack {
                Color(hex: "FFFFFF")
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    LottieView(animationName: "woman-reading-book-under-the-tree", subdirectory: "lottie")
                        .frame(width: w, height: h)
                    
                    Text("AI story")
                        .font(AppTheme.font(size: 48))
                        .foregroundStyle(AppTheme.primary)
                        .tracking(-1)
                    
                    Text("AI Story Book")
                        .font(AppTheme.font(size: 18))
                        .foregroundStyle(AppTheme.textOnLight)
                    
                    Spacer()
                }
                .padding(32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .onAppear {
            print("[SplashView] onAppear, transition after delay")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                appState.onSplashComplete()
            }
        }
    }
}

// MARK: - 闪屏动画尺寸（按屏幕宽度比例缩放，改比例可调大小）
private let splashAnimationDesignWidth: CGFloat = 174
private let splashAnimationDesignHeight: CGFloat = 214
/// 动画宽度占屏幕宽度的比例（约 0.45 时在 390pt 宽屏上接近原 174pt）
private let splashAnimationWidthRatio: CGFloat = 0.9

#Preview {
    SplashView()
        .environment(AppState.shared)
}
