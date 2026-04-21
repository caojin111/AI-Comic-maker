//
//  DailyRewardPopupView.swift
//  AI Comic maker
//

import SwiftUI

struct DailyRewardPopupView: View {
    @Binding var isPresented: Bool
    let rewardAmount: Int
    let rewardTitle: String
    @State private var showContent = false

    var body: some View {
        ZStack {
            // 遮罩层
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { dismissPopup() }

            // 弹窗
            VStack(spacing: 0) {

                // ── Header ──
                ZStack {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 28, bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0, topTrailingRadius: 28
                    )
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FF1493"), Color(hex: "FF69B4"), Color(hex: "FF1493")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                    // 装饰圆圈
                    GeometryReader { geo in
                        ZStack {
                            Circle().fill(Color.white.opacity(0.08)).frame(width: 100, height: 100)
                                .offset(x: geo.size.width - 30, y: -30)
                            Circle().fill(Color(hex: "00D9FF").opacity(0.12)).frame(width: 70, height: 70)
                                .offset(x: -20, y: geo.size.height - 20)
                        }
                    }

                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 72, height: 72)
                                .overlay(Circle().stroke(Color.black, lineWidth: 2))

                            Image("fish coin")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                                .rotationEffect(.degrees(showContent ? 12 : -12))
                                .animation(
                                    .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                                    value: showContent
                                )
                        }

                        Text("Daily Reward!")
                            .font(AppTheme.fontRowdiesBold(size: 22))
                            .foregroundStyle(.white)
                    }
                    .padding(.vertical, 24)
                }
                .frame(height: 148)
                .overlay(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 28, bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0, topTrailingRadius: 28
                    )
                    .stroke(Color.black, lineWidth: 3)
                )

                // ── 内容区 ──
                VStack(spacing: 20) {

                    // 奖励数量
                    VStack(spacing: 8) {
                        Text(rewardTitle)
                            .font(AppTheme.font(size: 14))
                            .foregroundStyle(Color(hex: "B0B0B0"))

                        HStack(spacing: 10) {
                            Image("fish coin")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 38, height: 38)

                            Text("+\(rewardAmount)")
                                .font(AppTheme.fontRowdiesBold(size: 52))
                                .foregroundStyle(Color(hex: "FF1493"))
                        }
                        .scaleEffect(showContent ? 1.0 : 0.7)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.15), value: showContent)

                        Text("Come back tomorrow for your next reward!")
                            .font(AppTheme.font(size: 13))
                            .foregroundStyle(Color(hex: "606070"))
                    }

                    // 分割线
                    Rectangle()
                        .fill(Color(hex: "FF1493").opacity(0.2))
                        .frame(height: 1)

                    Text("Go create a new story for your little one! 🎨")
                        .font(AppTheme.font(size: 13))
                        .foregroundStyle(Color(hex: "B0B0B0"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)

                    // Awesome 按钮
                    Button(action: { dismissPopup() }) {
                        Text("Awesome!")
                            .font(AppTheme.fontBold(size: 16))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "FF1493"), Color(hex: "FF69B4")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.black, lineWidth: 2.5)
                                    )
                            )
                            .shadow(color: Color(hex: "FF1493").opacity(0.5), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .background(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0, bottomLeadingRadius: 28,
                        bottomTrailingRadius: 28, topTrailingRadius: 0
                    )
                    .fill(Color(hex: "0A0E1A"))
                    .overlay(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0, bottomLeadingRadius: 28,
                            bottomTrailingRadius: 28, topTrailingRadius: 0
                        )
                        .stroke(Color.black, lineWidth: 3)
                    )
                    .overlay(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0, bottomLeadingRadius: 28,
                            bottomTrailingRadius: 28, topTrailingRadius: 0
                        )
                        .stroke(Color(hex: "FF1493").opacity(0.3), lineWidth: 1)
                    )
                )
            }
            .frame(width: 340)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .shadow(color: Color(hex: "FF1493").opacity(0.3), radius: 40, x: 0, y: 20)
            .scaleEffect(showContent ? 1.0 : 0.85)
            .opacity(showContent ? 1.0 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                showContent = true
            }
        }
    }

    private func dismissPopup() {
        withAnimation(.easeOut(duration: 0.2)) { showContent = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { isPresented = false }
    }
}

#Preview {
    DailyRewardPopupView(isPresented: .constant(true), rewardAmount: 10, rewardTitle: "Monthly member daily reward")
}
