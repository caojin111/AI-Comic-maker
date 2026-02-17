//
//  ImageCache.swift
//  AI Picture Book
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
    
    private init() {
        memoryCache.countLimit = 50
        memoryCache.totalCostLimit = 100 * 1024 * 1024 // 100MB
        
        let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheDirectory = cachesURL.appendingPathComponent("ImageCache", isDirectory: true)
        
        try? fileManager.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
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
    
    private func cacheKey(for url: URL) -> String {
        // 用 URL 的 hash 作为文件名，避免特殊字符
        let str = url.absoluteString
        var hash: UInt64 = 5381
        for char in str.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(char)
        }
        return "img_\(hash)"
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
