//
//  StoryBookView.swift
//  AI Picture Book
//
//  绘本页面：从首页点击加号开始后跳转，强制横屏
//

import SwiftUI
import UIKit

struct StoryBookView: View {
    @Environment(AppState.self) private var appState
    @EnvironmentObject var appOB: AppObservableObject
    @State private var currentPageIndex: Int = 0
    @State private var showSettings = false
    @AppStorage("storyTextSize") private var textSize: Double = 0.0 // 0.0 = 最小，1.0 = 最大
    
    // 用于传递给 PageViewController 的环境对象
    private var appOBForPages: AppObservableObject {
        appOB
    }
    
    // 根据滑动条值计算字体大小（14-28）
    private var fontSize: CGFloat {
        let minSize: CGFloat = 14
        let maxSize: CGFloat = 28
        return minSize + (maxSize - minSize) * CGFloat(textSize)
    }
    
    /// 要显示的页面：优先使用已保存的故事，否则使用 appOB.pages
    private var displayPages: [StoryPage] {
        if let saved = appState.viewingSavedStory {
            return saved.pages
        }
        return appOB.pages
    }
    
    var body: some View {
        ZStack {
            AppTheme.bgPrimary
                .ignoresSafeArea()
            
            // 1. 内容层：全屏铺满（绘本或加载状态）
            if appState.viewingSavedStory == nil && (appOB.status == .loading || appOB.pages.isEmpty) {
                // 加载中或等待状态
                VStack(spacing: 24) {
                    Spacer()
                    if appOB.status == .loading {
                        VStack(spacing: 16) {
                            ProgressView().scaleEffect(1.5)
                            Text("Creating your story book...").font(AppTheme.font(size: 20)).foregroundStyle(AppTheme.textPrimary)
                            Text("AI is creating a multi-page story for you. Please wait...").font(AppTheme.font(size: 14)).foregroundStyle(AppTheme.textSecondary)
                        }
                    } else if appOB.status == .failed {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill").font(AppTheme.font(size: 64)).foregroundStyle(Color.orange)
                            Text("Generation Failed").font(AppTheme.font(size: 20)).foregroundStyle(AppTheme.textPrimary)
                            Text("Please check your network connection or API configuration").font(AppTheme.font(size: 14)).foregroundStyle(AppTheme.textSecondary)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Text("📖").font(AppTheme.font(size: 64))
                            Text("Waiting for story").font(AppTheme.font(size: 20)).foregroundStyle(AppTheme.textPrimary)
                        }
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            } else {
                // 显示多页绘本：TabView 占满全屏，底层用黑色避免底部白边
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                    PageViewController(
                        pages: displayPages,
                        currentPageIndex: $currentPageIndex,
                        shouldRequestImageGeneration: appState.viewingSavedStory == nil,
                        appOB: appOBForPages,
                        audioPlayer: AudioPlayerManager.shared,
                        fontSize: fontSize
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(edges: .all)
                }
            }
            
            // 2. Header 浮层：压在内容之上，不占用内容区域
            VStack {
                HStack {
                    Button(action: { appState.backToHome() }) {
                        Image(systemName: "house.fill")
                            .font(AppTheme.font(size: 24))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(Color.white, in: Circle())
                            .shadow(color: AppTheme.shadowColor, radius: 8, x: 0, y: 2)
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                    Spacer()
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(AppTheme.font(size: 24))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(Color.white, in: Circle())
                            .shadow(color: AppTheme.shadowColor, radius: 8, x: 0, y: 2)
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 8)
                Spacer()
            }
        }
        .overlay {
            // 文本大小设置弹窗
            if showSettings {
                TextSizeSettingsView(
                    textSize: $textSize,
                    isPresented: $showSettings
                )
                .zIndex(1000)
            }
        }
        .onAppear {
            print("[StoryBookView] onAppear, force landscape")
            BackgroundMusicManager.shared.playRandomTrack()
            print("[StoryBookView] 绘本页数：\(displayPages.count)，来源：\(appState.viewingSavedStory != nil ? "已保存" : "新生成")")
            for (index, page) in displayPages.enumerated() {
                let imageUrlStatus = page.imageUrl.isEmpty ? "❌ 为空" : "✅ 有值"
                print("[StoryBookView] 第\(index + 1)页 - 文本：\"\(page.text.prefix(30))...\"，图片URL：\(imageUrlStatus)")
            }
            setOrientation(.landscape)
        }
        .onDisappear {
            print("[StoryBookView] onDisappear, restore portrait")
            setOrientation(.portrait)
            BackgroundMusicManager.shared.stop()
            AudioPlayerManager.shared.stop()
            // 移除重复保存：已在 StoryLoadingView 中保存，此处不再保存
        }
    }
}

// MARK: - 单页绘本视图（16:9 全屏适配，自适应占满屏幕）

struct StoryPageView: View {
    let page: StoryPage
    /// 是否在「新生成故事」模式：翻到该页时触发生图（仅当前会话，非从最近的故事打开）
    var shouldRequestImageGeneration: Bool = false
    /// 当前页索引（从0开始）
    var currentIndex: Int = 0
    /// 总页数
    var totalPages: Int = 1
    /// 翻页回调
    var onPageChange: ((Int) -> Void)? = nil
    /// 字体大小
    var fontSize: CGFloat = 20
    @EnvironmentObject private var appOB: AppObservableObject
    @EnvironmentObject private var audioPlayer: AudioPlayerManager
    
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                // 0. 底层黑色：任何缝隙都显示黑色而非白边
                Color.black
                    .frame(width: size.width, height: size.height)
                
                // 1. 背景层：优先使用内存缓存的 UIImage（仅当前会话新生成的故事），否则使用 CachedAsyncImage（利用系统缓存）
                if shouldRequestImageGeneration, let cachedImage = appOB.preloadedImages[page.id] {
                    // 当前会话新生成的故事：使用预加载的 UIImage，实现 0 毫秒延迟显示
                    Image(uiImage: cachedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.width, height: size.height)
                        .clipped()
                } else if !page.imageUrl.isEmpty, let imageUrl = URL(string: page.imageUrl) {
                    // 从保存的故事打开：使用 CachedAsyncImage，它会利用系统缓存和 ImageCache
                    CachedAsyncImage(url: imageUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipped()
                    } placeholder: {
                        ZStack {
                            Color.black.opacity(0.3)
                            ProgressView().scaleEffect(1.5).tint(.white)
                        }
                        .frame(width: size.width, height: size.height)
                    }
                    .frame(width: size.width, height: size.height)
                } else {
                    Color.black.opacity(0.5)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "photo").font(AppTheme.font(size: 64)).foregroundStyle(.white.opacity(0.7))
                                Text("Generating image...").font(AppTheme.font(size: 14)).foregroundStyle(.white.opacity(0.7))
                            }
                        )
                        .frame(width: size.width, height: size.height)
                }
                
                // 2. 遮罩层
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.6)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: size.width, height: size.height)
                
                // 3. 文本层：置于底部，带左右箭头
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        // 左箭头（第一页不显示）
                        if currentIndex > 0 {
                            Button(action: {
                                onPageChange?(currentIndex - 1)
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(AppTheme.font(size: 24))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white.opacity(0.2), in: Circle())
                            }
                            .buttonStyle(ClickSoundButtonStyle())
                        } else {
                            // 占位，保持布局
                            Spacer()
                                .frame(width: 44, height: 44)
                        }
                        
                        // 文本内容 + 喇叭按钮
                        HStack(alignment: .bottom, spacing: 8) {
                            Text(page.text)
                                .font(AppTheme.font(size: fontSize))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineSpacing(8)
                                .padding(30)
                                .frame(maxWidth: .infinity)
                            // 喇叭按钮：点击播放语音
                            if AudioCache.shared.hasCache(for: page.id) {
                                Button(action: {
                                    if audioPlayer.currentPageId == page.id && audioPlayer.isPlaying {
                                        audioPlayer.stop()
                                    } else {
                                        audioPlayer.play(pageId: page.id)
                                    }
                                }) {
                                    Image(systemName: audioPlayer.currentPageId == page.id && audioPlayer.isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                                        .font(AppTheme.font(size: 22))
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Color.white.opacity(0.2), in: Circle())
                                }
                                .buttonStyle(ClickSoundButtonStyle())
                            }
                        }
                        .background(
                            BlurView(style: .systemThinMaterialDark)
                                .cornerRadius(15)
                        )
                        .frame(maxWidth: .infinity)
                        
                        // 右箭头（最后一页不显示）
                        if currentIndex < totalPages - 1 {
                            Button(action: {
                                onPageChange?(currentIndex + 1)
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(AppTheme.font(size: 24))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white.opacity(0.2), in: Circle())
                            }
                            .buttonStyle(ClickSoundButtonStyle())
                        } else {
                            // 占位，保持布局
                            Spacer()
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .frame(width: size.width, height: size.height)
            }
            .frame(width: size.width, height: size.height)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .ignoresSafeArea(edges: .all)
        .onAppear {
            if shouldRequestImageGeneration {
                Task { await appOB.requestImageGenerationIfNeeded(for: page) }
            }
        }
    }
}

