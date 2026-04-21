//
//  ComicAPIService.swift
//  AI Comic maker
//
//  漫画生成 API 服务层

import Foundation

// MARK: - 枚举定义

/// 漫画格式枚举
enum ComicFormat: String {
    case fourPanel = "4-panel"
    case webtoon
    case manga
    case meme
    case knowledge
    
    /// 显示名称（用于 UI）
    var displayName: String {
        switch self {
        case .fourPanel:
            return "4-Panel"
        case .webtoon:
            return "Webtoon"
        case .manga:
            return "Manga"
        case .meme:
            return "Meme"
        case .knowledge:
            return "Knowledge"
        }
    }
}

/// 漫画风格枚举
enum ComicStyle: String {
    case comic
    case manga
    case chibi
    case retro
    case noir
    case threeD = "3d"
    
    /// 显示名称（用于 UI）
    var displayName: String {
        switch self {
        case .comic:
            return "Comic"
        case .manga:
            return "Manga"
        case .chibi:
            return "Chibi"
        case .retro:
            return "Retro"
        case .noir:
            return "Noir"
        case .threeD:
            return "3D"
        }
    }
}

// MARK: - 请求模型

/// 生成漫画故事的请求体
struct GenerateStoryRequest: Codable {
    let theme: String                    // 用户输入的故事内容/主题
    let style: String?                   // 用户选的画风代码（Knowledge 格式时为 nil，不传）
    let quantity: Int                    // 单张图内的分镜格数（1-6）
    let language: String                 // 对白所用的语言
    let visualAnchor: String?            // 核心：该角色的视觉特征描述（Knowledge 格式时为 nil，不传）
    let characterName: String?           // 用户设定的角色名字（Knowledge 格式时为 nil，不传）
    let variantsCount: Int               // 生成的总页数/候选方案数

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(theme, forKey: .theme)
        try container.encodeIfPresent(style, forKey: .style)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(language, forKey: .language)
        try container.encodeIfPresent(visualAnchor, forKey: .visualAnchor)
        try container.encodeIfPresent(characterName, forKey: .characterName)
        try container.encode(variantsCount, forKey: .variantsCount)
    }

    enum CodingKeys: String, CodingKey {
        case theme, style, quantity, language, visualAnchor, characterName, variantsCount
    }
}

/// 生成漫画图片的请求体（整体生成所有分镜）
struct GenerateImageRequest: Codable {
    let panels: [ComicPanel]             // 所有分镜数据
    let characterImageUrl: String?       // 用户上传的角色照片 URL
    let seed: Int                        // 种子值，确保视觉一致性
    let format: String                   // 漫画排版格式
    let quantity: Int                    // 单张图内的分镜格数
    let variantsCount: Int               // 生成的图片数量（页数）
}

// MARK: - 响应模型

/// 漫画分镜
struct ComicPanel: Codable {
    let panelIndex: Int                  // 分镜索引
    let dialogue: String                 // 对白
    let imagePrompt: String              // 图片生成提示词
}

/// 生成故事的响应体
struct GenerateStoryResponse: Codable {
    let panels: [ComicPanel]?            // 分镜数组（错误时为 nil）
    let masterSeed: Int?                 // 主种子值，用于生图时保证一致性（错误时为 nil）
    let error: String?                   // 错误信息
}

/// 生成图片的响应体（提交任务）
struct GenerateImageResponse: Codable {
    let requestId: String?               // 请求 ID（用于轮询获取结果）
    let error: String?                   // 错误信息
}

/// 轮询图片生成结果的响应体
struct ImageStatusResponse: Codable {
    let imageUrl: String?                // 单个漫画图片 URL（向后兼容）
    let imageUrls: [String]?             // 多张漫画图片 URL 数组
    let status: String?                  // 状态：pending, processing, success, failed
    let error: String?                   // 错误信息
}

// MARK: - API 服务

struct FullComicGenerationResult {
    let imageUrls: [String]
    let panels: [ComicPanel]
}

class ComicAPIService {
    static let shared = ComicAPIService()
    
    // Supabase Edge Functions 基础 URL
    private let baseURL = "https://iajhwrhrjevyzbhoyhze.supabase.co/functions/v1"
    
    // Supabase JWT Token - 从 Info.plist 中读取（不要硬编码）
    private let jwtToken: String
    
