//
//  ThemeInputModalView.swift
//  AI Picture Book
//
//  主题输入弹窗：用户输入故事主题
//

import SwiftUI

struct ThemeInputModalView: View {
    @Environment(AppState.self) private var appState
    @Binding var isPresented: Bool
    @State private var themeText: String = ""
    @State private var fishCoinManager = FishCoinManager.shared
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // 遮罩层
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
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
                            colors: [Color(hex: "FF9A8B"), Color(hex: "FF6A88")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.25))
                                .frame(width: 64, height: 64)
                            
                            Image(systemName: "sparkles")
                                .font(AppTheme.font(size: 32))
                                .foregroundStyle(.white)
                        }
                        
                        Text("Create New Story")
                            .font(AppTheme.fontBold(size: 22))
                            .foregroundStyle(.white)
                        
                        Text("Describe your magical adventure")
                            .font(AppTheme.font(size: 13))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(.vertical, 24)
                }
                .frame(height: 160)
                
                // 内容区域
                VStack(spacing: 20) {
                    // 输入框
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil.circle.fill")
                                .font(AppTheme.font(size: 16))
                                .foregroundStyle(Color(hex: "FF6A88"))
                            Text("Story Theme")
                                .font(AppTheme.fontBold(size: 15))
                                .foregroundStyle(Color(hex: "5D4E37"))
                        }
                        
                        ZStack(alignment: .topLeading) {
                            if themeText.isEmpty {
                                Text("e.g., A bunny's adventure in the forest")
                                    .font(AppTheme.font(size: 14))
                                    .foregroundStyle(Color(hex: "A0826D").opacity(0.6))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                            }
                            
                            TextEditor(text: $themeText)
                                .font(AppTheme.font(size: 14))
                                .foregroundStyle(Color(hex: "5D4E37"))
                                .scrollContentBackground(.hidden)
                                .frame(height: 100)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .focused($isTextFieldFocused)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: "F5E6D3"), lineWidth: 1.5)
                        )
                    }
                    
                    // Surprise me 按钮
                    Button(action: {
                        print("[ThemeInputModalView] 点击 Surprise me")
                        themeText = SurpriseMeWordBankLoader.generateTheme()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "wand.and.stars")
                                .font(AppTheme.font(size: 16))
                            Text("Surprise Me")
                                .font(AppTheme.fontBold(size: 15))
                        }
                        .foregroundStyle(Color(hex: "FF6A88"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "FF6A88").opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: "FF6A88").opacity(0.3), lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                    
                    // 按钮行
                    HStack(spacing: 12) {
                        // 取消按钮
                        Button(action: {
                            print("[ThemeInputModalView] 取消")
                            isPresented = false
                        }) {
                            Text("Cancel")
                                .font(AppTheme.fontBold(size: 16))
                                .foregroundStyle(Color(hex: "8B7355"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.white)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color(hex: "D4A574"), lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(ClickSoundButtonStyle())
                        
                        // 确认按钮
                        Button(action: {
                            print("[ThemeInputModalView] 开始创作，主题：\(themeText)")
                            guard !themeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                                return
                            }
                            
                            // 检查小鱼干余额
                            if !fishCoinManager.canGenerateStory() {
                                print("[ThemeInputModalView] 小鱼干不足，打开商店")
                                isPresented = false
                                appState.showFishCoinShop = true
                                return
                            }
                            
                            // 消耗小鱼干
                            if fishCoinManager.consumeForStoryGeneration() {
                                appState.startStoryCreation(theme: themeText.trimmingCharacters(in: .whitespacesAndNewlines))
                                isPresented = false
                            }
                        }) {
                            HStack(spacing: 6) {
                                Text("Create")
                                    .font(AppTheme.fontBold(size: 16))
                                Image("fish coin")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                Text("x10")
                                    .font(AppTheme.fontBold(size: 16))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "FF9A8B"), Color(hex: "FF6A88")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(color: Color(hex: "FF6A88").opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(ClickSoundButtonStyle())
                        .disabled(themeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(themeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                    }
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
        }
        .onAppear {
            print("[ThemeInputModalView] onAppear")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTextFieldFocused = true
            }
        }
    }
}

#Preview {
    ThemeInputModalView(isPresented: .constant(true))
        .environment(AppState.shared)
}
