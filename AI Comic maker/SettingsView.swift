//
//  SettingsView.swift
//  AI Comic maker
//

import SwiftUI
import MessageUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var selectedItem: SettingsItem?
    @State private var showMailComposer = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?

    enum SettingsItem: String, CaseIterable {
        case rateUs  = "Rate Us"
        case privacy = "Privacy Policy"
        case terms   = "Terms of Use"
        case contact = "Contact Us"

        var icon: String {
            switch self {
            case .rateUs:  return "star.fill"
            case .privacy: return "lock.shield.fill"
            case .terms:   return "doc.text.fill"
            case .contact: return "envelope.fill"
            }
        }

        var iconColor: String {
            switch self {
            case .rateUs:  return "FFD700"
            case .privacy: return "00D9FF"
            case .terms:   return "FF69B4"
            case .contact: return "FF1493"
            }
        }
    }

    var body: some View {
        ZStack {
            Color(hex: "0A0E1A").ignoresSafeArea()

            // 背景装饰
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(Color(hex: "FF1493").opacity(0.05))
                        .frame(width: 280, height: 280)
                        .offset(x: geo.size.width - 80, y: -60)
                    Circle()
                        .fill(Color(hex: "00D9FF").opacity(0.04))
                        .frame(width: 220, height: 220)
                        .offset(x: -60, y: geo.size.height - 160)
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部栏
                HStack {
                    Button(action: { dismiss() }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "1A1F2E"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: "FF1493"), lineWidth: 1)
                                )
                                .frame(width: 40, height: 40)
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color(hex: "FF1493"))
                        }
                    }
                    .buttonStyle(ClickSoundButtonStyle())

                    Spacer()

                    Text("Settings")
                        .font(AppTheme.fontRowdiesBold(size: 20))
                        .foregroundStyle(Color.white)

                    Spacer()

                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)

                // 菜单项
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(SettingsItem.allCases, id: \.self) { item in
                            SettingsRow(item: item) {
                                handleTap(item)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(item: $selectedItem) { item in
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
        .presentationDetents([.medium, .large])
    }

    private func handleTap(_ item: SettingsItem) {
        switch item {
        case .rateUs:
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                appState.showRateUs = true
            }
        case .contact:
            if MFMailComposeViewController.canSendMail() {
                showMailComposer = true
            } else {
                if let url = URL(string: "mailto:dxycj250@gmail.com?subject=AI%20Comic%20maker%20Contact") {
                    UIApplication.shared.open(url)
                }
            }
        default:
            selectedItem = item
        }
    }
}

// MARK: - 菜单行

private struct SettingsRow: View {
    let item: SettingsView.SettingsItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // 图标
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: item.iconColor).opacity(0.15))
                        .frame(width: 40, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: item.iconColor).opacity(0.3), lineWidth: 1)
                        )
                    Image(systemName: item.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: item.iconColor))
                }

                Text(item.rawValue)
                    .font(AppTheme.fontBold(size: 15))
                    .foregroundStyle(Color.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "3A3F55"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hex: "1A1F2E"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.black, lineWidth: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(hex: item.iconColor).opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ClickSoundButtonStyle())
    }
}

// MARK: - 详情页

struct SettingsDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let item: SettingsView.SettingsItem

    var body: some View {
        ZStack {
            Color(hex: "0A0E1A").ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部栏
                HStack {
                    Button(action: { dismiss() }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "1A1F2E"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: "FF1493"), lineWidth: 1)
                                )
                                .frame(width: 40, height: 40)
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color(hex: "FF1493"))
                        }
                    }
                    .buttonStyle(ClickSoundButtonStyle())

                    Spacer()

                    Text(item.rawValue)
                        .font(AppTheme.fontRowdiesBold(size: 18))
                        .foregroundStyle(Color.white)

                    Spacer()

                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    Text(detailContent)
                        .font(AppTheme.font(size: 14))
                        .foregroundStyle(Color(hex: "B0B0B0"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(hex: "1A1F2E"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var detailContent: String {
        switch item {
        case .rateUs: return ""
        case .contact: return ""
        case .privacy:
            return """
            Privacy Policy

            Effective Date: March 1, 2025
            Last Updated: March 1, 2025

            LazyCat ("we," "us," or "our") operates the AI Comic maker mobile application (the "App"). This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our App.

            1. Information We Collect

            Personal Information:
            • Child's name (optional, for personalization)
            • Child's age range (for age-appropriate content)
            • Child's gender (for story customization)
            • Avatar selection
            • Your relationship to the child

            Usage Information:
            • Stories created and saved
            • App usage patterns and preferences
            • Device information (model, OS version)
            • Crash reports and performance data

            2. How We Use Your Information

            We use the collected information to:
            • Personalize story content for your child
            • Generate AI-powered stories and images
            • Improve app functionality and user experience
            • Provide customer support
            • Send important updates about the App

            3. Data Storage and Security

            • Most data is stored locally on your device
            • Story generation requests are processed on our secure servers
            • We use industry-standard encryption to protect your data
            • We do not sell or share your personal information with third parties for marketing purposes

            4. Children's Privacy

            Our App is designed for children. We comply with applicable children's privacy laws, including COPPA. We:
            • Only collect minimal information necessary for app functionality
            • Do not knowingly collect personal information from children without parental consent
            • Do not share children's information with third parties
            • Allow parents to review and delete their child's information

            5. Contact Us

            LazyCat
            Email: dxycj250@gmail.com
            """
        case .terms:
            return """
            Terms of Use

            Effective Date: March 1, 2025
            Last Updated: March 1, 2025

            Welcome to AI Comic maker! These Terms of Use govern your use of the App operated by LazyCat.

            1. License to Use

            We grant you a limited, non-exclusive, non-transferable, revocable license to use the App for personal, non-commercial purposes.

            You may not:
            • Modify, copy, or create derivative works of the App
            • Reverse engineer or decompile the App
            • Use the App for any illegal or unauthorized purpose
            • Sell, rent, or sublicense the App

            2. In-App Purchases

            • Payment will be charged to your Apple ID account
            • Subscriptions automatically renew unless canceled 24 hours before the end of the current period
            • Refund requests are handled through the App Store

            3. AI-Generated Content

            • Stories and images are generated using artificial intelligence
            • Parents should review generated content before sharing with children
            • We are not responsible for any content that may be deemed inappropriate

            4. Limitation of Liability

            TO THE MAXIMUM EXTENT PERMITTED BY LAW, LAZYCAT SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES.

            5. Contact Us

            LazyCat
            Email: dxycj250@gmail.com

            Standard Apple EULA: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
            """
        }
    }
}

extension SettingsView.SettingsItem: Identifiable {
    var id: String { rawValue }
}

#Preview {
    SettingsView()
}
