//
//  SplashView.swift
//  AI Picture Book
//
//  启动页：App Logo + 俏皮可爱的弹跳动画
//

import SwiftUI

struct SplashView: View {
    @Environment(AppState.self) private var appState
    @State private var logoScale: CGFloat = 1.0
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var logoOffset: CGFloat = -300
    
    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                colors: [
                    Color(hex: "FFF8F0"),
                    Color(hex: "FFE8DC"),
                    Color(hex: "FFD6C8")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // App Logo
                Image("applogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .offset(y: logoOffset)
                
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
            
            // 2秒后跳转
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                appState.onSplashComplete()
            }
        }
    }
    
    private func playSplashSounds() {
        // 第一个音效：口哨声（Logo 开始落下时）
        AppSoundManager.shared.playSoundEffect(fileName: "mixkit-cartoon-toy-whistle-616", ext: "wav", subdirectory: "sound", volume: 0.7)
        print("[SplashView] 播放口哨音效")
        
        // 第二个音效：铃铛声（Logo 第一次弹起时，接力播放，延迟 1.12 秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.62) {
            AppSoundManager.shared.playSoundEffect(fileName: "mixkit-kids-cartoon-close-bells-2256", ext: "wav", subdirectory: "sound", volume: 0.7)
            print("[SplashView] 播放铃铛音效")
        }
    }
    
    private func startAnimation() {
        // Logo 淡入
        withAnimation(.easeIn(duration: 0.15)) {
            logoOpacity = 1.0
        }
        
        // 从上方自由落体到中心（使用 easeIn 模拟重力加速）
        withAnimation(.timingCurve(0.55, 0, 1, 0.45, duration: 0.5)) {
            logoOffset = 0
        }
        
        // 落地时压扁（横向拉伸，模拟冲击力）
        withAnimation(.timingCurve(0.25, 0.1, 0.25, 1, duration: 0.12).delay(0.5)) {
            logoScale = 1.25
        }
        
        // 第一次回弹（高度较高，能量损失少）
        withAnimation(.timingCurve(0.34, 1.56, 0.64, 1, duration: 0.35).delay(0.62)) {
            logoOffset = -50
            logoScale = 0.92
        }
        
        // 第一次落回地面（重力加速）
        withAnimation(.timingCurve(0.55, 0, 1, 0.45, duration: 0.25).delay(0.97)) {
            logoOffset = 0
        }
        
        // 第二次压扁（力度减小）
        withAnimation(.timingCurve(0.25, 0.1, 0.25, 1, duration: 0.1).delay(1.22)) {
            logoScale = 1.12
        }
        
        // 第二次回弹（高度降低，能量继续损失）
        withAnimation(.timingCurve(0.34, 1.56, 0.64, 1, duration: 0.28).delay(1.32)) {
            logoOffset = -20
            logoScale = 0.96
        }
        
        // 第二次落回地面
        withAnimation(.timingCurve(0.55, 0, 1, 0.45, duration: 0.2).delay(1.6)) {
            logoOffset = 0
        }
        
        // 最后轻微压扁
        withAnimation(.easeOut(duration: 0.08).delay(1.8)) {
            logoScale = 1.05
        }
        
        // 最终恢复到正常大小（使用弹簧动画模拟弹性恢复）
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75).delay(1.88)) {
            logoScale = 1.0
        }
        
        // 文字淡入
        withAnimation(.easeIn(duration: 0.4).delay(1.1)) {
            textOpacity = 1.0
        }
    }
}

#Preview {
    SplashView()
        .environment(AppState.shared)
}
