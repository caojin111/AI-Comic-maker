//
//  RecentStoriesListView.swift
//  AI Picture Book
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
        NavigationStack {
            ZStack {
                AppTheme.bgPrimary
                    .ignoresSafeArea()
                
                if currentStories.isEmpty {
                    VStack(spacing: 16) {
                        Text("📖")
                            .font(AppTheme.font(size: 64))
                        Text("No Stories Yet")
                            .font(AppTheme.font(size: 18))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Go to home to create a new story")
                            .font(AppTheme.font(size: 14))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 0) {
                        ScrollView {
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
                            .padding(20)
                            .padding(.bottom, 32)
                        }
                        
                        // 批量删除按钮栏
                        if isSelectMode {
                            HStack(spacing: 16) {
                                Button(action: {
                                    // 全选/取消全选
                                    if selectedStoryIds.count == currentStories.count {
                                        selectedStoryIds.removeAll()
                                    } else {
                                        selectedStoryIds = Set(currentStories.map { $0.id })
                                    }
                                }) {
                                    Text(selectedStoryIds.count == stories.count ? "Deselect All" : "Select All")
                                        .font(AppTheme.font(size: 16))
                                        .foregroundStyle(AppTheme.primary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(AppTheme.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(ClickSoundButtonStyle())
                                
                                Button(action: {
                                    deleteSelectedStories()
                                }) {
                                    Text("Delete (\(selectedStoryIds.count))")
                                        .font(AppTheme.font(size: 16))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(selectedStoryIds.isEmpty ? Color.gray : Color.red, in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(ClickSoundButtonStyle())
                                .disabled(selectedStoryIds.isEmpty)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(AppTheme.cardBackground)
                            .shadow(color: AppTheme.shadowColor.opacity(0.1), radius: 8, x: 0, y: -2)
                        }
                    }
                }
            }
            .navigationTitle("Recent Stories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isSelectMode {
                        Button(action: {
                            isSelectMode = false
                            selectedStoryIds.removeAll()
                        }) {
                            Text("Cancel")
                                .font(AppTheme.font(size: 16))
                                .foregroundStyle(AppTheme.primary)
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        if !isSelectMode {
                            Button(action: {
                                isSelectMode = true
                            }) {
                                Text("Select")
                                    .font(AppTheme.font(size: 16))
                                    .foregroundStyle(AppTheme.primary)
                            }
                        }
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(AppTheme.font(size: 28))
                                .foregroundStyle(AppTheme.textSecondary)
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
            HStack(spacing: 16) {
                // 选择模式：显示复选框
                if isSelectMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(AppTheme.font(size: 24))
                        .foregroundStyle(isSelected ? AppTheme.primary : Color.gray.opacity(0.5))
                        .frame(width: 28)
                }
                
                // 封面图
                if let firstPage = story.pages.first, !firstPage.imageUrl.isEmpty,
                   let url = URL(string: firstPage.imageUrl) {
                    CachedAsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(AppTheme.secondary)
                            .overlay(ProgressView())
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.secondary.opacity(0.5))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "book.fill")
                                .font(AppTheme.font(size: 24))
                                .foregroundStyle(AppTheme.textSecondary)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(story.theme)
                        .font(AppTheme.font(size: 16))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                    Text(story.previewText)
                        .font(AppTheme.font(size: 13))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                    Text(story.formattedDate)
                        .font(AppTheme.font(size: 11))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if !isSelectMode {
                    Image(systemName: "chevron.right")
                        .font(AppTheme.font(size: 14))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .padding(16)
            .background(isSelected && isSelectMode ? AppTheme.primary.opacity(0.1) : AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(isSelected && isSelectMode ? AppTheme.primary : Color.clear, lineWidth: 2)
            )
            .shadow(color: AppTheme.shadowColor, radius: 8, x: 0, y: 2)
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
