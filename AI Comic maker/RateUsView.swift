//
//  RateUsView.swift
//  AI Comic maker
//

import SwiftUI

struct RateUsView: View {
    @Binding var isPresented: Bool
    @Environment(AppState.self) private var appState
    @State private var selectedRating: Int = 0
    @State private var hasRated = false

    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    if !hasRated { isPresented = false }
                }

            // 弹窗卡片
            VStack(spacing: 0) {
                // 顶部装饰渐变条
                LinearGradient(
                    colors: [Color(hex: "FF1493"), Color(hex: "FF69B4")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 4)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 24, bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0, topTrailingRadius: 24
                    )
                )

                VStack(spacing: 24) {
                    // 图标
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "FF1493").opacity(0.2), Color(hex: "FF69B4").opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: "FF1493").opacity(0.3), lineWidth: 1.5)
                            )

                        Text(hasRated ? "🎉" : "⭐️")
                            .font(.system(size: 38))
                    }
                    .padding(.top, 8)

                    // 标题
                    VStack(spacing: 6) {
                        Text(hasRated ? "Thank You!" : "Enjoying the App?")
                            .font(AppTheme.fontBold(size: 22))
                            .foregroundStyle(Color.white)

                        Text(hasRated ? "Your rating means a lot to us 💖" : "Rate us on the App Store")
                            .font(AppTheme.font(size: 14))
                            .foregroundStyle(Color(hex: "B0B0B0"))
                            .multilineTextAlignment(.center)
                    }

                    // 星星评分
                    HStack(spacing: 14) {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: {
                                guard !hasRated else { return }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    selectedRating = star
                                }
                                handleRating(star)
                            }) {
                                Image(systemName: star <= selectedRating ? "star.fill" : "star")
                                    .font(.system(size: 36))
                                    .foregroundStyle(
                                        star <= selectedRating
                                            ? Color(hex: "FFD700")
                                            : Color(hex: "3A3F55")
                                    )
                                    .scaleEffect(star <= selectedRating ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.25), value: selectedRating)
                            }
                            .buttonStyle(ClickSoundButtonStyle())
                            .disabled(hasRated)
                        }
                    }
                    .padding(.vertical, 4)

                    // Maybe Later
                    if !hasRated {
                        Button(action: { isPresented = false }) {
                            Text("Maybe Later")
                                .font(AppTheme.font(size: 14))
                                .foregroundStyle(Color(hex: "606070"))
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(ClickSoundButtonStyle())
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 32)
                .padding(.top, 20)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1A1F2E"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.black, lineWidth: 3)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(hex: "FF1493").opacity(0.4), lineWidth: 1)
                    )
            )
            .shadow(color: Color(hex: "FF1493").opacity(0.25), radius: 30, x: 0, y: 15)
            .padding(.horizontal, 36)
        }
        .onAppear {
            NotificationCenter.default.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: .main
            ) { _ in
                if hasRated {
                    appState.showThankYouMessage()
                    isPresented = false
                }
            }
        }
    }

    private func handleRating(_ rating: Int) {
        print("[RateUsView] 用户评分：\(rating)星，直接跳转 App Store")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            hasRated = true
            openAppStore()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                appState.showThankYouMessage()
                isPresented = false
            }
        }
    }

    private func openAppStore() {
        let appStoreURL = "https://apps.apple.com/app/id6758834751"
        if let url = URL(string: appStoreURL) {
            UIApplication.shared.open(url)
            print("[RateUsView] 打开 App Store")
        }
    }
}

#Preview {
    RateUsView(isPresented: .constant(true))
}
