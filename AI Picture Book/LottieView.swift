//
//  LottieView.swift
//  AI Picture Book
//
//  SwiftUI 包装 Lottie 动画（从 bundle 子目录加载），用于闪屏等
//

import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    let animationName: String
    let subdirectory: String?
    var loopMode: LottieLoopMode = .loop
    var contentMode: UIView.ContentMode = .scaleAspectFit
    /// 播放速度，1.0 为原速，0.5 为一半速度
    var speed: CGFloat = 1.0
    /// 播放一次结束时回调（设置后会用 .playOnce）
    var onComplete: (() -> Void)? = nil

    init(animationName: String, subdirectory: String? = "lottie", loopMode: LottieLoopMode = .loop, contentMode: UIView.ContentMode = .scaleAspectFit, speed: CGFloat = 1.0, onComplete: (() -> Void)? = nil) {
        self.animationName = animationName
        self.subdirectory = subdirectory
        self.loopMode = onComplete != nil ? .playOnce : loopMode
        self.contentMode = contentMode
        self.speed = speed
        self.onComplete = onComplete
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear

        // 多种方式查找 bundle 内动画（兼容不同打包结构）
        let url: URL? = {
            if let sub = subdirectory {
                if let u = Bundle.main.url(forResource: animationName, withExtension: "json", subdirectory: sub) { return u }
                if let p = Bundle.main.path(forResource: animationName, ofType: "json", inDirectory: sub) { return URL(fileURLWithPath: p) }
            }
            if let u = Bundle.main.url(forResource: animationName, withExtension: "json", subdirectory: nil) { return u }
            if let p = Bundle.main.path(forResource: animationName, ofType: "json", inDirectory: nil) { return URL(fileURLWithPath: p) }
            let pathAsName = (subdirectory.map { "\($0)/" } ?? "") + animationName
            if let u = Bundle.main.url(forResource: pathAsName, withExtension: "json", subdirectory: nil) { return u }
            return nil
        }()
        guard let resolvedURL = url else {
            print("[LottieView] 未找到动画：name=\(animationName), subdir=\(subdirectory ?? "nil")。请确认 lottie 文件夹已加入 Target → Build Phases → Copy Bundle Resources")
            return container
        }
        let path = resolvedURL.path
        guard let animation = LottieAnimation.filepath(path) else {
            print("[LottieView] 无法解析动画：\(animationName).json")
            return container
        }
        let animationView = LottieAnimationView(animation: animation)
        animationView.contentMode = contentMode
        animationView.loopMode = loopMode
        animationView.animationSpeed = speed
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(animationView)
        context.coordinator.animationView = animationView

        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: container.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        if let completion = context.coordinator.onComplete {
            animationView.play { _ in
                DispatchQueue.main.async { completion() }
            }
        } else {
            animationView.play()
        }
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onComplete = onComplete
    }

    final class Coordinator {
        var onComplete: (() -> Void)?
        weak var animationView: LottieAnimationView?
        init(onComplete: (() -> Void)?) {
            self.onComplete = onComplete
        }
    }
}
