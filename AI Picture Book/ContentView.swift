//
//  ContentView.swift
//  AI Picture Book
//
//  Created by LazyG on 2026/2/6.
//
//  根路由：启动页 → OB开始 → OB第 1,2,3,4 页 → 首页 → 绘本页面
//

import SwiftUI

// MARK: - OB 翻页动画容器（用 offset 做滑入，保证可见）

private struct OBPageSlideContainer<Content: View>: View {
    let screenWidth: CGFloat
    let forward: Bool
    @ViewBuilder let content: () -> Content
    @State private var offset: CGFloat?

    var body: some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .offset(x: offset ?? (forward ? screenWidth : -screenWidth))
            .onAppear {
                guard offset == nil else { return }
                withAnimation(.easeInOut(duration: 0.35)) {
                    offset = 0
                }
            }
    }
}

struct ContentView: View {
    @StateObject var appOB = AppObservableObject()
    @State private var appState = AppState.shared

    /// 滑入动画用宽度（不依赖 GeometryReader，避免根视图尺寸被压缩）
    private static var slideWidth: CGFloat { UIScreen.main.bounds.width }

    /// OB 流程内用稳定 id，避免整容器被替换导致背景/顶栏重置
    private static func rootViewId(for page: AppPage) -> String {
        switch page {
        case .obGetStarted, .obTeamIntro, .obAge, .obAgeMotivation, .obGender, .obAvatar, .obName, .obNameMotivation, .obRelationship, .obRelationshipMotivation:
            return "obFlow"
        case .obPersonalizing:
            return "obPersonalizing"
        case .obAllSetUp:
            return "obAllSetUp"
        case .obChartMotivation:
            return "obChartMotivation"
        default:
            return "\(page)"
        }
    }

    var body: some View {
        ContentRootView()
            .environment(appState)
            .environmentObject(appOB)
            .environmentObject(AudioPlayerManager.shared)
    }
}

/// 根据 currentPage 选中的根视图（用 @Environment(AppState.self) 确保随 currentPage 更新）
private struct ContentRootView: View {
    @Environment(AppState.self) private var appState

    private static var slideWidth: CGFloat { UIScreen.main.bounds.width }
    private static func rootViewId(for page: AppPage) -> String {
        switch page {
        case .obGetStarted, .obTeamIntro, .obAge, .obAgeMotivation, .obGender, .obAvatar, .obName, .obNameMotivation, .obRelationship, .obRelationshipMotivation:
            return "obFlow"
        case .obPersonalizing:
            return "obPersonalizing"
        case .obAllSetUp:
            return "obAllSetUp"
        case .obChartMotivation:
            return "obChartMotivation"
        default:
            return "\(page)"
        }
    }

    var body: some View {
        Group {
            switch appState.currentPage {
            case .splash:
                SplashView()
            case .obStart:
                OBStartView()
            case .obGetStarted, .obTeamIntro, .obAge, .obAgeMotivation, .obGender, .obAvatar, .obName, .obNameMotivation, .obRelationship, .obRelationshipMotivation:
                OBFlowContainerView()
            case .obPersonalizing:
                OBPageSlideContainer(screenWidth: Self.slideWidth, forward: appState.obNavigationForward) { OBPersonalizingPage() }
            case .obAllSetUp:
                OBPageSlideContainer(screenWidth: Self.slideWidth, forward: appState.obNavigationForward) { OBAllSetUpPage() }
            case .obChartMotivation:
                OBPageSlideContainer(screenWidth: Self.slideWidth, forward: appState.obNavigationForward) { OBChartMotivationPage() }
            case .paywall:
                PaywallView()
            case .home:
                HomeView()
            case .storyLoading:
                StoryLoadingView()
            case .storyBook:
                StoryBookView()
            }
        }
        .background(Color(hex: "FFFFFF"))
        .id(Self.rootViewId(for: appState.currentPage))
        .animation(.easeInOut(duration: 0.35), value: appState.currentPage)
    }
}

#Preview {
    ContentView()
}
