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
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppTheme.textOnLight)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.gray.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 20)
            
            // Content
            VStack(spacing: 24) {
                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.gray)
                    TextField("Enter name", text: $nameText)
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.textOnLight)
                        .padding(.horizontal, 16)
                        .frame(height: 48)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                        .colorScheme(.light)
                }
                
                // Avatar selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Avatar")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.gray)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(AvatarOption.allCases, id: \.self) { avatar in
                            Button(action: { selectedAvatar = avatar }) {
                                Image(systemName: avatar.sfSymbolName)
                                    .font(.system(size: 32))
                                    .foregroundStyle(.white)
                                    .frame(width: 70, height: 70)
                                    .background(Color(hex: avatar.color), in: Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(AppTheme.primary, lineWidth: selectedAvatar == avatar ? 4 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
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
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
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
