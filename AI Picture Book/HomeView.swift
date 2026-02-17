//
//  HomeView.swift
//  AI Picture Book
//
//  首页：点击加号开始后跳转绘本页面
//

import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var showThemeModal = false
    @State private var showAllStories = false
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var recentStories: [SavedStory] = []
    
    private let maxStoriesOnHome = 3
    
    private var displayName: String {
        let name = appState.childName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "My Stories" : name
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar: avatar + name 与设置按钮同一行、同一高度
            HStack(alignment: .center, spacing: 16) {
                Button(action: {
                    print("[HomeView] 点击头像区域")
                    showEditProfile = true
                }) {
                    HStack(spacing: 16) {
                        if let avatar = appState.childAvatar {
                            Image(systemName: avatar.sfSymbolName)
                                .font(.system(size: 40))
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(Color(hex: avatar.color), in: Circle())
                                .shadow(color: AppTheme.shadowColor, radius: 6, x: 0, y: 2)
                        } else {
                            Circle()
                                .fill(AppTheme.secondary.opacity(0.6))
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 26))
                                        .foregroundStyle(AppTheme.textPrimary)
                                )
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(displayName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("Create a new story below")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .frame(height: 80)

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // 开始按钮（加号 CTA）
                Button(action: {
                    print("[HomeView] 点击开始按钮")
                    showThemeModal = true
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "plus")
                            .font(.system(size: 64))
                            .foregroundStyle(.white)
                        Text("Start")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("Create New Story")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 40))
                    .shadow(color: AppTheme.primary.opacity(0.25), radius: 16, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                
                // 最近的故事（首页最多展示 3 个）
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Recent Stories")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        
                        Spacer()
                        
                        if !recentStories.isEmpty {
                            Button(action: {
                                print("[HomeView] 点击更多")
                                showAllStories = true
                            }) {
                                HStack(spacing: 4) {
                                    Text("More")
                                        .font(.system(size: 14, weight: .medium))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundStyle(AppTheme.primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    if recentStories.isEmpty {
                        Text("No stories yet. Tap above to create one")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 24))
                            .shadow(color: AppTheme.shadowColor, radius: 8, x: 0, y: 2)
                    } else {
                        ForEach(Array(recentStories.prefix(maxStoriesOnHome))) { story in
                            StoryRowButton(story: story) {
                                print("[HomeView] 点击最近故事：\(story.theme)")
                                appState.viewSavedStory(story)
                            }
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        }
        .background(AppTheme.bgPrimary)
        .overlay {
            if showSettings {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture { showSettings = false }
                    .overlay {
                        SettingsPopupView(isPresented: $showSettings)
                    }
                    .zIndex(1000)
            }
            if showEditProfile {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture { showEditProfile = false }
                    .overlay {
                        EditProfilePopupView(isPresented: $showEditProfile)
                            .environment(appState)
                    }
                    .zIndex(1000)
            }
        }
        .overlay {
            // 独立的主题输入弹窗（不随抽屉式界面弹出）
            if showThemeModal {
                ThemeInputModalView(isPresented: $showThemeModal)
                    .environment(appState)
                    .zIndex(1000)
            }
        }
        .sheet(isPresented: $showAllStories) {
            RecentStoriesListView(stories: recentStories)
                .environment(appState)
        }
        .onAppear {
            print("[HomeView] onAppear")
            recentStories = StoryStorage.shared.loadAll()
        }
    }
}

#Preview {
    HomeView()
        .environment(AppState.shared)
}
