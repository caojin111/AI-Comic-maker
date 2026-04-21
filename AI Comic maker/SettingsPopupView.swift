//
//  SettingsPopupView.swift
//  AI Comic maker
//

import SwiftUI
import MessageUI

struct SettingsPopupView: View {
    @Binding var isPresented: Bool
    @Environment(AppState.self) private var appState
    @State private var selectedItem: SettingsView.SettingsItem?
    @State private var showMailComposer = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?

    var body: some View {
        VStack(spacing: 0) {

            // ── Header ──
            ZStack {
                UnevenRoundedRectangle(
                    topLeadingRadius: 26, bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0, topTrailingRadius: 26
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
                        Circle().fill(Color.white.opacity(0.08)).frame(width: 90, height: 90)
                            .offset(x: geo.size.width - 20, y: -25)
                        Circle().fill(Color(hex: "00D9FF").opacity(0.12)).frame(width: 60, height: 60)
                            .offset(x: -15, y: geo.size.height - 15)
                    }
                }

                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 44, height: 44)
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Settings")
                            .font(AppTheme.fontRowdiesBold(size: 20))
                            .foregroundStyle(.white)
                        Text("Manage your preferences")
                            .font(AppTheme.font(size: 12))
                            .foregroundStyle(.white.opacity(0.85))
                    }

                    Spacer()

                    Button(action: { isPresented = false }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 32, height: 32)
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
            .frame(height: 84)
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: 26, bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0, topTrailingRadius: 26
                )
                .stroke(Color.black, lineWidth: 3)
            )

            // ── 菜单行 ──
            VStack(spacing: 10) {
                ForEach(SettingsView.SettingsItem.allCases, id: \.self) { item in
                    Button(action: { handleTap(item) }) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: item.iconColor).opacity(0.15))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color(hex: item.iconColor).opacity(0.35), lineWidth: 1)
                                    )
                                Image(systemName: item.icon)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color(hex: item.iconColor))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.rawValue)
                                    .font(AppTheme.fontBold(size: 15))
                                    .foregroundStyle(Color.white)
                                Text(subtitle(for: item))
                                    .font(AppTheme.font(size: 11))
                                    .foregroundStyle(Color(hex: "606070"))
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(hex: "3A3F55"))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(hex: "1A1F2E"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color(hex: item.iconColor).opacity(0.15), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0, bottomLeadingRadius: 26,
                    bottomTrailingRadius: 26, topTrailingRadius: 0
                )
                .fill(Color(hex: "0A0E1A"))
                .overlay(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0, bottomLeadingRadius: 26,
                        bottomTrailingRadius: 26, topTrailingRadius: 0
                    )
                    .stroke(Color.black, lineWidth: 3)
                )
                .overlay(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0, bottomLeadingRadius: 26,
                        bottomTrailingRadius: 26, topTrailingRadius: 0
                    )
                    .stroke(Color(hex: "FF1493").opacity(0.25), lineWidth: 1)
                )
            )
        }
        .frame(width: 360)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: Color(hex: "FF1493").opacity(0.25), radius: 40, x: 0, y: 20)
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
    }

    private func handleTap(_ item: SettingsView.SettingsItem) {
        switch item {
        case .rateUs:
            isPresented = false
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

    private func subtitle(for item: SettingsView.SettingsItem) -> String {
        switch item {
        case .rateUs:    return "Share your feedback"
        case .privacy:   return "Your data protection"
        case .terms:     return "Terms of service"
        case .contact:   return "Get in touch with us"
        }
    }
}
