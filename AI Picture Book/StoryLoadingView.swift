//
//  StoryLoadingView.swift
//  AI Picture Book
//
//  故事生成Loading界面：显示生成进度
//

import SwiftUI

struct StoryLoadingView: View {
    @Environment(AppState.self) private var appState
    @State private var progress: Double = 0.0
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            AppTheme.bgPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // 加载图标（旋转的圆圈）
                ZStack {
                    Circle()
                        .stroke(AppTheme.primary.opacity(0.2), lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(AppTheme.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(rotationAngle))
                }
                
                // 标题
                Text("正在创作故事...")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                
                // 副标题
                Text("AI正在为你生成专属故事，请稍候")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(width: 326)
                
                // 进度条
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppTheme.secondary)
                        
                        Capsule()
                            .fill(AppTheme.primary)
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 8)
                .frame(width: 326)
            }
            .padding(32)
        }
        .onAppear {
            print("[StoryLoadingView] onAppear")
            startLoadingAnimation()
        }
    }
    
    private func startLoadingAnimation() {
        // 旋转动画（持续旋转）
        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        // 进度条动画（模拟进度，从0到70%）
        withAnimation(.easeInOut(duration: 2.5)) {
            progress = 0.7
        }
        
        // 最后0.5秒进度条到100%
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                progress = 1.0
            }
        }
        
        // 3秒后完成加载，跳转到绘本页面
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            print("[StoryLoadingView] 加载完成，跳转到绘本页面，主题：\(appState.storyTheme)")
            appState.finishStoryLoading()
        }
    }
}

#Preview {
    StoryLoadingView()
        .environment(AppState.shared)
}
