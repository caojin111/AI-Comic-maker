import Foundation
import CoreGraphics

// 单页绘本数据结构（imagePrompt 用于客户端按页异步生图）
struct StoryPage: Codable, Identifiable {
    var id: UUID
    let text: String
    var imageUrl: String
    /// 图片在 Documents/comic_images/ 目录的文件名（持久化，优先于远程 URL）
    var localImagePath: String?
    /// 生图用的提示词，有则可在翻到该页时再调生图 API
    let imagePrompt: String?
    /// 该页是否已经在生成记录中重新生成过一次
    var hasRegeneratedImage: Bool
    /// 是否为编辑后保存出的副本；副本允许本地保存，但不允许 regenerate
    var isEditableCopy: Bool

    init(id: UUID = UUID(), text: String, imageUrl: String, localImagePath: String? = nil, imagePrompt: String? = nil, hasRegeneratedImage: Bool = false, isEditableCopy: Bool = false) {
        self.id = id
        self.text = text
        self.imageUrl = imageUrl
        self.localImagePath = localImagePath
        self.imagePrompt = imagePrompt
        self.hasRegeneratedImage = hasRegeneratedImage
        self.isEditableCopy = isEditableCopy
    }

    /// 返回本地持久化图片的 URL（Documents 目录），优先于远程 URL
    var localImageURL: URL? {
        guard let filename = localImagePath, !filename.isEmpty else { return nil }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("comic_images").appendingPathComponent(filename)
    }

    /// 返回最终展示用的图片 URL：本地优先，否则远程
    var displayImageURL: URL? {
        if let local = localImageURL, FileManager.default.fileExists(atPath: local.path) {
            return local
        }
        return URL(string: imageUrl)
    }

    enum CodingKeys: String, CodingKey {
        case id, text, imageUrl, localImagePath, imagePrompt, hasRegeneratedImage, isEditableCopy
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let savedId = try? c.decode(UUID.self, forKey: .id) {
            id = savedId
        } else {
            id = UUID()
        }
        text = try c.decode(String.self, forKey: .text)
        imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl) ?? ""
        localImagePath = try c.decodeIfPresent(String.self, forKey: .localImagePath)
        imagePrompt = try c.decodeIfPresent(String.self, forKey: .imagePrompt)
        hasRegeneratedImage = try c.decodeIfPresent(Bool.self, forKey: .hasRegeneratedImage) ?? false
        isEditableCopy = try c.decodeIfPresent(Bool.self, forKey: .isEditableCopy) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(text, forKey: .text)
        try c.encode(imageUrl, forKey: .imageUrl)
        try c.encodeIfPresent(localImagePath, forKey: .localImagePath)
        try c.encodeIfPresent(imagePrompt, forKey: .imagePrompt)
        try c.encode(hasRegeneratedImage, forKey: .hasRegeneratedImage)
        try c.encode(isEditableCopy, forKey: .isEditableCopy)
    }
}

// 对应云函数返回的 JSON 格式（多页绘本）
struct StoryResponse: Codable {
    let pages: [StoryPage]
}

// 修正后的枚举：使用 case 而不是 let
enum GenerationStatus {
    case idle     // 闲置
    case loading  // 加载中
    case success  // 成功
    case failed   // 失败
}
