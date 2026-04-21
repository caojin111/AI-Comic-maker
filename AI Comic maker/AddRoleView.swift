//
//  AddRoleView.swift
//  AI Comic maker
//

import SwiftUI
import PhotosUI
import Mixpanel

struct AddRoleView: View {
    @Binding var isPresented: Bool
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var selectedImage: UIImage?
    @State private var roleName = ""
    @State private var selectedGender: String = "Male"
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showImageSourcePicker = false
    @FocusState private var isNameFocused: Bool

    var onRoleSaved: ((Character) -> Void)?
    let genders = ["Male", "Female", "Other"]

    var body: some View {
        ZStack {
            // 背景遮罩 — 点击只收起键盘，不关闭弹窗
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { isNameFocused = false }

            // 弹窗卡片
            VStack(spacing: 0) {

                // ── Header ──
                ZStack {
                    // 粉色渐变 Hero（与 FishCoinShop Hero 一致）
                    UnevenRoundedRectangle(
                        topLeadingRadius: 24, bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0, topTrailingRadius: 24
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
                                .offset(x: geo.size.width - 30, y: -25)
                            Circle().fill(Color(hex: "00D9FF").opacity(0.12)).frame(width: 60, height: 60)
                                .offset(x: -15, y: geo.size.height - 15)
                        }
                    }

                    HStack(spacing: 14) {
                        // 图标
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 48, height: 48)
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("New Character")
                                .font(AppTheme.fontRowdiesBold(size: 18))
                                .foregroundStyle(.white)
                            Text("Fill in the details below")
                                .font(AppTheme.font(size: 12))
                                .foregroundStyle(.white.opacity(0.85))
                        }

                        Spacer()

                        // 关闭按钮
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
                        topLeadingRadius: 24, bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0, topTrailingRadius: 24
                    )
                    .stroke(Color.black, lineWidth: 3)
                )