// MARK: - 模糊背景视图

struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let effect = UIBlurEffect(style: style)
        let view = UIVisualEffectView(effect: effect)
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// MARK: - 自定义 PageViewController（修复最后一页继续滑动问题）

struct PageViewController: UIViewControllerRepresentable {
    let pages: [StoryPage]
    @Binding var currentPageIndex: Int
    let shouldRequestImageGeneration: Bool
    let appOB: AppObservableObject
    let audioPlayer: AudioPlayerManager
    let fontSize: CGFloat
    
    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pageVC.dataSource = context.coordinator
        pageVC.delegate = context.coordinator
        
        if let firstVC = context.coordinator.viewController(for: 0) {
            pageVC.setViewControllers([firstVC], direction: .forward, animated: false)
        }
        
        return pageVC
    }
    
    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        if let currentVC = pageViewController.viewControllers?.first as? PageHostingController,
           let currentIndex = pages.firstIndex(where: { $0.id == currentVC.page.id }) {
            // 检查是否需要更新字体大小
            if currentVC.fontSize != fontSize {
                currentVC.updateFontSize(fontSize)
            }
            // 检查是否需要切换页面
            if currentIndex != currentPageIndex {
                if let targetVC = context.coordinator.viewController(for: currentPageIndex) {
                    pageViewController.setViewControllers([targetVC], direction: currentPageIndex > currentIndex ? .forward : .reverse, animated: true)
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        let parent: PageViewController
        
        init(_ parent: PageViewController) {
            self.parent = parent
        }
        
        func viewController(for index: Int) -> PageHostingController? {
            guard index >= 0 && index < parent.pages.count else { return nil }
            let page = parent.pages[index]
            let hostingVC = PageHostingController(
                page: page,
                currentIndex: index,
                totalPages: parent.pages.count,
                shouldRequestImageGeneration: parent.shouldRequestImageGeneration,
                appOB: parent.appOB,
                audioPlayer: parent.audioPlayer,
                fontSize: parent.fontSize,
                onPageChange: { [weak self] newIndex in
                    self?.parent.currentPageIndex = newIndex
                }
            )
            return hostingVC
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let hostingVC = viewController as? PageHostingController,
                  let index = parent.pages.firstIndex(where: { $0.id == hostingVC.page.id }),
                  index > 0 else { return nil }
            return self.viewController(for: index - 1)
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let hostingVC = viewController as? PageHostingController,
                  let index = parent.pages.firstIndex(where: { $0.id == hostingVC.page.id }),
                  index < parent.pages.count - 1 else { return nil }
            return self.viewController(for: index + 1)
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            if completed,
               let currentVC = pageViewController.viewControllers?.first as? PageHostingController,
               let index = parent.pages.firstIndex(where: { $0.id == currentVC.page.id }) {
                parent.currentPageIndex = index
            }
        }
    }
}

class PageHostingController: UIHostingController<AnyView> {
    let page: StoryPage
    var fontSize: CGFloat
    let currentIndex: Int
    let totalPages: Int
    let shouldRequestImageGeneration: Bool
    let appOB: AppObservableObject
    let audioPlayer: AudioPlayerManager
    let onPageChange: (Int) -> Void
    
    init(page: StoryPage, currentIndex: Int, totalPages: Int, shouldRequestImageGeneration: Bool, appOB: AppObservableObject, audioPlayer: AudioPlayerManager, fontSize: CGFloat, onPageChange: @escaping (Int) -> Void) {
        self.page = page
        self.fontSize = fontSize
        self.currentIndex = currentIndex
        self.totalPages = totalPages
        self.shouldRequestImageGeneration = shouldRequestImageGeneration
        self.appOB = appOB
        self.audioPlayer = audioPlayer
        self.onPageChange = onPageChange
        let pageView = StoryPageView(
            page: page,
            shouldRequestImageGeneration: shouldRequestImageGeneration,
            currentIndex: currentIndex,
            totalPages: totalPages,
            onPageChange: onPageChange,
            fontSize: fontSize
        )
        .environmentObject(appOB)
        .environmentObject(audioPlayer)
        super.init(rootView: AnyView(pageView))
    }
    
    func updateFontSize(_ newFontSize: CGFloat) {
        fontSize = newFontSize
        let pageView = StoryPageView(
            page: page,
            shouldRequestImageGeneration: shouldRequestImageGeneration,
            currentIndex: currentIndex,
            totalPages: totalPages,
            onPageChange: onPageChange,
            fontSize: fontSize
        )
        .environmentObject(appOB)
        .environmentObject(audioPlayer)
        rootView = AnyView(pageView)
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - 横屏控制

private func setOrientation(_ orientation: UIInterfaceOrientationMask) {
    guard let windowScene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first
    else { return }
    
    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
}

#Preview {
    StoryBookView()
        .environment(AppState.shared)
        .environmentObject(AppObservableObject())
}
