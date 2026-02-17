//
//  CachedAsyncImage.swift
//  AI Picture Book
//
//  带缓存的图片视图：首次加载后存入本地，再次显示时直接读取
//

import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    
    @State private var loadedImage: UIImage?
    @State private var loadFailed = false
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
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
        .task(id: url?.absoluteString) {
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
