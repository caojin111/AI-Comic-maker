//
//  RateUsView.swift
//  AI Picture Book
//
//  评分弹窗：用户选择1-5星，4-5星跳转App Store，1-3星展开反馈输入框
//

import SwiftUI
import MessageUI

struct RateUsView: View {
    @Binding var isPresented: Bool
    @Environment(AppState.self) private var appState
    @State private var selectedRating: Int = 0
    @State private var showFeedbackInput = false
    @State private var feedbackText = ""
    @State private var showMailComposer = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    if !showFeedbackInput {
                        isPresented = false
                    }
                }
            
            // 弹窗内容
            VStack(spacing: 24) {
                // 标题
                VStack(spacing: 8) {
                    Text("Rate Our App")
                        .font(AppTheme.fontBold(size: 24))
                        .foregroundColor(Color(hex: "5D4E37"))
                    
                    Text(showFeedbackInput ? "Tell us what we can improve" : "How would you rate your experience?")
                        .font(AppTheme.font(size: 16))
                        .foregroundColor(Color(hex: "5D4E37").opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                
                // 星星评分
                HStack(spacing: 16) {
                    ForEach(1...5, id: \.self) { star in
                        Button(action: {
                            selectedRating = star
                            handleRating(star)
                        }) {
                            Image(systemName: star <= selectedRating ? "star.fill" : "star")
                                .font(.system(size: 40))
                                .foregroundColor(star <= selectedRating ? Color(hex: "FFB84D") : Color.gray.opacity(0.3))
                        }
                        .buttonStyle(ClickSoundButtonStyle())
                        .disabled(showFeedbackInput)
                    }
                }
                .padding(.vertical, 8)
                
                // 反馈输入框（1-3星时展开）
                if showFeedbackInput {
                    VStack(spacing: 12) {
                        TextEditor(text: $feedbackText)
                            .font(AppTheme.font(size: 15))
                            .foregroundColor(Color(hex: "5D4E37"))
                            .scrollContentBackground(.hidden)
                            .frame(height: 120)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "D4A574"), lineWidth: 1)
                            )
                        
                        HStack(spacing: 12) {
                            // 取消按钮
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    showFeedbackInput = false
                                    selectedRating = 0
                                    feedbackText = ""
                                }
                            }) {
                                Text("Cancel")
                                    .font(AppTheme.fontBold(size: 16))
                                    .foregroundColor(Color(hex: "8B7355"))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 24)
                                            .fill(Color.white)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 24)
                                                    .stroke(Color(hex: "D4A574"), lineWidth: 1.5)
                                            )
                                    )
                            }
                            .buttonStyle(ClickSoundButtonStyle())
                            
                            // 提交按钮
                            Button(action: {
                                submitFeedback()
                            }) {
                                Text("Submit")
                                    .font(AppTheme.fontBold(size: 16))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 24)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(hex: "A8E6CF"), Color(hex: "81C784")],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    )
                            }
                            .buttonStyle(ClickSoundButtonStyle())
                            .disabled(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // 关闭按钮（只在未展开反馈输入框时显示）
                if !showFeedbackInput {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Maybe Later")
                            .font(AppTheme.font(size: 16))
                            .foregroundColor(Color(hex: "5D4E37").opacity(0.6))
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(color: Color(hex: "D4A574").opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
        }
        .sheet(isPresented: $showMailComposer) {
            MailComposeView(
                recipients: ["dxycj250@gmail.com"],
                subject: "AI Picture Book Feedback - \(selectedRating) Stars",
                body: feedbackText,
                result: $mailResult,
                onDismiss: {
                    // 邮件编辑器关闭后显示感谢提示
                    appState.showThankYouMessage()
                }
            )
        }
        .onAppear {
            // 监听应用从后台返回
            NotificationCenter.default.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: .main
            ) { _ in
                // 如果用户从 App Store 返回，显示感谢提示
                if selectedRating >= 4 {
                    appState.showThankYouMessage()
                }
            }
        }
    }
    
    private func handleRating(_ rating: Int) {
        print("[RateUsView] 用户评分：\(rating)星")
        
        // 延迟一下让用户看到星星选中效果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if rating >= 4 {
                // 4-5星：跳转到App Store
                openAppStore()
                isPresented = false
            } else {
                // 1-3星：展开反馈输入框
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showFeedbackInput = true
                }
            }
        }
    }
    
    private func submitFeedback() {
        print("[RateUsView] 提交反馈")
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
            isPresented = false
        } else {
            print("[RateUsView] 设备不支持发送邮件，打开邮件应用")
            let emailBody = feedbackText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "mailto:dxycj250@gmail.com?subject=AI%20Picture%20Book%20Feedback%20-%20\(selectedRating)%20Stars&body=\(emailBody)") {
                UIApplication.shared.open(url)
            }
            isPresented = false
            appState.showThankYouMessage()
        }
    }
    
    private func openAppStore() {
        let appStoreURL = "https://apps.apple.com/app/id6758834751"
        if let url = URL(string: appStoreURL) {
            UIApplication.shared.open(url)
            print("[RateUsView] 打开App Store")
        }
    }
}

// MARK: - 邮件编辑器

struct MailComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let body: String
    @Binding var result: Result<MFMailComposeResult, Error>?
    var onDismiss: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(recipients)
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        
        init(_ parent: MailComposeView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                parent.result = .failure(error)
            } else {
                parent.result = .success(result)
            }
            parent.dismiss()
            parent.onDismiss?()
        }
    }
}

#Preview {
    RateUsView(isPresented: .constant(true))
}

