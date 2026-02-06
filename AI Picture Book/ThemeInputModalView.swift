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
            // 遮罩层
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // 弹窗内容
            VStack(spacing: 24) {
                // 标题
                Text("输入故事主题")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                
                // 副标题
                Text("请描述你想要的故事主题，AI会为你创作专属故事")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // 输入框
                ZStack(alignment: .topLeading) {
                    if themeText.isEmpty {
                        Text("例如：小兔子在森林里冒险的故事")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                    }
                    
                    TextEditor(text: $themeText)
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(height: 120)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(Color(hex: "F5F5F5"), in: RoundedRectangle(cornerRadius: 6))
                        .focused($isTextFieldFocused)
                }
                
                // 按钮行
                HStack(spacing: 12) {
                    // 取消按钮
                    Button(action: {
                        print("[ThemeInputModalView] 取消")
                        isPresented = false
                    }) {
                        Text("取消")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color(hex: "F5F5F5"), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    
                    // 确认按钮
                    Button(action: {
                        print("[ThemeInputModalView] 开始创作，主题：\(themeText)")
                        guard !themeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                            return
                        }
                        appState.startStoryCreation(theme: themeText.trimmingCharacters(in: .whitespacesAndNewlines))
                        isPresented = false
                    }) {
                        Text("开始创作")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(AppTheme.primary, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(themeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(themeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                }
            }
            .padding(24)
            .frame(width: 326)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 24))
            .shadow(color: AppTheme.shadowColor, radius: 20, x: 0, y: 4)
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
