//
//  StoryBookView.swift
//  AI Picture Book
//
//  绘本页面：从首页点击加号开始后跳转，强制横屏
//

import SwiftUI
import UIKit

struct StoryBookView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        ZStack {
            AppTheme.bgPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header：返回首页 + 设置
                HStack {
                    Button(action: { appState.backToHome() }) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(Color.white, in: Circle())
                            .shadow(color: AppTheme.shadowColor, radius: 8, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(Color.white, in: Circle())
                            .shadow(color: AppTheme.shadowColor, radius: 8, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                
                // 绘本插图占位
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                        .shadow(color: AppTheme.shadowColor, radius: 12, x: 0, y: 2)
                    
                    VStack(spacing: 8) {
                        Text("📖 绘本插图")
                            .font(.system(size: 24))
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("故事生成后将显示在这里")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1.5, contentMode: .fit)
                
                // 进度条
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white)
                            
                            Capsule()
                                .fill(AppTheme.primary)
                                .frame(width: geo.size.width * 0.27)
                        }
                    }
                    .frame(height: 8)
                    
                    HStack {
                        Text("01:23 / 05:00")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.textSecondary)
                        Spacer()
                    }
                }
                
                // 副标题区域
                Text("从前，在一个美丽的森林里...")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 24))
                    .shadow(color: AppTheme.shadowColor, radius: 12, x: 0, y: 2)
                
                Spacer()
            }
            .padding(24)
        }
        .onAppear {
            print("[StoryBookView] onAppear, force landscape")
            setOrientation(.landscape)
        }
        .onDisappear {
            print("[StoryBookView] onDisappear, restore portrait")
            setOrientation(.portrait)
        }
    }
}

// MARK: - 横屏控制

private func setOrientation(_ orientation: UIInterfaceOrientationMask) {
    guard let windowScene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first
    else { return }
    
    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
}

#Preview {
    StoryBookView()
        .environment(AppState.shared)
}
