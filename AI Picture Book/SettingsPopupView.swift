//
//  SettingsPopupView.swift
//  AI Picture Book
//
//  Settings as centered popup: 全新温馨设计
//

import SwiftUI
import MessageUI

struct SettingsPopupView: View {
    @Binding var isPresented: Bool
    @Environment(AppState.self) private var appState
    @State private var selectedItem: SettingsView.SettingsItem?
    @State private var showMailComposer = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?

    private func icon(for item: SettingsView.SettingsItem) -> String {
        switch item {
        case .rateUs: return "star.fill"
        case .privacy: return "lock.shield.fill"
        case .terms: return "doc.text.fill"
        case .contact: return "envelope.fill"
        }
    }

    private func iconGradient(for item: SettingsView.SettingsItem) -> LinearGradient {
        switch item {
        case .rateUs:
            return LinearGradient(
                colors: [Color(hex: "FFB84D"), Color(hex: "FF9A8B")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .privacy: 
            return LinearGradient(
                colors: [Color(hex: "A8E6CF"), Color(hex: "81C784")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .terms: 
            return LinearGradient(
                colors: [Color(hex: "9FA8DA"), Color(hex: "7986CB")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .contact: 
            return LinearGradient(
                colors: [Color(hex: "FF9A8B"), Color(hex: "FF6A88")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with gradient background
            ZStack {
                UnevenRoundedRectangle(
                    topLeadingRadius: 26,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 26
                )
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FFE8DC"), Color(hex: "FFD6C8")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(2)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Settings")
                            .font(AppTheme.fontBold(size: 24))
                            .foregroundStyle(Color(hex: "5D4E37"))
                        Text("Manage your preferences")
                            .font(AppTheme.font(size: 13))
                            .foregroundStyle(Color(hex: "8B7355"))
                    }
                    Spacer()
                    Button(action: { isPresented = false }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.9))
                                .frame(width: 36, height: 36)
                            Image(systemName: "xmark")
                                .font(AppTheme.font(size: 14))
                                .foregroundStyle(Color(hex: "8B7355"))
                        }
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .frame(height: 80)

            // Rows with beautiful cards
            VStack(spacing: 12) {
                ForEach(SettingsView.SettingsItem.allCases, id: \.self) { item in
                    Button(action: {
                        print("[SettingsPopupView] 点击了：\(item.rawValue)")
                        if item == .rateUs {
                            print("[SettingsPopupView] Rate Us 被点击")
                            isPresented = false
                            // 延迟显示评分弹窗，确保设置弹窗已完全关闭
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                appState.showRateUs = true
                                print("[SettingsPopupView] 显示评分弹窗")
                            }
                        } else if item == .contact {
                            print("[SettingsPopupView] Contact Us 被点击")
                            if MFMailComposeViewController.canSendMail() {
                                showMailComposer = true
                                print("[SettingsPopupView] 显示邮件编辑器")
                            } else {
                                // 设备不支持发送邮件，打开邮件应用
                                print("[SettingsPopupView] 设备不支持邮件编辑器，打开邮件应用")
                                if let url = URL(string: "mailto:dxycj250@gmail.com?subject=AI%20Picture%20Book%20Contact") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        } else {
                            print("[SettingsPopupView] 其他选项被点击，设置 selectedItem")
                            selectedItem = item
                        }
                    }) {
                        HStack(spacing: 16) {
                            // Icon with gradient background
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(iconGradient(for: item))
                                    .frame(width: 52, height: 52)
                                Image(systemName: icon(for: item))
                                    .font(AppTheme.font(size: 22))
                                    .foregroundStyle(.white)
                            }
                            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.rawValue)
                                    .font(AppTheme.fontBold(size: 17))
                                    .foregroundStyle(Color(hex: "5D4E37"))
                                Text(subtitle(for: item))
                                    .font(AppTheme.font(size: 12))
                                    .foregroundStyle(Color(hex: "A0826D"))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(AppTheme.font(size: 14))
                                .foregroundStyle(Color(hex: "D4A574"))
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color(hex: "F5E6D3"), lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
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
        .sheet(item: $selectedItem) { item in
            print("[SettingsPopupView] sheet(item:) 被触发，item: \(item.rawValue)")
            return SettingsDetailView(item: item)
        }
        .sheet(isPresented: $showMailComposer) {
            print("[SettingsPopupView] sheet(isPresented:) 被触发，显示邮件编辑器")
            return MailComposeView(
                recipients: ["dxycj250@gmail.com"],
                subject: "AI Picture Book Contact",
                body: "Hello,\n\n",
                result: $mailResult
            )
        }
        .onChange(of: selectedItem) { oldValue, newValue in
            print("[SettingsPopupView] selectedItem 变化: \(oldValue?.rawValue ?? "nil") -> \(newValue?.rawValue ?? "nil")")
        }
        .onChange(of: showMailComposer) { oldValue, newValue in
            print("[SettingsPopupView] showMailComposer 变化: \(oldValue) -> \(newValue)")
        }
    }
    
    private func subtitle(for item: SettingsView.SettingsItem) -> String {
        switch item {
        case .rateUs: return "Share your feedback"
        case .privacy: return "Your data protection"
        case .terms: return "Terms of service"
        case .contact: return "Get in touch with us"
        }
    }
}
