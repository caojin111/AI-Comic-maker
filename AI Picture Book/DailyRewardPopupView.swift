//
//  DailyRewardPopupView.swift
//  AI Picture Book
//
//  每日登录奖励弹窗
//

import SwiftUI

struct DailyRewardPopupView: View {
    @Binding var isPresented: Bool
    let rewardAmount: Int
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // 遮罩层
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissPopup()
                }
            
            // 弹窗内容
            VStack(spacing: 0) {
                // Header 区域
                ZStack {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 28,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 28
                    )
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FFB84D"), Color(hex: "FF9A8B")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    
                    VStack(spacing: 12) {
                        // 小猫抓鱼动画
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.25))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "fish.fill")
                                .font(AppTheme.font(size: 40))
                                .foregroundStyle(.white)
                                .rotationEffect(.degrees(showContent ? 10 : -10))
                                .animation(
                                    Animation.easeInOut(duration: 0.5)
                                        .repeatForever(autoreverses: true),
                                    value: showContent
                                )
                        }
                        
                        Text("Daily Reward!")
                            .font(AppTheme.fontBold(size: 24))
                            .foregroundStyle(.white)
                    }
                    .padding(.vertical, 24)
                }
                .frame(height: 140)
                
                // 内容区域
                VStack(spacing: 24) {
                    // 奖励信息
                    VStack(spacing: 12) {
                        Text("Meow! You caught")
                            .font(AppTheme.font(size: 16))
                            .foregroundStyle(Color(hex: "5D4E37"))
                        
                        HStack(spacing: 8) {
                            Image(systemName: "fish.fill")
                                .font(AppTheme.font(size: 32))
                                .foregroundStyle(Color(hex: "FFB84D"))
                            
                            Text("\(rewardAmount)")
                                .font(AppTheme.fontBold(size: 48))
                                .foregroundStyle(Color(hex: "FF6A88"))
                        }
                        .scaleEffect(showContent ? 1.0 : 0.8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2), value: showContent)
                        
                        Text("fresh fish today!")
                            .font(AppTheme.font(size: 16))
                            .foregroundStyle(Color(hex: "5D4E37"))
                    }
                    
                    Text("Go create a new story for your little one!")
                        .font(AppTheme.font(size: 14))
                        .foregroundStyle(Color(hex: "8B7355"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    // 确认按钮
                    Button(action: {
                        dismissPopup()
                    }) {
                        Text("Awesome!")
                            .font(AppTheme.fontBold(size: 16))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "FFB84D"), Color(hex: "FF9A8B")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(color: Color(hex: "FFB84D").opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .frame(width: 360)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(hex: "FFF8F0"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .strokeBorder(Color.white, lineWidth: 2)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .shadow(color: Color.black.opacity(0.15), radius: 30, x: 0, y: 15)
            .scaleEffect(showContent ? 1.0 : 0.9)
            .opacity(showContent ? 1.0 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showContent = true
            }
        }
    }
    
    private func dismissPopup() {
        withAnimation(.easeOut(duration: 0.2)) {
            showContent = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }
}

#Preview {
    DailyRewardPopupView(isPresented: .constant(true), rewardAmount: 10)
}

