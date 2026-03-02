//
//  StoryLoadingView.swift
//  AI Picture Book
//
//  故事生成Loading界面：显示生成进度
//

import SwiftUI

/// 加载阶段
private enum LoadingPhase {
    case generating   // 正在生成故事
    case preloading   // 正在加载图片和语音
    case ready       // 全部完成，即将跳转
    case failed      // 生成失败，显示重试
}

struct StoryLoadingView: View {
    @Environment(AppState.self) private var appState
    @EnvironmentObject var appOB: AppObservableObject
    @State private var fishCoinManager = FishCoinManager.shared
    @State private var progress: Double = 0.0
    @State private var phase: LoadingPhase = .generating
    @State private var preloadCurrent: Int = 0
    @State private var preloadTotal: Int = 0
    @State private var hasRefunded = false
    @State private var hasConsumedCoins = false
    @State private var rotationAngle: Double = 0
    
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
            
            if phase == .failed {
                // 失败状态：友好提示 + 重试按钮
                VStack(spacing: 24) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(AppTheme.font(size: 56))
                        .foregroundStyle(Color(hex: "FFB84D"))
                    
                    Text("Oops!")
                        .font(AppTheme.fontBold(size: 26))
                        .foregroundStyle(Color(hex: "5D4E37"))
                    
                    Text("Something went wrong.\nPlease try again.")
                        .font(AppTheme.font(size: 16))
                        .foregroundStyle(Color(hex: "8B7355"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            print("[StoryLoadingView] 用户点击 Home")
                            appState.backToHome()
                        }) {
                            Text("Home")
                                .font(AppTheme.fontBold(size: 16))
                                .foregroundStyle(Color(hex: "8B7355"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.white)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color(hex: "D4A574"), lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(ClickSoundButtonStyle())
                        
                        Button(action: {
                            print("[StoryLoadingView] 用户点击重试")
                            
                            // 检查小鱼干余额
                            if !fishCoinManager.canGenerateStory() {
                                print("[StoryLoadingView] 小鱼干不足，无法重试")
                                appState.backToHome()
                                return
                            }
                            
                            // 重试时需要重新扣除小鱼干
                            if !fishCoinManager.consumeForStoryGeneration() {
                                print("[StoryLoadingView] 扣除小鱼干失败")
                                appState.backToHome()
                                return
                            }
                            
                            phase = .generating
                            progress = 0
                            hasRefunded = false
                            hasConsumedCoins = true
                            startStoryGeneration()
                            startLoadingAnimation()
                        }) {
                            Text("Retry")
                                .font(AppTheme.fontBold(size: 16))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "FF9A8B"), Color(hex: "FF6A88")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                                .shadow(color: Color(hex: "FF6A88").opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(ClickSoundButtonStyle())
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                }
                .padding(32)
            } else {
                VStack(spacing: 32) {
                    Spacer()
                    
                    // 蝴蝶动画（添加原地旋转效果）
                    LottieView(
                        animationName: "buttefly-animation_13100012",
                        subdirectory: "lottie",
                        contentMode: .scaleAspectFit
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(rotationAngle))
                    
                    VStack(spacing: 12) {
                        Text(phaseTitle)
                            .font(AppTheme.fontBold(size: 24))
                            .foregroundStyle(Color(hex: "5D4E37"))
                        
                        Text(phaseSubtitle)
                            .font(AppTheme.font(size: 15))
                            .foregroundStyle(Color(hex: "8B7355"))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .frame(width: 300)
                    }
                    
                    // 进度条
                    VStack(spacing: 8) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 999)
                                    .fill(Color(hex: "D4A574").opacity(0.2))
                                
                                RoundedRectangle(cornerRadius: 999)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "FF9A8B"), Color(hex: "FF6A88")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * progress)
                            }
                        }
                        .frame(height: 8)
                        .frame(width: 280)
                        
                        Text("\(Int(progress * 100))%")
                            .font(AppTheme.fontBold(size: 13))
                            .foregroundStyle(Color(hex: "A0826D"))
                    }
                    
                    Spacer()
                }
                .padding(32)
            }
        }
        .onAppear {
            print("[StoryLoadingView] onAppear")
            hasConsumedCoins = true // 标记已经在 ThemeInputModalView 中扣除过
            startStoryGeneration()
            startLoadingAnimation()
        }
    }
    
    private var phaseTitle: String {
        switch phase {
        case .generating:
            return "Creating Magic..."
        case .preloading:
            return "Almost Ready..."
        case .ready:
            return "All Set!"
        case .failed:
            return ""
        }
    }
    
    private var phaseSubtitle: String {
        switch phase {
        case .generating:
            return "Our AI is crafting a personalized story just for you. This may take a moment."
        case .preloading:
            if preloadTotal > 0 {
                return "Loading beautiful illustrations and audio\n(\(preloadCurrent)/\(preloadTotal))"
            }
            return "Preparing your magical adventure"
        case .ready:
            return "Your story is ready to read!"
        case .failed:
            return ""
        }
    }
    
    private func startStoryGeneration() {
        // 获取主题和年龄
        let theme = appState.storyTheme
        guard !theme.isEmpty else {
            print("[StoryLoadingView] 错误：故事主题为空")
            return
        }
        
        // 获取年龄（从OB阶段填写的年龄）
        let age: String
        if let childAge = appState.childAge {
            // 提取年龄数字
            switch childAge {
            case .under3:
                age = "2"
            case .age3_5:
                age = "4"
            case .age6_7:
                age = "6"
            case .age8Plus:
                age = "8"
            }
        } else {
            // 如果没有填写年龄，使用默认值
            age = "4"
            print("[StoryLoadingView] 警告：未找到用户年龄，使用默认值4")
        }
        
        print("[StoryLoadingView] 开始生成故事，主题：\(theme)，年龄：\(age)")
        
        // 调用AI生成功能
        Task {
            await appOB.generateBookPage(theme: theme, age: age)
            
            // 等待生成完成（根据状态判断）
            // 注意：这里我们仍然使用3秒的固定时间，实际应该根据appOB.status来判断
            // 但为了保持UI流畅，我们先保持3秒的loading时间
        }
    }
    
    private func startLoadingAnimation() {
        // 蝴蝶旋转动画（持续旋转）
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        // 进度条动画（模拟进度，从0到70%）
        withAnimation(.easeInOut(duration: 2.5)) {
            progress = 0.7
        }
        
                // 监听生成状态，当成功或失败时跳转
                // 使用定时器检查状态，最多等待120秒（与请求超时时间一致，多页绘本需要更长时间）
                let maxWaitTime: TimeInterval = 120.0
        let checkInterval: TimeInterval = 0.5
        var elapsedTime: TimeInterval = 0
        
        Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { timer in
            elapsedTime += checkInterval
            
            // 更新进度条（模拟）
            if elapsedTime <= 2.5 {
                // 前2.5秒进度到70%
            } else if elapsedTime <= 3.0 {
                // 最后0.5秒进度到100%
                withAnimation(.easeInOut(duration: 0.5)) {
                    progress = 1.0
                }
            }
            
                    // 检查生成状态
                    if appOB.status == .success || appOB.status == .failed {
                        timer.invalidate()
                        print("[StoryLoadingView] 生成完成，状态：\(appOB.status)，绘本页数：\(appOB.pages.count)")
                        
                        if appOB.status == .failed {
                            // 生成失败，退还小鱼干（仅当已扣除时）
                            if !hasRefunded && hasConsumedCoins {
                                fishCoinManager.refundForFailedGeneration()
                                hasRefunded = true
                                print("[StoryLoadingView] 生成失败，已退还小鱼干")
                            }
                            phase = .failed
                            return
                        }
                        
                        guard !appOB.pages.isEmpty else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                appState.finishStoryLoading()
                            }
                            return
                        }
                        
                        // 拿到故事 JSON 后，按照 imagePrompt 调用生图代理接口，等所有图片生成完成后再跳转
                        Task { @MainActor in
                            await generateAllImagesThenNavigate(elapsedSoFar: elapsedTime)
                        }
            } else if elapsedTime >= maxWaitTime {
                // 超时，强制跳转
                timer.invalidate()
                print("[StoryLoadingView] 生成超时，强制跳转")
                appState.finishStoryLoading()
            }
        }
    }
    
    /// 并行生成图片和语音，全部完成后保存故事并跳转
    @MainActor
    private func generateAllImagesThenNavigate(elapsedSoFar: TimeInterval) async {
        let pages = appOB.pages
        
        // 计算需要生成的内容
        var pagesNeedingImage: [(Int, StoryPage, String)] = []
        var pagesNeedingAudio: [(Int, StoryPage)] = []
        
        for (index, page) in pages.enumerated() {
            if let prompt = page.imagePrompt, !prompt.isEmpty, page.imageUrl.isEmpty {
                pagesNeedingImage.append((index, page, prompt))
            }
            if !page.text.isEmpty {
                pagesNeedingAudio.append((index, page))
            }
        }
        
        let imageCount = pagesNeedingImage.count
        let audioCount = pagesNeedingAudio.count
        preloadTotal = imageCount + audioCount
        preloadCurrent = 0
        
        if preloadTotal == 0 {
            print("[StoryLoadingView] 所有页已有图片和语音，直接跳转")
            finishAndNavigate(elapsedSoFar: elapsedSoFar)
            return
        }
        
        phase = .preloading
        progress = 0.7
        let baseProgress = 0.7
        let remainingProgress = 0.3
        
        // 页间间隔（避免服务器压力）
        let pageInterval: TimeInterval = 2.0
        var lastPageTime: Date = .distantPast
        
        // 使用 TaskGroup 并行处理每一页的图片和语音
        await withTaskGroup(of: Void.self) { group in
            // 遍历所有页面索引，确保按顺序处理
            let allPageIndices = Set(pagesNeedingImage.map { $0.0 } + pagesNeedingAudio.map { $0.0 }).sorted()
            
            for pageIndex in allPageIndices {
                // 等待页间间隔
                let elapsed = Date().timeIntervalSince(lastPageTime)
                let delay = max(0, pageInterval - elapsed)
                if delay > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
                lastPageTime = Date()
                
                let page = pages[pageIndex]
                let needsImage = pagesNeedingImage.contains { $0.0 == pageIndex }
                let needsAudio = pagesNeedingAudio.contains { $0.0 == pageIndex }
                
                // 同时发起该页的图片和语音请求
                if needsImage, let (_, _, prompt) = pagesNeedingImage.first(where: { $0.0 == pageIndex }) {
                    group.addTask {
                        print("[StoryLoadingView] 开始生成第 \(pageIndex + 1) 页图片")
                        if let imageUrl = await self.appOB.generateImage(prompt: prompt) {
                            await MainActor.run {
                                self.appOB.updatePageImageUrl(pageId: page.id, imageUrl: imageUrl)
                            }
                            _ = await self.appOB.downloadAndCacheImage(pageId: page.id, imageUrl: imageUrl)
                            await MainActor.run {
                                self.preloadCurrent += 1
                                self.progress = baseProgress + remainingProgress * Double(self.preloadCurrent) / Double(preloadTotal)
                                print("[StoryLoadingView] 第 \(pageIndex + 1) 页图片完成 (\(self.preloadCurrent)/\(preloadTotal))")
                            }
                        } else {
                            print("[StoryLoadingView] ⚠️ 第 \(pageIndex + 1) 页图片失败")
                        }
                    }
                }
                
                if needsAudio {
                    group.addTask {
                        print("[StoryLoadingView] 开始生成第 \(pageIndex + 1) 页语音")
                        if let base64 = await self.appOB.generateAudio(text: page.text) {
                            _ = AudioCache.shared.save(pageId: page.id, base64Data: base64)
                            await MainActor.run {
                                self.preloadCurrent += 1
                                self.progress = baseProgress + remainingProgress * Double(self.preloadCurrent) / Double(preloadTotal)
                                print("[StoryLoadingView] 第 \(pageIndex + 1) 页语音完成 (\(self.preloadCurrent)/\(preloadTotal))")
                            }
                        } else {
                            print("[StoryLoadingView] ⚠️ 第 \(pageIndex + 1) 页语音失败")
                        }
                    }
                }
            }
            
            // 等待所有任务完成
            await group.waitForAll()
        }
        
        phase = .ready
        progress = 1.0
        print("[StoryLoadingView] 所有图片和语音加载完成")
        
        StoryStorage.shared.save(theme: appState.storyTheme, pages: appOB.pages)
        finishAndNavigate(elapsedSoFar: elapsedSoFar)
    }
    
    @MainActor
    private func finishAndNavigate(elapsedSoFar: TimeInterval) {
        let remaining = max(0, 3.0 - elapsedSoFar)
        DispatchQueue.main.asyncAfter(deadline: .now() + remaining) {
            appState.finishStoryLoading()
        }
    }
}

#Preview {
    StoryLoadingView()
        .environment(AppState.shared)
        .environmentObject(AppObservableObject())
}
