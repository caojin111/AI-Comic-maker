//
//  HomeView.swift
//  AI Picture Book
//
//  首页：点击加号开始后跳转绘本页面
//

import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var showThemeModal = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI 故事书")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("用AI为宝宝创造专属故事")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.bottom, 8)
                
                // 开始按钮（加号 CTA）
                Button(action: {
                    print("[HomeView] 点击开始按钮")
                    showThemeModal = true
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "plus")
                            .font(.system(size: 64))
                            .foregroundStyle(.white)
                        Text("开始")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("创建新故事")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 40))
                    .shadow(color: AppTheme.primary.opacity(0.25), radius: 16, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                
                // 最近的故事
                VStack(alignment: .leading, spacing: 16) {
                    Text("最近的故事")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    
                    Text("暂无故事，点击上方开始创建")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 24))
                        .shadow(color: AppTheme.shadowColor, radius: 8, x: 0, y: 2)
                }
                
                // 功能特色
                VStack(alignment: .leading, spacing: 16) {
                    Text("功能特色")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    
                    HStack(spacing: 12) {
                        FeatureCard(icon: "sparkles", title: "AI创作", color: AppTheme.primary)
                        FeatureCard(icon: "book.closed.fill", title: "个性化", color: Color(hex: "4ECDC4"))
                        FeatureCard(icon: "photo.fill", title: "精美插图", color: Color(hex: "FFB84D"))
                    }
                }
                
                // 提示卡片
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(AppTheme.primary)
                    Text("💡 提示：输入宝宝的名字和喜好，AI会为你生成专属故事")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.primary.opacity(0.15), in: RoundedRectangle(cornerRadius: 24))
                .padding(.bottom, 32)
            }
            .padding(32)
        }
        .background(AppTheme.bgPrimary)
        .sheet(isPresented: $showThemeModal) {
            ThemeInputModalView(isPresented: $showThemeModal)
                .environment(appState)
        }
        .onAppear { print("[HomeView] onAppear") }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: AppTheme.shadowColor, radius: 6, x: 0, y: 2)
    }
}

#Preview {
    HomeView()
        .environment(AppState.shared)
}
