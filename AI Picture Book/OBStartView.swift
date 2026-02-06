//
//  OBStartView.swift
//  AI Picture Book
//
//  OB 开始页：按 Pencil 设计图，深紫背景 + 大图 + 文案 + 继续按钮
//

import SwiftUI

struct OBStartView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        ZStack {
            AppTheme.obStartBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // 顶部大图区域（设计稿约 333×382）
                Image("SplashIllustration")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(height: 382)
                    .padding(.horizontal)
                
                // 文案区域
                Text("用AI为宝宝创造专属故事")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                Spacer()
                
                // 继续按钮（设计稿：pill 圆角、primary 色）
                Button(action: { appState.enterOnboarding() }) {
                    Text("继续")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .background(AppTheme.primary, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .padding(32)
        }
        .onAppear { print("[OBStartView] onAppear") }
    }
}

#Preview {
    OBStartView()
        .environment(AppState.shared)
}
