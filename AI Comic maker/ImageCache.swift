//
//  ImageCache.swift
//  AI Comic maker
//
//  图片缓存：内存 + 磁盘，首次加载后复用
//

import SwiftUI
import UIKit

/// 图片缓存服务（内存 + 磁盘）
final class ImageCache {
    static let shared = ImageCache()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let diskCacheDirectory: URL
    
    /// 永久存储目录（Documents/comic_images/），不会被系统清除
    let persistentDirectory: URL

    private init() {
        memoryCache.countLimit = 50
        memoryCache.totalCostLimit = 100 * 1024 * 1024 // 100MB

        let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheDirectory = cachesURL.appendingPathComponent("ImageCache", isDirectory: true)
        try? fileManager.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)

        let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        persistentDirectory = docsURL.appendingPathComponent("comic_images", isDirectory: true)
        try? fileManager.createDirectory(at: persistentDirectory, withIntermediateDirectories: true)
    }
    
    /// 从 URL 加载图片（优先缓存）
    func load(url: URL) async -> UIImage? {
        let key = cacheKey(for: url)
        
        // 1. 内存缓存
        if let cached = memoryCache.object(forKey: key as NSString) {
            print("[ImageCache] 命中内存缓存：\(url.lastPathComponent)")
            return cached
        }
        
        // 2. 磁盘缓存
        let diskPath = diskCacheDirectory.appendingPathComponent(key)
        if fileManager.fileExists(atPath: diskPath.path),
           let data = try? Data(contentsOf: diskPath),
           let image = UIImage(data: data) {
            print("[ImageCache] 命中磁盘缓存：\(url.lastPathComponent)")
            memoryCache.setObject(image, forKey: key as NSString)
            return image
        }
        
        // 3. 网络加载
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { return nil }
            
            // 写入缓存
            memoryCache.setObject(image, forKey: key as NSString)
            try? data.write(to: diskPath)
            print("[ImageCache] 网络加载并已缓存：\(url.lastPathComponent)")
            return image
        } catch {
            print("[ImageCache] 加载失败：\(error.localizedDescription)")
            return nil
        }
    }
    
    /// 预下载图片到本地缓存（用于漫画生成完成后立即缓存所有图片）
    func preloadImages(urls: [URL]) async {
        print("[ImageCache] 开始预下载 \(urls.count) 张图片")
        
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    let key = self.cacheKey(for: url)
                    let diskPath = self.diskCacheDirectory.appendingPathComponent(key)
                    
                    // 如果已经缓存，跳过
                    if self.fileManager.fileExists(atPath: diskPath.path) {
                        print("[ImageCache] 图片已缓存，跳过：\(url.lastPathComponent)")
                        return
                    }
                    
                    // 下载并缓存
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        guard let image = UIImage(data: data) else {
                            print("[ImageCache] 预下载失败（无效图片）：\(url.lastPathComponent)")
                            return
                        }
                        
                        // 写入磁盘和内存缓存
                        try? data.write(to: diskPath)
                        self.memoryCache.setObject(image, forKey: key as NSString)
                        print("[ImageCache] 预下载成功：\(url.lastPathComponent)")
                    } catch {
                        print("[ImageCache] 预下载失败：\(url.lastPathComponent) - \(error.localizedDescription)")
                    }
                }
            }
        }
        
        print("[ImageCache] 预下载完成")
    }
    
    /// 仅读取缓存/本地，不发起网络请求，避免导出快照时只渲染出 loading
    func loadCachedOnly(url: URL) -> UIImage? {
        let key = cacheKey(for: url)

        if let cached = memoryCache.object(forKey: key as NSString) {
            return cached
        }

        let diskPath = diskCacheDirectory.appendingPathComponent(key)
        if fileManager.fileExists(atPath: diskPath.path),
           let data = try? Data(contentsOf: diskPath),
           let image = UIImage(data: data) {
            memoryCache.setObject(image, forKey: key as NSString)
            return image
        }

        return nil
    }

    private func cacheKey(for url: URL) -> String {
        // 用 URL 的 hash 作为文件名，避免特殊字符
        let str = url.absoluteString
        var hash: UInt64 = 5381
        for char in str.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(char)
        }
        return "img_\(hash)"
    }
    
    /// 将图片数据永久保存到 Documents/comic_images/，返回文件名
    /// 用于故事图片持久化，不会被系统清除
    @discardableResult
    func savePersistent(data: Data, filename: String) -> String? {
        let fileURL = persistentDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: fileURL, options: .atomic)
            // 同时写入内存缓存
            if let image = UIImage(data: data) {
                memoryCache.setObject(image, forKey: filename as NSString)
            }
            print("[ImageCache] 已持久化图片：\(filename)")
            return filename
        } catch {
            print("[ImageCache] 持久化保存失败：\(error.localizedDescription)")
            return nil
        }
    }

    /// 从 URL 下载图片并持久化保存，返回文件名
    func downloadAndSavePersistent(url: URL, filename: String) async -> String? {
        // 如果本地已存在，直接返回
        let fileURL = persistentDirectory.appendingPathComponent(filename)
        if fileManager.fileExists(atPath: fileURL.path) {
            print("[ImageCache] 已存在持久化图片，跳过：\(filename)")
            return filename
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return savePersistent(data: data, filename: filename)
        } catch {
            print("[ImageCache] 下载持久化图片失败：\(url.lastPathComponent) - \(error.localizedDescription)")
            return nil
        }
    }

    /// 从持久化目录加载图片（Documents，不会被系统清除）
    func loadPersistent(filename: String) -> UIImage? {
        // 先查内存缓存
        if let cached = memoryCache.object(forKey: filename as NSString) {
            return cached
        }
        let fileURL = persistentDirectory.appendingPathComponent(filename)
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else { return nil }
        memoryCache.setObject(image, forKey: filename as NSString)
        return image
    }

    /// 删除持久化图片
    func deletePersistent(filename: String) {
        let fileURL = persistentDirectory.appendingPathComponent(filename)
        try? fileManager.removeItem(at: fileURL)
        memoryCache.removeObject(forKey: filename as NSString)
        print("[ImageCache] 已删除持久化图片：\(filename)")
    }

    /// 删除指定 URL 的图片缓存（内存和磁盘）
    func delete(url: URL) {
        let key = cacheKey(for: url)
        
        // 删除内存缓存
        memoryCache.removeObject(forKey: key as NSString)
        
        // 删除磁盘缓存
        let diskPath = diskCacheDirectory.appendingPathComponent(key)
        try? fileManager.removeItem(at: diskPath)
        
        print("[ImageCache] 已删除图片缓存：\(url.lastPathComponent)")
    }
}
