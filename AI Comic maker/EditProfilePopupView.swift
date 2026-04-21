//
//  EditProfilePopupView.swift
//  AI Comic maker
//
//  编辑头像和姓名的弹窗
//

import SwiftUI
import MessageUI

struct EditProfilePopupView: View {
    @Binding var isPresented: Bool
    @Environment(AppState.self) private var appState
    @State private var selectedAvatar: AvatarOption?
    @State private var nameText: String = ""
    @State private var selectedSettingsItem: SettingsView.SettingsItem?
    @State private var showMailComposer = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
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
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Edit Profile")
                            .font(AppTheme.fontBold(size: 24))
                            .foregroundStyle(.white)
                        Text("Customize your avatar & name")
                            .font(AppTheme.font(size: 13))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    Spacer()
                    Button(action: { isPresented = false }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.25))
                                .frame(width: 36, height: 36)
                            Image(systemName: "xmark")
                                .font(AppTheme.font(size: 14))
                                .foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .frame(height: 80)
            
            // Content
            VStack(spacing: 20) {
                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(AppTheme.fontBold(size: 15))
                        .foregroundStyle(Color(hex: "5D4E37"))
                    
                    TextField("Enter your name", text: $nameText)
                        .font(AppTheme.font(size: 16))
                        .foregroundStyle(Color(hex: "5D4E37"))
                        .padding(.horizontal, 16)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: "F5E6D3"), lineWidth: 1.5)
                        )
                }
                
                // Avatar selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Avatar")
                        .font(AppTheme.fontBold(size: 15))
                        .foregroundStyle(Color(hex: "5D4E37"))
                    
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(AvatarOption.allCases, id: \.self) { avatar in
                            Button(action: { selectedAvatar = avatar }) {
                                ZStack {
                                    // 选中状态的背景光晕
                                    Circle()
                                        .fill(Color(hex: "FF6A88").opacity(selectedAvatar == avatar ? 0.2 : 0))
                                        .frame(width: 68, height: 68)
                                    
                                    // 头像圆形
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(hex: avatar.color).opacity(0.8), Color(hex: avatar.color)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                        
                                        // Lottie 动画
                                        LottieView(
                                            animationName: avatar.lottieAnimationName,
                                            subdirectory: "lottie",
                                            contentMode: .scaleAspectFit
                                        )
                                        .frame(width: 64, height: 64)
                                    }
                                    .frame(width: 56, height: 56)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    
                                    // 选中状态的勾选标记
                                    VStack {
                                        HStack {
                                            Spacer()
                                            ZStack {
                                                Circle()
                                                    .fill(Color(hex: "FF6A88"))
                                                    .frame(width: 20, height: 20)
                                                Image(systemName: "checkmark")
                                                    .font(AppTheme.fontBold(size: 10))
                                                    .foregroundStyle(.white)
                                            }
                                            .opacity(selectedAvatar == avatar ? 1 : 0)
                                            .offset(x: 4, y: -4)
                                        }
                                        Spacer()
                                    }
                                    .frame(width: 56, height: 56)
                                }
                                .frame(width: 68, height: 68)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedAvatar)
                            }
                            .buttonStyle(ClickSoundButtonStyle())
                        }
                    }
                }
                
                // Save button
                Button(action: {
                    print("[EditProfilePopupView] 保存前 - 当前头像：\(appState.childAvatar?.rawValue ?? "nil")")
                    print("[EditProfilePopupView] 保存前 - 选中头像：\(selectedAvatar?.rawValue ?? "nil")")
                    print("[EditProfilePopupView] 保存前 - 姓名：\(nameText)")
                    
                    if let avatar = selectedAvatar {
                        appState.childAvatar = avatar
                        print("[EditProfilePopupView] 已设置头像为：\(avatar.rawValue)")
                        print("[EditProfilePopupView] AppStorage 值：\(appState.childAvatarRaw)")
                        print("[EditProfilePopupView] 验证读取：\(appState.childAvatar?.rawValue ?? "nil")")
                    }
                    if !nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        appState.childName = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
                        print("[EditProfilePopupView] 已设置姓名为：\(appState.childName)")
                    }
                    
                    print("[EditProfilePopupView] 保存后 - 当前头像：\(appState.childAvatar?.rawValue ?? "nil")")
                    
                    // 延迟关闭，确保数据已保存
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPresented = false
                    }
                }) {
                    Text("Save Changes")
                        .font(AppTheme.fontBold(size: 16))
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
                
                // 设置选项
                VStack(spacing: 8) {
                    ForEach(SettingsView.SettingsItem.allCases, id: \.self) { item in
                        Button(action: {
                            print("[EditProfilePopupView] 点击了：\(item.rawValue)")
                            if item == .rateUs {
                                print("[EditProfilePopupView] Rate Us 被点击")
                                isPresented = false
                                // 延迟显示评分弹窗，确保编辑弹窗已完全关闭
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    appState.showRateUs = true
                                    print("[EditProfilePopupView] 显示评分弹窗")
                                }
                            } else if item == .contact {
                                print("[EditProfilePopupView] Contact Us 被点击")
                                if MFMailComposeViewController.canSendMail() {
                                    showMailComposer = true
                                    print("[EditProfilePopupView] 显示邮件编辑器")
                                } else {
                                    print("[EditProfilePopupView] 设备不支持邮件编辑器，打开邮件应用")
                                    if let url = URL(string: "mailto:dxycj250@gmail.com?subject=AI%20Comic%20maker%20Contact") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            } else {
                                print("[EditProfilePopupView] 其他选项被点击，设置 selectedSettingsItem")
                                selectedSettingsItem = item
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: iconForSettingsItem(item))
                                    .font(AppTheme.font(size: 16))
                                    .foregroundStyle(Color(hex: "8B7355"))
                                    .frame(width: 24)
                                
                                Text(item.rawValue)
                                    .font(AppTheme.font(size: 15))
                                    .foregroundStyle(Color(hex: "5D4E37"))
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(AppTheme.font(size: 12))
                                    .foregroundStyle(Color(hex: "D4A574"))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                            )
                        }
                        .buttonStyle(ClickSoundButtonStyle())
                    }
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
        .sheet(item: $selectedSettingsItem) { item in
            SettingsDetailView(item: item)
        }
        .sheet(isPresented: $showMailComposer) {
            MailComposeView(
                recipients: ["dxycj250@gmail.com"],
                subject: "AI Comic maker Contact",
                body: "Hello,\n\n",
                result: $mailResult
            )
        }
        .onAppear {
            selectedAvatar = appState.childAvatar
            nameText = appState.childName
        }
    }
    
    private func iconForSettingsItem(_ item: SettingsView.SettingsItem) -> String {
        switch item {
        case .rateUs: return "star.fill"
        case .privacy: return "lock.shield.fill"
        case .terms: return "doc.text.fill"
        case .contact: return "envelope.fill"
        }
    }
}

#Preview {
    EditProfilePopupView(isPresented: .constant(true))
        .environment(AppState.shared)
}

