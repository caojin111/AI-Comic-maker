//
//  StoryStorage.swift
//  AI Comic maker
//
//  本地存储最近生成的故事
//

import Foundation

/// 已保存的故事（用于最近的故事列表）
struct SavedStory: Identifiable, Codable {
    let id: UUID
    let theme: String
    var pages: [StoryPage]
    let createdAt: Date
    
    init(id: UUID = UUID(), theme: String, pages: [StoryPage], createdAt: Date = Date()) {
        self.id = id
        self.theme = theme
        self.pages = pages
        self.createdAt = createdAt
    }
    
    /// 第一页预览文本
    var previewText: String {
        pages.first?.text.prefix(50).description ?? "No content"
    }
    
    /// 格式化日期
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: createdAt)
    }
}

/// 故事本地存储服务
final class StoryStorage {
    static let shared = StoryStorage()
    
    private let userDefaults = UserDefaults.standard
    private let key = "recentStories"
    private let maxStories = 50
    
    private init() {}
    
    /// 保存新故事
    @discardableResult
    func save(theme: String, pages: [StoryPage]) -> SavedStory {
        let story = SavedStory(theme: theme, pages: pages)
        var list = loadAll()
        list.insert(story, at: 0)
        
        // 如果超过上限，删除最旧的故事并清理其缓存
        if list.count > maxStories {
            let storiesToRemove = Array(list.suffix(list.count - maxStories))
            list = Array(list.prefix(maxStories))
            
            // 清理被删除故事的缓存
            for removedStory in storiesToRemove {
                cleanupCache(for: removedStory)
            }
        }
        
        saveAll(list)
        print("[StoryStorage] 已保存故事，主题：\(theme)，共\(pages.count)页")
        return story
    }
    
    /// 加载所有最近的故事
    func loadAll() -> [SavedStory] {
        guard let data = userDefaults.data(forKey: key) else { return [] }
        do {
            let list = try JSONDecoder().decode([SavedStory].self, from: data)
            return list
        } catch {
            print("[StoryStorage] 加载失败：\(error)")
            return []
        }
    }
    
    /// 根据ID获取故事
    func load(id: UUID) -> SavedStory? {
        loadAll().first { $0.id == id }
    }
    
    /// 删除故事
    func delete(id: UUID) {
        var list = loadAll()
        if let storyToDelete = list.first(where: { $0.id == id }) {
            list.removeAll { $0.id == id }
            saveAll(list)
            // 清理被删除故事的缓存
            cleanupCache(for: storyToDelete)
            print("[StoryStorage] 已删除故事：\(id)")
        }
    }
    
    /// 批量删除故事
    func delete(ids: [UUID]) {
        var list = loadAll()
        let storiesToDelete = list.filter { ids.contains($0.id) }
        list.removeAll { ids.contains($0.id) }
        saveAll(list)
        // 清理被删除故事的缓存
        for story in storiesToDelete {
            cleanupCache(for: story)
        }
        print("[StoryStorage] 已批量删除 \(storiesToDelete.count) 个故事")
    }
    
    /// 清理故事的图片和音频缓存
    private func cleanupCache(for story: SavedStory) {
        print("[StoryStorage] 开始清理故事缓存：\(story.id)")
        for page in story.pages {
            // 清理音频缓存
            AudioCache.shared.delete(pageId: page.id)

            // 清理持久化图片（Documents/comic_images/）
            if let filename = page.localImagePath {
                ImageCache.shared.deletePersistent(filename: filename)
            }

            // 清理磁盘图片缓存（Caches 目录）
            if let imageUrl = URL(string: page.imageUrl) {
                ImageCache.shared.delete(url: imageUrl)
            }
        }
        print("[StoryStorage] 已清理故事缓存：\(story.id)")
    }
    
    private func saveAll(_ list: [SavedStory]) {
        do {
            let data = try JSONEncoder().encode(list)
            userDefaults.set(data, forKey: key)
        } catch {
            print("[StoryStorage] 保存失败：\(error)")
        }
    }
    
    /// 用新列表整体替换当前故事存储
    func replaceAll(with stories: [SavedStory]) {
        saveAll(stories)
    }
}
