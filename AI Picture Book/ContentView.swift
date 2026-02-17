//
//  ContentView.swift
//  AI Picture Book
//
//  Created by LazyG on 2026/2/6.
//
//  根路由：启动页 → OB开始 → OB第 1,2,3,4 页 → 首页 → 绘本页面
//

import SwiftUI

struct ContentView: View {
    @StateObject var appOB = AppObservableObject()
    @State private var appState = AppState.shared
    
    var body: some View {
        Group {
            switch appState.currentPage {
            case .splash:
                SplashView()
            case .obStart:
                OBStartView()
            case .obTeamIntro:
                OBTeamIntroPage()
            case .obAge:
                OBAgePage()
            case .obAgeMotivation:
                OBAgeMotivationPage()
            case .obGender:
                OBGenderPage()
            case .obAvatar:
                OBAvatarPage()
            case .obName:
                OBNamePage()
            case .obNameMotivation:
                OBNameMotivationPage()
            case .obRelationship:
                OBRelationshipPage()
            case .obRelationshipMotivation:
                OBRelationshipMotivationPage()
            case .obPersonalizing:
                OBPersonalizingPage()
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
        .environment(appState)
        .environmentObject(appOB)
        .environmentObject(AudioPlayerManager.shared)
        .animation(.easeInOut(duration: 0.3), value: appState.currentPage)
    }
}

#Preview {
    ContentView()
}
