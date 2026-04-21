//
//  AI_Comic_MakerApp.swift
//  AI Comic maker
//
//  Created by LazyG on 2026/2/6.
//

import Mixpanel
import SwiftUI

@main
struct AI_Comic_MakerApp: App {
    private static let mixpanelProjectToken = "f5f9649f5134663e8c27ea48efd67a84"

    init() {
        print("[AI_Comic_MakerApp] Mixpanel 初始化开始")
        Mixpanel.initialize(token: Self.mixpanelProjectToken, trackAutomaticEvents: true)
        print("[AI_Comic_MakerApp] Mixpanel 初始化完成")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
