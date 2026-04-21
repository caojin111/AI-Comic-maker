//
//  RoleCard.swift
//  AI Comic maker
//
//  角色卡片组件

import SwiftUI

struct RoleCard: View {
    let character: Character
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // 角色图片
                ZStack {
                    if let imageUrl = CharacterStorage.shared.getImageUrl(for: character),
                       let imageData = try? Data(contentsOf: imageUrl),
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "FF1493"), Color(hex: "00D9FF")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(AppTheme.font(size: 28))
                                    .foregroundStyle(.white)
                            )
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: 2.5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "FF1493"), lineWidth: 1)
                )
                .shadow(color: Color(hex: "FF1493").opacity(0.4), radius: 8, x: 0, y: 3)

                // 角色信息
                VStack(alignment: .leading, spacing: 6) {
                    Text(character.name)
                        .font(AppTheme.fontBold(size: 16))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(AppTheme.font(size: 10))
                        Text(character.formattedDate)
                            .font(AppTheme.font(size: 11))
                    }
                    .foregroundStyle(Color(hex: "808080"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 删除按钮（直接显示，无省略号）
                Button(action: { showDeleteConfirm = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "FF4444"))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color(hex: "FF4444").opacity(0.12))
                        )
                }
                .buttonStyle(ClickSoundButtonStyle())
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "1A1F2E"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.black, lineWidth: 3)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(hex: "FF1493"), lineWidth: 1.5)
                    )
                    .shadow(color: Color(hex: "FF1493").opacity(0.3), radius: 8, x: 0, y: 3)
            )
        }
        .buttonStyle(ClickSoundButtonStyle())
        .alert("Delete Role?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("Sure to delete this role?")
        }
    }
}

#Preview {
    RoleCard(
        character: Character(name: "Hero", imageUrl: ""),
        onTap: {},
        onDelete: {}
    )
}
