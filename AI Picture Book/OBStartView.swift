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
            Color(hex: "FFFFFF")
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
                Text("Create personalized stories for your child with AI")
                    .font(AppTheme.font(size: 20))
                    .foregroundStyle(AppTheme.textOnLight)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(32)
        }
        .onAppear {
            print("[OBStartView] onAppear, auto-advance to OB first page in 2s")
            setOrientation(.portrait)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                appState.enterOnboarding()
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

#Preview {
    OBStartView()
        .environment(AppState.shared)
}