                // ── Body ──
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {

                        // 图片选择
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "FF1493"))
                                Text("Character Photo")
                                    .font(AppTheme.fontBold(size: 13))
                                    .foregroundStyle(Color(hex: "B0B0B0"))
                            }

                            if let image = selectedImage {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.black, lineWidth: 2.5)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color(hex: "FF1493"), lineWidth: 1.5)
                                        )

                                    Button(action: { selectedImage = nil }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 26))
                                            .foregroundStyle(Color(hex: "FF1493"))
                                            .shadow(color: .black, radius: 4)
                                    }
                                    .buttonStyle(ClickSoundButtonStyle())
                                    .padding(6)
                                }
                            } else {
                                Button(action: { showImageSourcePicker = true }) {
                                    VStack(spacing: 10) {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: "FF1493").opacity(0.15))
                                                .frame(width: 52, height: 52)
                                            Image(systemName: "plus")
                                                .font(.system(size: 22, weight: .bold))
                                                .foregroundStyle(Color(hex: "FF1493"))
                                        }
                                        Text("Tap to add photo")
                                            .font(AppTheme.font(size: 13))
                                            .foregroundStyle(Color(hex: "606070"))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 110)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color(hex: "0F1419"))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.black, lineWidth: 2)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .strokeBorder(
                                                        Color(hex: "FF1493"),
                                                        style: StrokeStyle(lineWidth: 1, dash: [6, 3])
                                                    )
                                            )
                                    )
                                }
                                .buttonStyle(ClickSoundButtonStyle())
                            }
                        }

                        // 分割线
                        Rectangle()
                            .fill(Color(hex: "FF1493").opacity(0.15))
                            .frame(height: 1)

                        // 名字输入
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "textformat")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "00D9FF"))
                                Text("Name")
                                    .font(AppTheme.fontBold(size: 13))
                                    .foregroundStyle(Color(hex: "B0B0B0"))
                            }

                            TextField("", text: $roleName)
                                .font(AppTheme.font(size: 16))
                                .foregroundStyle(Color.white)
                                .tint(Color(hex: "FF1493"))
                                .placeholder(when: roleName.isEmpty) {
                                    Text("e.g. Luna")
                                        .font(AppTheme.font(size: 16))
                                        .foregroundStyle(Color(hex: "3A3F55"))
                                }
                                .focused($isNameFocused)
                                .padding(.horizontal, 14)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "0F1419"))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.black, lineWidth: 2)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    isNameFocused ? Color(hex: "FF1493") : Color(hex: "FF1493").opacity(0.2),
                                                    lineWidth: isNameFocused ? 1.5 : 1
                                                )
                                        )
                                )
                        }

                        // 分割线
                        Rectangle()
                            .fill(Color(hex: "FF1493").opacity(0.15))
                            .frame(height: 1)

                        // 性别选择
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "FF69B4"))
                                Text("Gender")
                                    .font(AppTheme.fontBold(size: 13))
                                    .foregroundStyle(Color(hex: "B0B0B0"))
                            }

                            HStack(spacing: 10) {
                                ForEach(genders, id: \.self) { gender in
                                    Button(action: { selectedGender = gender }) {
                                        Text(gender)
                                            .font(AppTheme.fontBold(size: 14))
                                            .foregroundStyle(selectedGender == gender ? .white : Color(hex: "606070"))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 42)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(
                                                        selectedGender == gender
                                                        ? LinearGradient(
                                                            colors: [Color(hex: "FF1493"), Color(hex: "FF69B4")],
                                                            startPoint: .leading, endPoint: .trailing
                                                        )
                                                        : LinearGradient(
                                                            colors: [Color(hex: "0F1419"), Color(hex: "0F1419")],
                                                            startPoint: .leading, endPoint: .trailing
                                                        )
                                                    )
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .stroke(Color.black, lineWidth: 2)
                                                    )
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .stroke(
                                                                selectedGender == gender
                                                                    ? Color.clear
                                                                    : Color(hex: "FF1493").opacity(0.2),
                                                                lineWidth: 1
                                                            )
                                                    )
                                            )
                                            .shadow(
                                                color: selectedGender == gender ? Color(hex: "FF1493").opacity(0.4) : .clear,
                                                radius: 8, x: 0, y: 4
                                            )
                                    }
                                    .buttonStyle(ClickSoundButtonStyle())
                                }
                            }
                        }

                        // 保存按钮
                        let canSave = !roleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedImage != nil
                        Button(action: { saveRole() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18, weight: .bold))
                                Text("Save Character")
                                    .font(AppTheme.fontBold(size: 16))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        canSave
                                        ? LinearGradient(
                                            colors: [Color(hex: "FF1493"), Color(hex: "FF69B4")],
                                            startPoint: .leading, endPoint: .trailing
                                        )
                                        : LinearGradient(
                                            colors: [Color(hex: "1A1F2E"), Color(hex: "1A1F2E")],
                                            startPoint: .leading, endPoint: .trailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.black, lineWidth: 2.5)
                                    )
                                    .shadow(
                                        color: canSave ? Color(hex: "FF1493").opacity(0.5) : .clear,
                                        radius: 12, x: 0, y: 6
                                    )
                            )
                        }
                        .buttonStyle(ClickSoundButtonStyle())
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.45)
                    }
                    .padding(20)
                }
                .background(Color(hex: "0A0E1A"))
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0, bottomLeadingRadius: 24,
                        bottomTrailingRadius: 24, topTrailingRadius: 0
                    )
                )
                .overlay(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0, bottomLeadingRadius: 24,
                        bottomTrailingRadius: 24, topTrailingRadius: 0
                    )
                    .stroke(Color.black, lineWidth: 3)
                )
            }
            .frame(maxWidth: 360)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color(hex: "FF1493").opacity(0.3), radius: 40, x: 0, y: 20)
            .onTapGesture { isNameFocused = false }
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $selectedImage, sourceType: .camera)
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
        // 图片来源选择器（暗色底部弹窗）
        .overlay {
            if showImageSourcePicker {
                ZStack(alignment: .bottom) {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture { showImageSourcePicker = false }

                    VStack(spacing: 0) {
                        // 标题
                        VStack(spacing: 6) {
                            Text("📸")
                                .font(.system(size: 32))
                            Text("Add a Photo")
                                .font(AppTheme.fontRowdiesBold(size: 18))
                                .foregroundStyle(Color.white)
                            Text("Choose how to add your character's image")
                                .font(AppTheme.font(size: 12))
                                .foregroundStyle(Color(hex: "B0B0B0"))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 24)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                        Rectangle()
                            .fill(Color(hex: "FF1493").opacity(0.2))
                            .frame(height: 1)

                        // 拍照
                        Button(action: {
                            showImageSourcePicker = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showCamera = true }
                        }) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "FF1493"), Color(hex: "FF69B4")],
                                                startPoint: .topLeading, endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 44, height: 44)
                                        .overlay(Circle().stroke(Color.black, lineWidth: 2))
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Take Photo")
                                        .font(AppTheme.fontBold(size: 16))
                                        .foregroundStyle(Color.white)
                                    Text("Use your camera right now")
                                        .font(AppTheme.font(size: 12))
                                        .foregroundStyle(Color(hex: "B0B0B0"))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color(hex: "FF1493"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(ClickSoundButtonStyle())

                        Rectangle()
                            .fill(Color(hex: "FF1493").opacity(0.2))
                            .frame(height: 1)
                            .padding(.horizontal, 20)

                        // 相册
                        Button(action: {
                            showImageSourcePicker = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showPhotoPicker = true }
                        }) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "00D9FF"), Color(hex: "00D9FF").opacity(0.7)],
                                                startPoint: .topLeading, endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 44, height: 44)
                                        .overlay(Circle().stroke(Color.black, lineWidth: 2))
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Choose from Library")
                                        .font(AppTheme.fontBold(size: 16))
                                        .foregroundStyle(Color.white)
                                    Text("Pick from your photo library")
                                        .font(AppTheme.font(size: 12))
                                        .foregroundStyle(Color(hex: "B0B0B0"))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color(hex: "00D9FF"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(ClickSoundButtonStyle())

                        // 取消
                        Button(action: { showImageSourcePicker = false }) {
                            Text("Cancel")
                                .font(AppTheme.fontBold(size: 15))
                                .foregroundStyle(Color(hex: "606070"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                        }
                        .buttonStyle(ClickSoundButtonStyle())
                        .padding(.top, 4)
                        .padding(.bottom, 8)
                    }
                    .background(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 24, bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0, topTrailingRadius: 24
                        )
                        .fill(Color(hex: "0A0E1A"))
                        .overlay(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 24, bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0, topTrailingRadius: 24
                            )
                            .stroke(Color.black, lineWidth: 3)
                        )
                        .overlay(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 24, bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0, topTrailingRadius: 24
                            )
                            .stroke(Color(hex: "FF1493").opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color(hex: "FF1493").opacity(0.3), radius: 20, x: 0, y: -8)
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .ignoresSafeArea()
                .zIndex(10)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showImageSourcePicker)
            }
        }
    }

    private func saveRole() {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        let trimmedRoleName = roleName.trimmingCharacters(in: .whitespacesAndNewlines)
        let character = Character(
            name: trimmedRoleName,
            imageUrl: UUID().uuidString,
            gender: selectedGender,
            description: "A character with distinctive features"
        )

        CharacterStorage.shared.save(character: character, imageData: imageData)
        AnalyticsManager.track(
            AnalyticsEvent.roleCreationSucceeded,
            properties: [
                "gender": selectedGender,
                "name_length": trimmedRoleName.count,
                "has_photo": true
            ]
        )
        print("[AddRoleView] 已保存角色：\(character.name)，性别：\(selectedGender)")
        onRoleSaved?(character)
        isPresented = false
    }
}

// MARK: - placeholder helper
extension View {
    func placeholder<Content: View>(when shouldShow: Bool, @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: .leading) {
            if shouldShow { placeholder() }
            self
        }
    }
}

// MARK: - 图片选择器
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
    }
}

#Preview {
    AddRoleView(isPresented: .constant(true))
}
 
