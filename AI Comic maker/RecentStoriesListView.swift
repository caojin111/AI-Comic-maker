//
//  RecentStoriesListView.swift
//  AI Comic maker
//
//  所有最近的故事列表
//

import SwiftUI

struct RecentStoriesListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    let stories: [SavedStory]
    
    @State private var isSelectMode = false
    @State private var selectedStoryIds: Set<UUID> = []
    @State private var currentStories: [SavedStory] = []
    
    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                colors: [
                    Color(hex: "FFF8F0"),
                    Color(hex: "FFF0E6"),
                    Color(hex: "FFE8DC")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 自定义顶部栏
                HStack {
                    if isSelectMode {
                        Button(action: {
                            isSelectMode = false
                            selectedStoryIds.removeAll()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(AppTheme.font(size: 16))
                                Text("Cancel")
                                    .font(AppTheme.fontBold(size: 16))
                            }
                            .foregroundStyle(Color(hex: "FF6A88"))
                        }
                        .buttonStyle(ClickSoundButtonStyle())
                    } else {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(AppTheme.font(size: 16))
                                Text("Back")
                                    .font(AppTheme.fontBold(size: 16))
                            }
                            .foregroundStyle(Color(hex: "FF6A88"))
                        }
                        .buttonStyle(ClickSoundButtonStyle())
                    }
                    
                    Spacer()
                    
                    Text("My Stories")
                        .font(AppTheme.fontBold(size: 20))
                        .foregroundStyle(Color(hex: "5D4E37"))
                    
                    Spacer()
                    
                    if !isSelectMode && !currentStories.isEmpty {
                        Button(action: {
                            isSelectMode = true
                        }) {
                            Text("Select")
                                .font(AppTheme.fontBold(size: 16))
                                .foregroundStyle(Color(hex: "FF6A88"))
                        }
                        .buttonStyle(ClickSoundButtonStyle())
                    } else {
                        // 占位保持居中
                        Text("Select")
                            .font(AppTheme.fontBold(size: 16))
                            .foregroundStyle(.clear)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                if currentStories.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed.fill")
                            .font(AppTheme.font(size: 56))
                            .foregroundStyle(Color(hex: "D4A574").opacity(0.5))
                        
                        Text("No Stories Yet")
                            .font(AppTheme.fontBold(size: 20))
                            .foregroundStyle(Color(hex: "8B7355"))
                        
                        Text("Create your first magical story!")
                            .font(AppTheme.font(size: 14))
                            .foregroundStyle(Color(hex: "A0826D"))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(currentStories) { story in
                                StoryRowButton(
                                    story: story,
                                    isSelectMode: isSelectMode,
                                    isSelected: selectedStoryIds.contains(story.id)
                                ) {
                                    if isSelectMode {
                                        // 选择模式：切换选中状态
                                        if selectedStoryIds.contains(story.id) {
                                            selectedStoryIds.remove(story.id)
                                        } else {
                                            selectedStoryIds.insert(story.id)
                                        }
                                    } else {
                                        // 正常模式：打开故事
                                        print("[RecentStoriesListView] 点击故事：\(story.theme)")
                                        dismiss()
                                        appState.viewSavedStory(story)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, isSelectMode ? 100 : 32)
                    }
                    
                    // 批量删除按钮栏
                    if isSelectMode {
                        VStack(spacing: 0) {
                            Divider()
                                .background(Color(hex: "D4A574").opacity(0.3))
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    // 全选/取消全选
                                    if selectedStoryIds.count == currentStories.count {
                                        selectedStoryIds.removeAll()
                                    } else {
                                        selectedStoryIds = Set(currentStories.map { $0.id })
                                    }
                                }) {
                                    Text(selectedStoryIds.count == currentStories.count ? "Deselect All" : "Select All")
                                        .font(AppTheme.fontBold(size: 15))
                                        .foregroundStyle(Color(hex: "FF6A88"))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 48)
                                        .background(
                                            RoundedRectangle(cornerRadius: 24)
                                                .fill(Color.white)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 24)
                                                .stroke(Color(hex: "FF6A88"), lineWidth: 1.5)
                                        )
                                }
                                .buttonStyle(ClickSoundButtonStyle())
                                
                                Button(action: {
                                    deleteSelectedStories()
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "trash.fill")
                                            .font(AppTheme.font(size: 14))
                                        Text("Delete (\(selectedStoryIds.count))")
                                            .font(AppTheme.fontBold(size: 15))
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 24)
                                            .fill(selectedStoryIds.isEmpty ? Color.gray : Color(hex: "FF6A88"))
                                    )
                                    .shadow(color: selectedStoryIds.isEmpty ? .clear : Color(hex: "FF6A88").opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                                .buttonStyle(ClickSoundButtonStyle())
                                .disabled(selectedStoryIds.isEmpty)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color(hex: "FFF8F0").opacity(0.95))
                        }
                    }
                }
            }
        }
        .onAppear {
            if currentStories.isEmpty {
                currentStories = stories
            }
            loadStories()
        }
    }
    
    private func deleteSelectedStories() {
        guard !selectedStoryIds.isEmpty else { return }
        
        let idsToDelete = Array(selectedStoryIds)
        StoryStorage.shared.delete(ids: idsToDelete)
        
        // 更新列表
        currentStories = StoryStorage.shared.loadAll()
        
        // 清空选择并退出选择模式
        selectedStoryIds.removeAll()
        isSelectMode = false
    }
    
    private func loadStories() {
        currentStories = StoryStorage.shared.loadAll()
    }
}

