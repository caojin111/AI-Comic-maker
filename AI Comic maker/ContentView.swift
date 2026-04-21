//
//  ContentView.swift
//  AI Comic maker
//

import SwiftUI

struct ContentView: View {
    @StateObject var appOB = AppObservableObject()
    @State private var appState = AppState.shared

    var body: some View {
        ContentRootView()
            .environment(appState)
            .environmentObject(appOB)
            .environmentObject(AudioPlayerManager.shared)
    }
}

private struct ContentRootView: View {
    @Environment(AppState.self) private var appState

    private static func rootViewId(for page: AppPage) -> String {
        switch page {
        case .obGetStarted, .obPage2, .obPage3, .obPage4, .obPage5, .obPage6:
            return "obFlow"
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
            case .obGetStarted, .obPage2, .obPage3, .obPage4, .obPage5, .obPage6:
                OBFlowContainerView()
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
