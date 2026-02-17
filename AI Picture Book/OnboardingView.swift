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
    let totalSteps: Int
    
    private var progress: CGFloat {
        guard totalSteps > 0 else { return 0 }
        return CGFloat(currentStep) / CGFloat(totalSteps)
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

// MARK: - OB Team Intro 页：Let's learn about your team!

struct OBTeamIntroPage: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        OBPageLayout(currentStep: 1, totalSteps: 10, showBackButton: false) {
            VStack(spacing: 32) {
                Spacer()
                Text("Let's learn about your team!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                Spacer()
                OBPrimaryButton(title: "Continue") {
                    appState.nextOnboardingPage()
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - OB 第 2 页：年龄

struct OBAgePage: View {
    @Environment(AppState.self) private var appState
    @State private var selectedAge: ChildAge?
    
    var body: some View {
        OBPageLayout(currentStep: 2, totalSteps: 10) {
            VStack(spacing: 32) {
                Text("How old is your child?")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)
                
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
                
                Spacer()
                
                OBPrimaryButton(title: "Continue") {
                    appState.childAge = selectedAge
                    if selectedAge != nil {
                        appState.nextOnboardingPage()
                    }
                }
                .disabled(selectedAge == nil)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - OB Age Motivation 页：根据年龄显示不同激励文案

struct OBAgeMotivationPage: View {
    @Environment(AppState.self) private var appState
    
    private var motivationText: String {
        guard let age = appState.childAge else { return "Let's start the journey!" }
        switch age {
        case .under3:
            return "Perfect time to spark imagination and early learning!"
        case .age3_5:
            return "Great age for storytelling adventures and creativity!"
        case .age6_7:
            return "Ready for exciting stories and reading exploration!"
        case .age8Plus:
            return "Time for engaging stories that inspire and challenge!"
        }
    }
    
    var body: some View {
        OBPageLayout(currentStep: 3, totalSteps: 10) {
            VStack(spacing: 32) {
                Spacer()
                Text(motivationText)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Spacer()
                OBPrimaryButton(title: "Continue") {
                    appState.nextOnboardingPage()
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - OB 第 3 页：性别

struct OBGenderPage: View {
    @Environment(AppState.self) private var appState
    @State private var selectedGender: ChildGender?
    
    var body: some View {
        OBPageLayout(currentStep: 4, totalSteps: 10) {
            VStack(spacing: 32) {
                Text("What is your child's gender?")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)
                
                HStack(spacing: 16) {
                    OBGenderCard(
                        title: "Boy",
                        icon: "person.fill",
                        iconColor: Color(hex: "4ECDC4"),
                        isSelected: selectedGender == .boy
                    ) { selectedGender = .boy }
                    
                    OBGenderCard(
                        title: "Girl",
                        icon: "heart.fill",
                        iconColor: Color(hex: "FF6B9D"),
                        isSelected: selectedGender == .girl
                    ) { selectedGender = .girl }
                }
                
                Spacer()
                
                OBPrimaryButton(title: "Continue") {
                    appState.childGender = selectedGender
                    if selectedGender != nil {
                        appState.nextOnboardingPage()
                    }
                }
                .disabled(selectedGender == nil)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - OB 第 4 页：头像

struct OBAvatarPage: View {
    @Environment(AppState.self) private var appState
    @State private var selectedAvatar: AvatarOption?
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        OBPageLayout(currentStep: 5, totalSteps: 10) {
            VStack(spacing: 32) {
                Text("Choose your child's avatar")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)
                
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(AvatarOption.allCases, id: \.self) { avatar in
                        OBAvatarCell(
                            avatar: avatar,
                            isSelected: selectedAvatar == avatar
                        ) { selectedAvatar = avatar }
                    }
                }
                .frame(height: 230)
                
                Spacer()
                
                OBPrimaryButton(title: "Continue") {
                    appState.childAvatar = selectedAvatar
                    if selectedAvatar != nil {
                        appState.nextOnboardingPage()
                    }
                }
                .disabled(selectedAvatar == nil)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - OB 第 5 页：名字

struct OBNamePage: View {
    @Environment(AppState.self) private var appState
    @State private var nameText: String = ""
    
    var body: some View {
        OBPageLayout(currentStep: 6, totalSteps: 10) {
            VStack(spacing: 32) {
                Text("Your child's name")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)
                
                TextField("Enter name", text: $nameText)
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.textOnLight)
                    .padding(.horizontal, 20)
                    .frame(height: 56)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 24))
                    .shadow(color: AppTheme.shadowColor, radius: 12, x: 0, y: 2)
                    .colorScheme(.light)
                
                Spacer()
                
                OBPrimaryButton(title: "Continue") {
                    appState.childName = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        appState.nextOnboardingPage()
                    }
                }
                .disabled(nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - OB Name Motivation 页：Get ready for x's reading journey!

struct OBNameMotivationPage: View {
    @Environment(AppState.self) private var appState
    
    private var childName: String {
        let name = appState.childName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "your child" : name
    }
    
    var body: some View {
        OBPageLayout(currentStep: 7, totalSteps: 10) {
            VStack(spacing: 32) {
                Spacer()
                Text("Get ready for \(childName)'s reading journey!")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Spacer()
                OBPrimaryButton(title: "Continue") {
                    appState.nextOnboardingPage()
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - OB 第 6 页：Who are you to (child name)?

struct OBRelationshipPage: View {
    @Environment(AppState.self) private var appState
    @State private var selectedRelationship: ChildRelationship?
    
    private var childName: String {
        let name = appState.childName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "your child" : name
    }
    
    var body: some View {
        OBPageLayout(currentStep: 8, totalSteps: 10) {
            VStack(spacing: 32) {
                Text("Who are you to \(childName)?")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)
                
                VStack(spacing: 16) {
                    ForEach(ChildRelationship.allCases, id: \.self) { rel in
                        OBSelectableRow(
                            title: rel.rawValue,
                            isSelected: selectedRelationship == rel
                        ) {
                            selectedRelationship = rel
                        }
                    }
                }
                
                Spacer()
                
                OBPrimaryButton(title: "Continue") {
                    appState.childRelationship = selectedRelationship
                    if selectedRelationship != nil {
                        appState.nextOnboardingPage()
                    }
                }
                .disabled(selectedRelationship == nil)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - OB Relationship Motivation 页：展示大人和小孩图标，文案 x and x

struct OBRelationshipMotivationPage: View {
    @Environment(AppState.self) private var appState
    
    private var childName: String {
        let name = appState.childName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "your child" : name
    }
    
    private var relationshipText: String {
        guard let rel = appState.childRelationship else { return "Parent" }
        return rel.rawValue
    }
    
    private var adultIcon: String {
        guard let rel = appState.childRelationship else { return "person.fill" }
        switch rel {
        case .mom: return "person.fill"
        case .dad: return "person.fill"
        case .grandparent: return "person.2.fill"
        case .teacher: return "person.badge.shield.checkmark.fill"
        case .other: return "person.fill"
        }
    }
    
    var body: some View {
        OBPageLayout(currentStep: 9, totalSteps: 10) {
            VStack(spacing: 40) {
                Spacer()
                HStack(spacing: 32) {
                    // Adult icon
                    Image(systemName: adultIcon)
                        .font(.system(size: 64))
                        .foregroundStyle(AppTheme.primary)
                        .frame(width: 100, height: 100)
                        .background(AppTheme.primary.opacity(0.15), in: Circle())
                    // Child icon
                    Image(systemName: "face.smiling")
                        .font(.system(size: 64))
                        .foregroundStyle(Color(hex: "FF6B9D"))
                        .frame(width: 100, height: 100)
                        .background(Color(hex: "FF6B9D").opacity(0.15), in: Circle())
                }
                Text("\(relationshipText) and \(childName)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                Spacer()
                OBPrimaryButton(title: "Continue") {
                    appState.nextOnboardingPage()
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - OB Personalizing 页：进度条 0-100%

struct OBPersonalizingPage: View {
    @Environment(AppState.self) private var appState
    @State private var progress: Double = 0.0
    
    var body: some View {
        ZStack {
            AppTheme.bgPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                Text("Personalizing...")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.secondary.opacity(0.3))
                            .frame(height: 12)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.primary)
                            .frame(width: geo.size.width * CGFloat(progress), height: 12)
                    }
                }
                .frame(height: 12)
                .frame(width: 280)
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                
                Spacer()
            }
            .padding(32)
        }
        .onAppear {
            withAnimation(.linear(duration: 2.5)) {
                progress = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                appState.nextOnboardingPage()
            }
        }
    }
}

// MARK: - 通用布局

struct OBPageLayout<Content: View>: View {
    let currentStep: Int
    var totalSteps: Int = 10
    var showBackButton: Bool = true
    @Environment(AppState.self) private var appState
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        ZStack {
            AppTheme.bgPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部固定区域：返回按钮 + 进度条
                VStack(spacing: 0) {
                    HStack {
                        if showBackButton {
                            Button(action: { appState.previousOnboardingPage() }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                    .frame(height: 60)
                    
                    OBProgressBar(currentStep: currentStep, totalSteps: totalSteps)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 24)
                        .frame(height: 40)
                }
                .frame(height: 100)
                
                // 主视觉区域：统一高度，内容居中
                GeometryReader { geo in
                    ScrollView {
                        content()
                            .frame(minHeight: geo.size.height)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
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
                    .foregroundStyle(AppTheme.textOnLight)
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
                    .foregroundStyle(AppTheme.textOnLight)
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
