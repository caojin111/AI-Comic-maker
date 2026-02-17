//
//  SplashView.swift
//  AI Picture Book
//
//  启动页
//

import SwiftUI

struct SplashView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        ZStack {
            AppTheme.bgPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // 设计稿中的 Rectangle 插画（174×214）
                Image("SplashIllustration")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 174, height: 214)
                
                Text("AI story")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(AppTheme.primary)
                    .tracking(-1)
                
                Text("AI Story Book")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.textSecondary)
                
                Spacer()
            }
            .padding(32)
        }
        .onAppear {
            print("[SplashView] onAppear, transition after delay")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                appState.onSplashComplete()
            }
        }
    }
}

#Preview {
    SplashView()
        .environment(AppState.shared)
}
