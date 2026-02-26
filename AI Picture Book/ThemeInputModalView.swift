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
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // 遮罩层（添加淡入动画，让出现更柔和）
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                }
                .opacity(isPresented ? 1 : 0)
                .animation(.easeIn(duration: 0.3), value: isPresented)
            
            // 弹窗内容（添加缩放和淡入动画）
            VStack(spacing: 24) {
                // 标题
                Text("Enter Story Theme")
                    .font(AppTheme.font(size: 24))
                    .foregroundStyle(AppTheme.textPrimary)
                
                // 副标题
                Text("Describe the story you want, and AI will create it for you")
                    .font(AppTheme.font(size: 14))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // 输入框（强制浅色，不受深色模式影响）
                VStack(spacing: 8) {
                    ZStack(alignment: .topLeading) {
                        if themeText.isEmpty {
                            Text("e.g., A bunny's adventure in the forest")
                                .font(AppTheme.font(size: 14))
                                .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                        }
                        
                        TextEditor(text: $themeText)
                            .font(AppTheme.font(size: 14))
                            .foregroundStyle(AppTheme.textPrimary)
                            .scrollContentBackground(.hidden)
                            .frame(height: 120)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .focused($isTextFieldFocused)
                    }
                    .background(AppTheme.cardBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
                    .colorScheme(.light)
                    
                    // Surprise me 按钮（从本地 JSON 词库生成，支持双主角与 lesson 概率）
                    Button(action: {
                        print("[ThemeInputModalView] 点击 Surprise me")
                        themeText = SurpriseMeWordBankLoader.generateTheme()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(AppTheme.font(size: 14))
                            Text("Surprise me")
                                .font(AppTheme.font(size: 14))
                        }
                        .foregroundStyle(AppTheme.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(AppTheme.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                }
                
                // 按钮行
                HStack(spacing: 12) {
                    // 取消按钮
                    Button(action: {
                        print("[ThemeInputModalView] 取消")
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .font(AppTheme.font(size: 16))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(AppTheme.cardBackground.opacity(0.5), in: Capsule())
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                    
                    // 确认按钮
                    Button(action: {
                        print("[ThemeInputModalView] 开始创作，主题：\(themeText)")
                        guard !themeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                            return
                        }
                        appState.startStoryCreation(theme: themeText.trimmingCharacters(in: .whitespacesAndNewlines))
                        isPresented = false
                    }) {
                        Text("Create Story")
                            .font(AppTheme.font(size: 16))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(AppTheme.primary, in: Capsule())
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                    .disabled(themeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(themeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                }
            }
            .padding(24)
            .frame(width: 326)
            .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 24))
            .shadow(color: AppTheme.shadowColor, radius: 20, x: 0, y: 4)
            .scaleEffect(isPresented ? 1 : 0.9)
            .opacity(isPresented ? 1 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
        }
        .onAppear {
            print("[ThemeInputModalView] onAppear")
            // 延迟一下再聚焦，确保动画完成
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