    // 请求超时时间（秒）- 增加到 120 秒以支持长时间的 Gemini 生成
    private let requestTimeout: TimeInterval = 120.0
    
    private init() {
        // 从 Info.plist 中读取 JWT Token
        if let token = Bundle.main.infoDictionary?["SUPABASE_JWT_TOKEN"] as? String {
            self.jwtToken = token
        } else {
            // 如果 Info.plist 中没有配置，使用空字符串（会导致 401 错误，提醒开发者配置）
            self.jwtToken = ""
            print("[ComicAPIService] ⚠️ 警告：未在 Info.plist 中配置 SUPABASE_JWT_TOKEN")
        }
    }
    
    // MARK: - 第一步：生成故事脚本
    
    /// 生成漫画故事脚本
    /// - Parameters:
    ///   - request: 生成故事的请求体
    ///   - completion: 完成回调，返回故事响应或错误
    func generateStory(
        request: GenerateStoryRequest,
        completion: @escaping (Result<GenerateStoryResponse, APIError>) -> Void
    ) {
        let endpoint = "\(baseURL)/generate-comic-story"
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var urlRequest = URLRequest(url: url, timeoutInterval: requestTimeout)
        urlRequest.httpMethod = "POST"
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData  // 禁用缓存
        
        // --- Supabase 认证头（仅需两个） ---
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        // -----------------------------------
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            completion(.failure(.encodingError(error)))
            return
        }
        
