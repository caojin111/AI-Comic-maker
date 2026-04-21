//
//  CachedAsyncImage.swift
//  AI Comic maker
//
//  带缓存的图片视图：优先读取本地持久化文件，其次内存/磁盘缓存，最后网络
//

import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    /// 本地持久化文件名（Documents/comic_images/），若存在则直接加载不走网络
    let localFilename: String?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var loadedImage: UIImage?
    @State private var loadFailed = false

    init(
        url: URL?,
        localFilename: String? = nil,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.localFilename = localFilename
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let uiImage = loadedImage {
                content(Image(uiImage: uiImage))
            } else if loadFailed {
                placeholder()
            } else {
                placeholder()
            }
        }
        .task(id: localFilename ?? url?.absoluteString) {
            // 1. 优先从 Documents 持久化目录加载（无需网络，秒显示）
            if let filename = localFilename, !filename.isEmpty {
                if let img = ImageCache.shared.loadPersistent(filename: filename) {
                    loadedImage = img
                    return
                }
            }
            // 2. 降级：从 URL 加载（内存缓存 → 磁盘缓存 → 网络）
            guard let url = url else {
                loadFailed = true
                return
            }
            loadedImage = await ImageCache.shared.load(url: url)
            if loadedImage == nil {
                loadFailed = true
            }
        }
    }
}
