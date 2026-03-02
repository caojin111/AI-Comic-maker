//
//  SettingsView.swift
//  AI Picture Book
//
//  Settings: Privacy Policy, Terms of Use, Contact Us (English).
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
        case rateUs = "Rate Us"
        case privacy = "Privacy Policy"
        case terms = "Terms of Use"
        case contact = "Contact Us"
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(SettingsItem.allCases, id: \.self) { item in
                    Button(action: { 
                        print("[SettingsView] 点击了：\(item.rawValue)")
                        if item == .rateUs {
                            print("[SettingsView] Rate Us 被点击")
                            dismiss()
                            // 延迟显示评分弹窗，确保设置页面已完全关闭
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                appState.showRateUs = true
                                print("[SettingsView] 显示评分弹窗")
                            }
                        } else if item == .contact {
                            print("[SettingsView] Contact Us 被点击")
                            if MFMailComposeViewController.canSendMail() {
                                showMailComposer = true
                                print("[SettingsView] 显示邮件编辑器")
                            } else {
                                // 设备不支持发送邮件，打开邮件应用
                                print("[SettingsView] 设备不支持邮件编辑器，打开邮件应用")
                                if let url = URL(string: "mailto:dxycj250@gmail.com?subject=AI%20Picture%20Book%20Contact") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        } else {
                            print("[SettingsView] 其他选项被点击，设置 selectedItem")
                            selectedItem = item
                        }
                    }) {
                        HStack {
                            Text(item.rawValue)
                                .foregroundStyle(AppTheme.textOnLight)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(AppTheme.font(size: 14))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                }
            }
            .listStyle(.insetGrouped)
            .background(AppTheme.bgPrimary)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                    .foregroundStyle(AppTheme.primary)
                }
            }
            .sheet(item: $selectedItem) { item in
                print("[SettingsView] sheet(item:) 被触发，item: \(item.rawValue)")
                return SettingsDetailView(item: item)
            }
            .sheet(isPresented: $showMailComposer) {
                print("[SettingsView] sheet(isPresented:) 被触发，显示邮件编辑器")
                return MailComposeView(
                    recipients: ["dxycj250@gmail.com"],
                    subject: "AI Picture Book Contact",
                    body: "Hello,\n\n",
                    result: $mailResult
                )
            }
            .onChange(of: selectedItem) { oldValue, newValue in
                print("[SettingsView] selectedItem 变化: \(oldValue?.rawValue ?? "nil") -> \(newValue?.rawValue ?? "nil")")
            }
            .onChange(of: showMailComposer) { oldValue, newValue in
                print("[SettingsView] showMailComposer 变化: \(oldValue) -> \(newValue)")
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct SettingsDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let item: SettingsView.SettingsItem

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(detailContent)
                    .font(AppTheme.font(size: 15))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(item.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                    .foregroundStyle(AppTheme.primary)
                }
            }
        }
    }

    private var detailContent: String {
        switch item {
        case .rateUs:
            return "" // Rate Us 不需要详情页，直接打开评分弹窗
        case .privacy:
            return """
            Privacy Policy
            
            Effective Date: March 1, 2025
            Last Updated: March 1, 2025
            
            LazyCat ("we," "us," or "our") operates the AI Picture Book mobile application (the "App"). This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our App.
            
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
            
            Our App is designed for children. We comply with applicable children's privacy laws, including COPPA (Children's Online Privacy Protection Act). We:
            • Only collect minimal information necessary for app functionality
            • Do not knowingly collect personal information from children without parental consent
            • Do not share children's information with third parties
            • Allow parents to review and delete their child's information
            
            5. Third-Party Services
            
            We use the following third-party services:
            • AI content generation services (for creating stories and images)
            • Analytics services (to improve app performance)
            • Payment processing (for in-app purchases)
            
            These services have their own privacy policies and we encourage you to review them.
            
            6. Your Rights
            
            You have the right to:
            • Access your data stored in the App
            • Delete your data at any time
            • Opt out of data collection (though this may limit app functionality)
            • Contact us with privacy concerns
            
            7. Data Retention
            
            • Stories and user data are stored locally on your device
            • You can delete stories and data at any time through the App
            • Server-side data is retained only as long as necessary for service provision
            
            8. Changes to This Privacy Policy
            
            We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy in the App and updating the "Last Updated" date.
            
            9. Contact Us
            
            If you have questions or concerns about this Privacy Policy, please contact us:
            
            LazyCat
            Email: dxycj250@gmail.com
            
            By using AI Picture Book, you agree to the collection and use of information in accordance with this Privacy Policy.
            """
        case .terms:
            return """
            Terms of Use
            
            Effective Date: March 1, 2025
            Last Updated: March 1, 2025
            
            Welcome to AI Picture Book! These Terms of Use ("Terms") govern your use of the AI Picture Book mobile application (the "App") operated by LazyCat ("we," "us," or "our").
            
            By downloading, installing, or using the App, you agree to be bound by these Terms. If you do not agree to these Terms, please do not use the App.
            
            1. License to Use
            
            We grant you a limited, non-exclusive, non-transferable, revocable license to use the App for personal, non-commercial purposes in accordance with these Terms.
            
            You may not:
            • Modify, copy, or create derivative works of the App
            • Reverse engineer, decompile, or disassemble the App
            • Remove any copyright or proprietary notices
            • Use the App for any illegal or unauthorized purpose
            • Sell, rent, lease, or sublicense the App
            
            2. User Content
            
            Stories and Content:
            • Stories generated through the App are for your personal, non-commercial use
            • You retain ownership of any personal information you provide
            • AI-generated content (stories and images) is created specifically for you
            • You may not redistribute or commercially exploit generated content
            
            3. Subscription and Payments
            
            In-App Purchases:
            • The App offers in-app purchases for premium features
            • Prices are displayed in the App and may vary by region
            • Payment will be charged to your Apple ID account
            • Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period
            • You can manage subscriptions in your App Store account settings
            
            Refunds:
            • Refund requests are handled through the App Store
            • We do not guarantee refunds for in-app purchases
            
            4. AI-Generated Content
            
            • Stories and images are generated using artificial intelligence
            • We strive for age-appropriate and safe content, but cannot guarantee perfection
            • Parents should review generated content before sharing with children
            • We are not responsible for any content that may be deemed inappropriate
            • You can report inappropriate content through the App
            
            5. Intellectual Property
            
            • The App, including its design, features, and functionality, is owned by LazyCat
            • All trademarks, logos, and service marks are our property
            • AI-generated stories are created for your personal use
            • You may not use our intellectual property without written permission
            
            6. Disclaimer of Warranties
            
            THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO:
            • Warranties of merchantability or fitness for a particular purpose
            • Warranties that the App will be uninterrupted or error-free
            • Warranties regarding the accuracy or reliability of content
            
            7. Limitation of Liability
            
            TO THE MAXIMUM EXTENT PERMITTED BY LAW, LAZYCAT SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO:
            • Loss of profits or data
            • Service interruptions
            • Errors in AI-generated content
            
            8. Parental Responsibility
            
            • This App is designed for children under parental supervision
            • Parents are responsible for monitoring their child's use of the App
            • Parents should review generated stories before sharing with children
            • We recommend setting appropriate device restrictions
            
            9. Service Availability
            
            • We strive to provide continuous service but do not guarantee uninterrupted access
            • We may suspend or terminate service for maintenance or updates
            • We reserve the right to modify or discontinue features at any time
            
            10. Termination
            
            We may terminate or suspend your access to the App immediately, without prior notice, if you:
            • Violate these Terms
            • Engage in fraudulent or illegal activities
            • Abuse or misuse the App
            
            You may terminate your use of the App at any time by deleting it from your device.
            
            11. Changes to Terms
            
            We reserve the right to modify these Terms at any time. We will notify you of any changes by:
            • Posting the updated Terms in the App
            • Updating the "Last Updated" date
            • Sending an in-app notification (for significant changes)
            
            Your continued use of the App after changes constitutes acceptance of the new Terms.
            
            12. Governing Law
            
            These Terms shall be governed by and construed in accordance with the laws of your jurisdiction, without regard to its conflict of law provisions.
            
            13. Contact Us
            
            If you have any questions about these Terms, please contact us:
            
            LazyCat
            Email: dxycj250@gmail.com
            
            14. Severability
            
            If any provision of these Terms is found to be unenforceable or invalid, that provision shall be limited or eliminated to the minimum extent necessary, and the remaining provisions shall remain in full force and effect.
            
            15. Entire Agreement
            
            These Terms constitute the entire agreement between you and LazyCat regarding the use of the App and supersede all prior agreements and understandings.
            
            By using AI Picture Book, you acknowledge that you have read, understood, and agree to be bound by these Terms of Use.
            """
        case .contact:
            return "" // Contact Us 直接发送邮件，不需要详情页
        }
    }
}

extension SettingsView.SettingsItem: Identifiable {
    var id: String { rawValue }
}

#Preview {
    SettingsView()
}