        print("[ComicAPIService] ========== 生成故事请求 ==========")
        print("[ComicAPIService] URL: \(endpoint)")
        print("[ComicAPIService] Method: POST")
        print("[ComicAPIService] Content-Type: application/json")
        print("[ComicAPIService] Authorization: Bearer \(jwtToken.prefix(30))...")
        print("[ComicAPIService] 主题: \(request.theme)")
        print("[ComicAPIService] 分镜数: \(request.quantity)")
        print("[ComicAPIService] 超时: \(requestTimeout)s")
        print("[ComicAPIService] ================================")
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[ComicAPIService] 网络错误: \(error.localizedDescription)")
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("[ComicAPIService] 无效的响应")
                    completion(.failure(.invalidResponse))
                    return
                }
                
                print("[ComicAPIService] 故事生成响应状态码: \(httpResponse.statusCode)")
                
                guard let data = data else {
                    print("[ComicAPIService] 无响应数据")
                    completion(.failure(.noData))
                    return
                }
                
                // 打印原始 JSON 用于调试
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("[ComicAPIService] 响应 JSON: \(jsonString)")
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .useDefaultKeys
                    
                    let storyResponse = try decoder.decode(GenerateStoryResponse.self, from: data)
                    
                    // 检查是否有错误信息
                    if let error = storyResponse.error {
                        print("[ComicAPIService] 故事生成错误: \(error)")
                        completion(.failure(.apiError(error)))
                        return
                    }
                    
                    // 检查是否有必要的数据
                    guard let panels = storyResponse.panels, let masterSeed = storyResponse.masterSeed else {
                        print("[ComicAPIService] 故事生成响应缺少必要字段: panels=\(storyResponse.panels != nil), masterSeed=\(storyResponse.masterSeed != nil)")
                        completion(.failure(.apiError("Missing panels or masterSeed in response")))
                        return
                    }
                    
                    print("[ComicAPIService] 故事生成成功，分镜数: \(panels.count)，masterSeed: \(masterSeed)")
                        completion(.success(storyResponse))
                } catch {
                    print("[ComicAPIService] 解析故事响应失败: \(error.localizedDescription)")
                    if let decodingError = error as? DecodingError {
                        print("[ComicAPIService] 解析详情: \(String(describing: decodingError))")
                    }
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
    }
    
    // MARK: - 第二步：生成图片
    
    /// 生成漫画图片（提交任务）
    /// - Parameters:
    ///   - request: 生成图片的请求体
    ///   - completion: 完成回调，返回图片 URL 或错误
    func generateImage(
        request: GenerateImageRequest,
        completion: @escaping (Result<String, APIError>) -> Void
    ) {
        let endpoint = "\(baseURL)/comic-image"
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var urlRequest = URLRequest(url: url, timeoutInterval: 30.0) // 提交任务只需 30 秒
        urlRequest.httpMethod = "POST"
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData  // 禁用缓存
        
        // --- Supabase 认证头（仅需两个） ---
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        // -----------------------------------
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            completion(.failure(.encodingError(error)))
            return
        }
        
        print("[ComicAPIService] ========== 提交图片生成任务 ==========")
        print("[ComicAPIService] URL: \(endpoint)")
        print("[ComicAPIService] 种子: \(request.seed)")
        print("[ComicAPIService] 格式: \(request.format)")
        print("[ComicAPIService] 分镜格数: \(request.quantity)")
        print("[ComicAPIService] 分镜数: \(request.panels.count)")
        print("[ComicAPIService] 图片数量: \(request.variantsCount)")
        
        // 打印请求 Body
        if let body = urlRequest.httpBody, let jsonString = String(data: body, encoding: .utf8) {
            print("[ComicAPIService] 请求 Body: \(jsonString)")
        }
        print("[ComicAPIService] ================================")
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[ComicAPIService] 网络错误: \(error.localizedDescription)")
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("[ComicAPIService] 无效的响应")
                    completion(.failure(.invalidResponse))
                    return
                }
                
                print("[ComicAPIService] 提交任务响应状态码: \(httpResponse.statusCode)")
                
                guard let data = data else {
                    print("[ComicAPIService] 无响应数据")
                    completion(.failure(.noData))
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .useDefaultKeys
                    
                    let imageResponse = try decoder.decode(GenerateImageResponse.self, from: data)
                    
                    if let error = imageResponse.error {
                        print("[ComicAPIService] 图片生成错误: \(error)")
                        completion(.failure(.apiError(error)))
                    } else if let requestId = imageResponse.requestId {
                        // 获得 requestId，开始轮询
                        print("[ComicAPIService] 获得 requestId: \(requestId)，开始轮询")
                        self.pollImageResult(requestId: requestId, completion: completion)
                    } else {
                        print("[ComicAPIService] 无 requestId")
                        completion(.failure(.noData))
                    }
                } catch {
                    print("[ComicAPIService] 解析图片响应失败: \(error.localizedDescription)")
                    if let decodingError = error as? DecodingError {
                        print("[ComicAPIService] 解析详情: \(String(describing: decodingError))")
                    }
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
    }
    
    /// 轮询图片生成结果
    /// - Parameters:
    ///   - requestId: 请求 ID
    ///   - completion: 完成回调
    ///   - retryCount: 重试次数（最多 120 次，约 6 分钟）
    private func pollImageResult(
        requestId: String,
        completion: @escaping (Result<String, APIError>) -> Void,
        retryCount: Int = 0
    ) {
        let maxRetries = 120 // 最多轮询 120 次
        let pollInterval: TimeInterval = 3.0 // 每 3 秒轮询一次
        
        if retryCount >= maxRetries {
            print("[ComicAPIService] 轮询超时，requestId: \(requestId)")
            completion(.failure(.apiError("Image generation timeout")))
            return
        }
        
        // 延迟后查询
        DispatchQueue.main.asyncAfter(deadline: .now() + pollInterval) {
            let endpoint = "\(self.baseURL)/comic-image-status/\(requestId)"
            
            guard let url = URL(string: endpoint) else {
                completion(.failure(.invalidURL))
                return
            }
            
            var urlRequest = URLRequest(url: url, timeoutInterval: 10.0)
            urlRequest.httpMethod = "GET"
            urlRequest.cachePolicy = .reloadIgnoringLocalCacheData  // 禁用缓存
            urlRequest.setValue("Bearer \(self.jwtToken)", forHTTPHeaderField: "Authorization")
            
            print("[ComicAPIService] 轮询第 \(retryCount + 1) 次，requestId: \(requestId)")
            
            URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("[ComicAPIService] 轮询网络错误: \(error.localizedDescription)")
                        // 网络错误，继续重试
                        self.pollImageResult(requestId: requestId, completion: completion, retryCount: retryCount + 1)
                        return
                    }
                    
                    guard let data = data else {
                        print("[ComicAPIService] 轮询无响应数据")
                        self.pollImageResult(requestId: requestId, completion: completion, retryCount: retryCount + 1)
                        return
                    }
                    
                    // --- 【关键调试】打印后端返回的原始 JSON ---
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("[DEBUG] 轮询响应原始 JSON: \(jsonString)")
                    }
                    // ----------------------------------------
                    
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .useDefaultKeys
                        
                        let statusResponse = try decoder.decode(ImageStatusResponse.self, from: data)
                        
                        if let status = statusResponse.status {
                            switch status {
                            case "success":
                                // 优先使用 imageUrls 数组，如果没有则降级到单个 imageUrl
                                if let imageUrls = statusResponse.imageUrls, !imageUrls.isEmpty {
                                    print("[ComicAPIService] 图片生成完成，共 \(imageUrls.count) 张图片")
                                    // 返回第一张图片的 URL（后续可以扩展为返回所有 URL）
                                    let imageUrlsJson = imageUrls.joined(separator: ",")
                                    completion(.success(imageUrlsJson))
                                } else if let imageUrl = statusResponse.imageUrl {
                                    print("[ComicAPIService] 图片生成完成: \(imageUrl)")
                                    completion(.success(imageUrl))
                                } else {
                                    print("[ComicAPIService] 状态为 success 但无 imageUrl 或 imageUrls")
                                    completion(.failure(.noData))
                                }
                            case "failed":
                                let errorMsg = statusResponse.error ?? "Unknown error"
                                print("[ComicAPIService] 图片生成失败: \(errorMsg)")
                                completion(.failure(.apiError(errorMsg)))
                            case "pending", "processing":
                                // 继续轮询
                                print("[ComicAPIService] 状态: \(status)，继续轮询")
                                self.pollImageResult(requestId: requestId, completion: completion, retryCount: retryCount + 1)
                            default:
                                print("[ComicAPIService] 未知状态: \(status)")
                                self.pollImageResult(requestId: requestId, completion: completion, retryCount: retryCount + 1)
                            }
                        } else {
                            // 没有状态字段，继续轮询
                            print("[ComicAPIService] 无状态字段，继续轮询")
                            self.pollImageResult(requestId: requestId, completion: completion, retryCount: retryCount + 1)
                        }
                    } catch {
                        print("[ComicAPIService] 解析轮询响应失败: \(error.localizedDescription)")
                        if let decodingError = error as? DecodingError {
                            print("[ComicAPIService] 解析详情: \(String(describing: decodingError))")
                        }
                        self.pollImageResult(requestId: requestId, completion: completion, retryCount: retryCount + 1)
                    }
                }
            }.resume()
        }
    }
    
    /// 单张图片重新生成（提交任务 + 轮询）
    /// - Parameters:
    ///   - prompt: 单张图片提示词
    ///   - completion: 完成回调，返回图片 URL 或错误
    func regenerateImage(
        prompt: String,
        completion: @escaping (Result<String, APIError>) -> Void
    ) {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            completion(.failure(.apiError("Missing image prompt")))
            return
        }
        
        let panel = ComicPanel(
            panelIndex: 0,
            dialogue: "",
            imagePrompt: trimmedPrompt
        )
        let request = GenerateImageRequest(
            panels: [panel],
            characterImageUrl: nil,
            seed: Int.random(in: 1...999_999_999),
            format: ComicFormat.meme.rawValue,
            quantity: 1,
            variantsCount: 1
        )
        
        print("[ComicAPIService] 开始单张重绘，prompt 长度: \(trimmedPrompt.count)")
        generateImage(request: request, completion: completion)
    }
    
    // MARK: - 完整流程：生成故事 + 逐张生成图片
    
    /// 完整的漫画生成流程
    /// - Parameters:
    ///   - storyRequest: 故事生成请求
    ///   - characterImageUrl: 角色照片 URL
    ///   - format: 漫画格式
    ///   - completion: 完成回调，返回生成的漫画图片 URL 或错误
    func generateFullComic(
        storyRequest: GenerateStoryRequest,
        characterImageUrl: String?,
        format: String,
        completion: @escaping (Result<FullComicGenerationResult, APIError>) -> Void
    ) {
        print("[ComicAPIService] 开始完整漫画生成流程")
        
        generateStory(request: storyRequest) { [weak self] result in
            switch result {
            case .success(let storyResponse):
                guard let self else {
                    completion(.failure(.apiError("ComicAPIService released")))
                    return
                }
                guard let panels = storyResponse.panels, let masterSeed = storyResponse.masterSeed else {
                    print("[ComicAPIService] 故事响应缺少必要数据")
                    completion(.failure(.apiError("Missing panels or masterSeed")))
                    return
                }
                
                let targetImageCount = max(storyRequest.variantsCount, 1)
                print("[ComicAPIService] 故事生成完成，masterSeed: \(masterSeed)，分镜数: \(panels.count)，目标张数: \(targetImageCount)")
                
                self.generateImagesSequentially(
                    panels: panels,
                    characterImageUrl: characterImageUrl,
                    format: format,
                    quantity: storyRequest.quantity,
                    masterSeed: masterSeed,
                    targetImageCount: targetImageCount,
                    currentIndex: 0,
                    collectedImageUrls: [],
                    completion: completion
                )
                
            case .failure(let error):
                print("[ComicAPIService] 故事生成失败: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    private func generateImagesSequentially(
        panels: [ComicPanel],
        characterImageUrl: String?,
        format: String,
        quantity: Int,
        masterSeed: Int,
        targetImageCount: Int,
        currentIndex: Int,
        collectedImageUrls: [String],
        completion: @escaping (Result<FullComicGenerationResult, APIError>) -> Void
    ) {
        if currentIndex >= targetImageCount {
            print("[ComicAPIService] 所有单图生成完成，共 \(collectedImageUrls.count) 张")
            completion(.success(FullComicGenerationResult(imageUrls: collectedImageUrls, panels: panels)))
            return
        }
        
        let seed = masterSeed + currentIndex
        let imageRequest = GenerateImageRequest(
            panels: panels,
            characterImageUrl: characterImageUrl,
            seed: seed,
            format: format,
            quantity: quantity,
            variantsCount: 1
        )
        
        print("[ComicAPIService] 开始生成第 \(currentIndex + 1)/\(targetImageCount) 张，seed: \(seed)")
        
        generateImage(request: imageRequest) { [weak self] result in
            switch result {
            case .success(let imageResult):
                let imageUrl = imageResult
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .first(where: { !$0.isEmpty })
                
                guard let imageUrl else {
                    print("[ComicAPIService] 第 \(currentIndex + 1) 张生成成功但没有可用 URL")
                    completion(.failure(.noData))
                    return
                }
                
                var nextCollectedImageUrls = collectedImageUrls
                nextCollectedImageUrls.append(imageUrl)
                
                guard let self else {
                    completion(.failure(.apiError("ComicAPIService released")))
                    return
                }
                
                self.generateImagesSequentially(
                    panels: panels,
                    characterImageUrl: characterImageUrl,
                    format: format,
                    quantity: quantity,
                    masterSeed: masterSeed,
                    targetImageCount: targetImageCount,
                    currentIndex: currentIndex + 1,
                    collectedImageUrls: nextCollectedImageUrls,
                    completion: completion
                )
                
            case .failure(let error):
                print("[ComicAPIService] 第 \(currentIndex + 1) 张生成失败: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}

// MARK: - 错误类型

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case noData
    case decodingError(Error)
    case encodingError(Error)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response"
        case .noData:
            return "No response data"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

// MARK: - 辅助函数

/// 将 quantity 字符串转换为整数
func parseQuantity(_ quantity: String) -> Int {
    if quantity == "Random" {
        return Int.random(in: 1...6)
    }
    return Int(quantity) ?? Int.random(in: 1...6)
}

/// 将 style 字符串转换为 ComicStyle 枚举
func styleToBackendCode(_ style: String) -> String {
    switch style {
    case "Comic":
        return ComicStyle.comic.rawValue
    case "Manga":
        return ComicStyle.manga.rawValue
    case "Chibi":
        return ComicStyle.chibi.rawValue
    case "Retro":
        return ComicStyle.retro.rawValue
    case "Noir":
        return ComicStyle.noir.rawValue
    case "3D":
        return ComicStyle.threeD.rawValue
    default:
        return style.lowercased()
    }
}

/// 将 format 字符串转换为 ComicFormat 枚举
func formatToBackendCode(_ format: String) -> String {
    switch format {
    case "Manga":
        return ComicFormat.manga.rawValue
    case "4-Panel":
        return ComicFormat.fourPanel.rawValue
    case "Meme":
        return ComicFormat.meme.rawValue
    case "Webtoon":
        return ComicFormat.webtoon.rawValue
    case "Knowledge":
        return ComicFormat.knowledge.rawValue
    default:
        return format.lowercased()
    }
}