// MARK: - 故事行按钮（首页和更多页共用）

struct StoryRowButton: View {
    let story: SavedStory
    var isSelectMode: Bool = false
    var isSelected: Bool = false
    let action: () -> Void
    
    @State private var hasDragged: Bool = false
    
    var body: some View {
        Button(action: {
            // 只有在没有拖拽的情况下才执行操作
            guard !hasDragged else { return }
            action()
        }) {
            HStack(spacing: 14) {
                // 选择模式：显示复选框
                if isSelectMode {
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color(hex: "FF6A88") : Color.white)
                            .frame(width: 28, height: 28)
                        
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(AppTheme.fontBold(size: 14))
                                .foregroundStyle(.white)
                        } else {
                            Circle()
                                .stroke(Color(hex: "D4A574"), lineWidth: 2)
                                .frame(width: 28, height: 28)
                        }
                    }
                }
                
                // 封面图
                ZStack {
                    if let firstPage = story.pages.first,
                       (firstPage.localImagePath != nil || !firstPage.imageUrl.isEmpty) {
                        ZStack {
                            Color.white.opacity(0.45)
                        CachedAsyncImage(
                            url: URL(string: firstPage.imageUrl),
                            localFilename: firstPage.localImagePath
                        ) { image in
                            image
                                .resizable()
                                    .scaledToFit()
                        } placeholder: {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FFD6A5"), Color(hex: "FDCB6E")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    ProgressView()
                                        .tint(.white)
                                )
                            }
                            .padding(6)
                        }
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white, lineWidth: 2)
                        )
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "A8E6CF"), Color(hex: "81C784")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)
                            .overlay(
                                Image(systemName: "book.fill")
                                    .font(AppTheme.font(size: 28))
                                    .foregroundStyle(.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                }
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                
                // 文字信息
                VStack(alignment: .leading, spacing: 6) {
                    Text(story.theme)
                        .font(AppTheme.fontBold(size: 16))
                        .foregroundStyle(Color(hex: "5D4E37"))
                        .lineLimit(1)
                    
                    Text(story.previewText)
                        .font(AppTheme.font(size: 13))
                        .foregroundStyle(Color(hex: "8B7355"))
                        .lineLimit(2)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(AppTheme.font(size: 10))
                        Text(story.formattedDate)
                            .font(AppTheme.font(size: 11))
                    }
                    .foregroundStyle(Color(hex: "A0826D"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 箭头
                if !isSelectMode {
                    Image(systemName: "chevron.right")
                        .font(AppTheme.font(size: 16))
                        .foregroundStyle(Color(hex: "D4A574"))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color(hex: "D4A574").opacity(0.15), radius: 8, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected && isSelectMode ? Color(hex: "FF6A88") : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(ClickSoundButtonStyle())
        .highPriorityGesture(
            DragGesture(minimumDistance: 10)
                .onChanged { _ in
                    // 检测到拖拽，标记为已拖拽，阻止按钮点击
                    hasDragged = true
                }
                .onEnded { _ in
                    // 延迟重置，确保按钮点击不会触发
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        hasDragged = false
                    }
                }
        )
    }
}
