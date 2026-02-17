import Foundation

// 单页绘本数据结构（imagePrompt 用于客户端按页异步生图）
struct StoryPage: Codable, Identifiable {
    var id: UUID
    let text: String
    var imageUrl: String
    /// 生图用的提示词，有则可在翻到该页时再调生图 API
    let imagePrompt: String?
    
    init(id: UUID = UUID(), text: String, imageUrl: String, imagePrompt: String? = nil) {
        self.id = id
        self.text = text
        self.imageUrl = imageUrl
        self.imagePrompt = imagePrompt
    }
    
    enum CodingKeys: String, CodingKey {
        case id, text, imageUrl, imagePrompt
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // 优先使用保存的 id，如果没有则生成新的（兼容旧数据）
        if let savedId = try? c.decode(UUID.self, forKey: .id) {
            id = savedId
        } else {
            id = UUID()
        }
        text = try c.decode(String.self, forKey: .text)
        imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl) ?? ""
        imagePrompt = try c.decodeIfPresent(String.self, forKey: .imagePrompt)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(text, forKey: .text)
        try c.encode(imageUrl, forKey: .imageUrl)
        try c.encodeIfPresent(imagePrompt, forKey: .imagePrompt)
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
