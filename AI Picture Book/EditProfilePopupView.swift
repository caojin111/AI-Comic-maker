//
//  EditProfilePopupView.swift
//  AI Picture Book
//
//  编辑头像和姓名的弹窗
//

import SwiftUI

struct EditProfilePopupView: View {
    @Binding var isPresented: Bool
    @Environment(AppState.self) private var appState
    @State private var selectedAvatar: AvatarOption?
    @State private var nameText: String = ""
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Profile")
                    .font(AppTheme.font(size: 20))
                    .foregroundStyle(AppTheme.textOnLight)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(AppTheme.font(size: 24))
                        .foregroundStyle(Color.gray.opacity(0.6))
                }
                .buttonStyle(ClickSoundButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 20)
            
            // Content
            VStack(spacing: 24) {
                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(AppTheme.font(size: 14))
                        .foregroundStyle(Color.gray)
                    TextField("Enter name", text: $nameText)
                        .font(AppTheme.font(size: 16))
                        .foregroundStyle(AppTheme.textOnLight)
                        .padding(.horizontal, 16)
                        .frame(height: 48)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                        .colorScheme(.light)
                }
                
                // Avatar selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Avatar")
                        .font(AppTheme.font(size: 14))
                        .foregroundStyle(Color.gray)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(AvatarOption.allCases, id: \.self) { avatar in
                            Button(action: { selectedAvatar = avatar }) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: avatar.color))
                                    LottieView(
                                        animationName: avatar.lottieAnimationName,
                                        subdirectory: "lottie",
                                        contentMode: .scaleAspectFit
                                    )
                                    .frame(width: 84, height: 84)
                                }
                                .frame(width: 70, height: 70)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(AppTheme.primary, lineWidth: selectedAvatar == avatar ? 4 : 0)
                                )
                            }
                            .buttonStyle(ClickSoundButtonStyle())
                        }
                    }
                }
                
                // Save button
                Button(action: {
                    print("[EditProfilePopupView] 保存：头像=\(selectedAvatar?.rawValue ?? "nil"), 姓名=\(nameText)")
                    if let avatar = selectedAvatar {
                        appState.childAvatar = avatar
                    }
                    if !nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        appState.childName = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    isPresented = false
                }) {
                    Text("Save")
                        .font(AppTheme.font(size: 17))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(ClickSoundButtonStyle())
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(width: 360)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.12), radius: 24, x: 0, y: 12)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.gray.opacity(0.08), lineWidth: 1))
        .onAppear {
            selectedAvatar = appState.childAvatar
            nameText = appState.childName
        }
    }
}
