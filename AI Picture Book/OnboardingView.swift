//
//  OnboardingView.swift
//  AI Picture Book
//
//  OB 第 1、2、3、4 页
//

import SwiftUI

// MARK: - OB 进度条

struct OBProgressBar: View {
    let currentStep: Int
    let totalSteps: Int = 4
    
    private var progress: CGFloat {
        CGFloat(currentStep) / CGFloat(totalSteps)
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 999)
                    .fill(AppTheme.secondary)
                
                RoundedRectangle(cornerRadius: 999)
                    .fill(AppTheme.primary)
                    .frame(width: geo.size.width * progress)
            }
        }
        .frame(height: 16)
    }
}

// MARK: - OB 主按钮

struct OBPrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(AppTheme.primary, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - OB 第 1 页：年龄

struct OBAgePage: View {
    @Environment(AppState.self) private var appState
    @State private var selectedAge: ChildAge?
    
    var body: some View {
        OBPageLayout(currentStep: 1) {
            VStack(spacing: 32) {
                Text("你的孩子多大了？")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {
                    ForEach(ChildAge.allCases, id: \.self) { age in
                        OBSelectableRow(
                            title: age.rawValue,
                            isSelected: selectedAge == age
                        ) {
                            selectedAge = age
                        }
                    }
                }
                
                OBPrimaryButton(title: "继续") {
                    appState.childAge = selectedAge
                    if selectedAge != nil {
                        appState.nextOnboardingPage()
                    }
                }
                .disabled(selectedAge == nil)
            }
            .padding(32)
        }
    }
}

// MARK: - OB 第 2 页：性别

struct OBGenderPage: View {
    @Environment(AppState.self) private var appState
    @State private var selectedGender: ChildGender?
    
    var body: some View {
        OBPageLayout(currentStep: 2) {
            VStack(spacing: 32) {
                Text("你的孩子的性别")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    OBGenderCard(
                        title: "男孩",
                        icon: "person.fill",
                        iconColor: Color(hex: "4ECDC4"),
                        isSelected: selectedGender == .boy
                    ) { selectedGender = .boy }
                    
                    OBGenderCard(
                        title: "女孩",
                        icon: "heart.fill",
                        iconColor: Color(hex: "FF6B9D"),
                        isSelected: selectedGender == .girl
                    ) { selectedGender = .girl }
                }
                
                OBPrimaryButton(title: "继续") {
                    appState.childGender = selectedGender
                    if selectedGender != nil {
                        appState.nextOnboardingPage()
                    }
                }
                .disabled(selectedGender == nil)
            }
            .padding(32)
        }
    }
}

// MARK: - OB 第 3 页：头像

struct OBAvatarPage: View {
    @Environment(AppState.self) private var appState
    @State private var selectedAvatar: AvatarOption?
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        OBPageLayout(currentStep: 3) {
            VStack(spacing: 32) {
                Text("选择你孩子的头像")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(AvatarOption.allCases, id: \.self) { avatar in
                        OBAvatarCell(
                            avatar: avatar,
                            isSelected: selectedAvatar == avatar
                        ) { selectedAvatar = avatar }
                    }
                }
                .frame(height: 230)
                
                OBPrimaryButton(title: "继续") {
                    appState.childAvatar = selectedAvatar
                    if selectedAvatar != nil {
                        appState.nextOnboardingPage()
                    }
                }
                .disabled(selectedAvatar == nil)
            }
            .padding(32)
        }
    }
}

// MARK: - OB 第 4 页：名字

struct OBNamePage: View {
    @Environment(AppState.self) private var appState
    @State private var nameText: String = ""
    
    var body: some View {
        OBPageLayout(currentStep: 4) {
            VStack(spacing: 32) {
                Text("你孩子的名字")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                
                TextField("请输入名字", text: $nameText)
                    .font(.system(size: 16))
                    .padding(.horizontal, 20)
                    .frame(height: 56)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 24))
                    .shadow(color: AppTheme.shadowColor, radius: 12, x: 0, y: 2)
                
                Spacer()
                
                OBPrimaryButton(title: "继续") {
                    appState.childName = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    appState.finishOnboarding()
                }
                .disabled(nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(32)
        }
    }
}

// MARK: - 通用布局

struct OBPageLayout<Content: View>: View {
    let currentStep: Int
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        ZStack {
            AppTheme.bgPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                OBProgressBar(currentStep: currentStep)
                
                content()
            }
            .padding(32)
        }
    }
}

// MARK: - 可选行（年龄）

struct OBSelectableRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(AppTheme.primary)
                }
            }
            .padding(.horizontal, 24)
            .frame(height: 64)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(isSelected ? AppTheme.primary : Color.clear, lineWidth: 2)
            )
            .shadow(color: AppTheme.shadowColor, radius: 12, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 性别卡片

struct OBGenderCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 64))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(isSelected ? AppTheme.primary : Color.clear, lineWidth: 3)
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.primary)
                        .background(Color.white, in: Circle())
                        .offset(x: -12, y: 12)
                }
            }
            .shadow(color: AppTheme.shadowColor, radius: 12, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 头像单元格

struct OBAvatarCell: View {
    let avatar: AvatarOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: avatar.sfSymbolName)
                    .font(.system(size: 48))
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .background(Color(hex: avatar.color), in: Circle())
                    .overlay(
                        Circle()
                            .stroke(isSelected ? AppTheme.primary : Color.clear, lineWidth: 3)
                    )
                    .shadow(color: AppTheme.shadowColor, radius: 12, x: 0, y: 2)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                        .background(AppTheme.primary, in: Circle())
                        .offset(x: 4, y: 4)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview("OB Age") {
    OBAgePage()
        .environment(AppState.shared)
}
