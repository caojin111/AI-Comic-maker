import SwiftUI
internal import Combine

// 这个类负责处理所有跟 AI 相关的动作
class AppObservableObject: ObservableObject {
    // @Published 意味着当这些变量变化时，界面会自动刷新
    @Published var pages: [StoryPage] = []
    @Published var status: GenerationStatus = .idle
    
    // 兼容旧代码的辅助属性（用于显示第一页的内容）
    var storyText: String {
        pages.first?.text ?? "Waiting for your theme..."
    }
    
    var imageUrl: URL? {
        if let firstPage = pages.first {
            return URL(string: firstPage.imageUrl)
        }
        return nil
    }
    
    // 任务 A：生成故事（仅文案 + imagePrompt），入参 theme，回参 pages[]，拿到即跳转 UI
    // 安全：不涉及 Key，仅 Supabase Anon 鉴权
    private let generateStoryURL = URL(string: "https://iajhwrhrjevyzbhoyhze.supabase.co/functions/v1/generate-story")!
    
    // 任务 B：生图代理。iOS 只传 imagePrompt，由 Supabase 在后端挂载 Key 转发，客户端不持有 REPLICATE_API_KEY
    private let generateImageProxyURL = URL(string: "https://iajhwrhrjevyzbhoyhze.supabase.co/functions/v1/generate-image-proxy")!
    
    // 任务 C：语音生成。传入 text，返回 Base64 音频
    private let generateAudioURL = URL(string: "https://iajhwrhrjevyzbhoyhze.supabase.co/functions/v1/generate-audio")!
    
    // 这是你的安全门票 (请去 Supabase Settings -> API 复制 Anon Key)
    private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlhamh3cmhyamV2eXpiaG95aHplIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAzODE5MTIsImV4cCI6MjA4NTk1NzkxMn0.mb335WseDloKGnqR02aUetm_Ne37uh1LB5sDQroTW7o"
    
    /// 上次开始生图的时间，用于间隔 2 秒再发下一张，避免 429
    private var lastImageGenerationStartTime: Date = .distantPast
    /// 已发起过生图请求的 page id，避免重复请求
    private var pageIdsGenerationStarted: Set<UUID> = []
    /// 预加载的图片对象缓存：pageId -> UIImage，实现 0 毫秒延迟显示
    @Published var preloadedImages: [UUID: UIImage] = [:]

    // 任务 A：调用 generate-story，入参仅 theme，回参 pages（text + imagePrompt），拿到后立即跳转
    func generateBookPage(theme: String, age: String) async {
        print("[AppObservableObject] 任务 A：调用 generate-story，主题：\(theme)")
        
        if supabaseAnonKey == "YOUR_SUPABASE_ANON_KEY" {
            print("[AppObservableObject] ⚠️ 错误：Supabase Anon Key 未配置！")
            await MainActor.run {
                self.status = .failed
                self.pages = []
            }
            return
        }
        
        await MainActor.run {
            self.status = .loading
            self.pages = []
            self.pageIdsGenerationStarted = []
            self.preloadedImages = [:] // 清空图片缓存，避免旧数据干扰
        }
        
        var request = URLRequest(url: generateStoryURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 120.0
        
        let body: [String: String] = ["theme": theme]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            print("[AppObservableObject] generate-story 请求参数：\(body)")
            
            // 发起真正的网络请求
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("[AppObservableObject] HTTP状态码：\(httpResponse.statusCode)")
                
                // 打印响应头（用于调试）
                if let headers = httpResponse.allHeaderFields as? [String: Any] {
                    print("[AppObservableObject] 响应头：\(headers)")
                }
                
                if httpResponse.statusCode == 200 {
                    // 打印响应数据（用于调试）
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("[AppObservableObject] 响应数据：\(responseString)")
                    }
                    
                    // 解析云端传回的 JSON
                    do {
                        let decoded = try JSONDecoder().decode(StoryResponse.self, from: data)
                        print("[AppObservableObject] ✅ 解析成功")
                        print("[AppObservableObject] 绘本页数：\(decoded.pages.count)")
                        for (index, page) in decoded.pages.enumerated() {
                            let hasPrompt = (page.imagePrompt ?? "").isEmpty ? "无" : "有"
                            print("[AppObservableObject] 第\(index + 1)页 - text 长度：\(page.text.count)，imagePrompt：\(hasPrompt)")
                        }
                        
                        await MainActor.run {
                            self.pages = decoded.pages
                            self.status = .success
                        }
                    } catch {
                        print("[AppObservableObject] ❌ JSON解析失败：\(error)")
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("[AppObservableObject] 响应内容：\(responseString)")
                        }
                        await MainActor.run {
                            self.status = .failed
                            self.pages = []
                        }
                    }
                } else {
                    // HTTP错误
                    let errorMessage: String
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("[AppObservableObject] ❌ HTTP错误响应：\(responseString)")
                        errorMessage = "HTTP \(httpResponse.statusCode): \(responseString.prefix(100))"
                    } else {
                        errorMessage = "HTTP错误：\(httpResponse.statusCode)"
                    }
                    
                    print("[AppObservableObject] ❌ HTTP状态码错误：\(httpResponse.statusCode)")
                    await MainActor.run {
                        self.status = .failed
                        self.pages = []
                    }
                }
            } else {
                print("[AppObservableObject] ❌ 无法获取HTTP响应")
                await MainActor.run {
                    self.status = .failed
                    self.pages = []
                }
            }
        } catch {
            print("[AppObservableObject] ❌ 网络请求异常：\(error)")
            print("[AppObservableObject] 错误详情：\(error.localizedDescription)")
            await MainActor.run {
                self.status = .failed
                self.pages = []
            }
        }
    }
    
    // MARK: - 按页异步生图（翻到该页时再请求，间隔 2 秒避免 429）
    
    /// 任务 B：调用 Supabase 生图代理（传 imagePrompt），后端挂 Key 转发，iOS 不持有 REPLICATE_API_KEY
    /// 超时 120 秒以兼容后端轮询；频率由调用方控制（翻页触发 + 2 秒间隔）
    func generateImage(prompt: String) async -> String? {
        var request = URLRequest(url: generateImageProxyURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 120.0
        let body: [String: String] = ["imagePrompt": prompt]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        request.httpBody = bodyData
        print("[AppObservableObject] 任务 B：生图代理请求开始，imagePrompt 长度：\(prompt.count)")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let http = response as? HTTPURLResponse
            let code = http?.statusCode ?? -1
            if code != 200 {
                let msg = String(data: data, encoding: .utf8) ?? ""
                print("[AppObservableObject] 生图代理非 200：\(code)，body：\(msg.prefix(200))")
                return nil
            }
            struct ImageResponse: Codable { let imageUrl: String }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decoded = try decoder.decode(ImageResponse.self, from: data)
            print("[AppObservableObject] 生图成功，URL：\(decoded.imageUrl.prefix(60))...")
            return decoded.imageUrl
        } catch {
            print("[AppObservableObject] 生图请求异常：\(error)")
            return nil
        }
    }
    
    /// 更新某一页的图片 URL（主线程）
    func updatePageImageUrl(pageId: UUID, imageUrl: String) {
        guard let idx = pages.firstIndex(where: { $0.id == pageId }) else {
            print("[AppObservableObject] 未找到 pageId：\(pageId)，无法更新图片")
            return
        }
        pages[idx].imageUrl = imageUrl
        print("[AppObservableObject] 已更新第 \(idx + 1) 页图片 URL")
    }
    
    /// 下载图片并转换成 UIImage 存入缓存（用于预加载，实现 0 毫秒延迟）
    /// 同时存入 preloadedImages（当前会话）和 ImageCache（持久化缓存）
    func downloadAndCacheImage(pageId: UUID, imageUrl: String) async -> UIImage? {
        guard let url = URL(string: imageUrl) else {
            print("[AppObservableObject] 无效的图片 URL：\(imageUrl)")
            return nil
        }
        // 使用 ImageCache 加载（会利用内存+磁盘缓存，如果已缓存则直接返回）
        guard let image = await ImageCache.shared.load(url: url) else {
            print("[AppObservableObject] ImageCache 加载失败")
            return nil
        }
        // 同时存入 preloadedImages，供当前会话快速访问
        await MainActor.run {
            preloadedImages[pageId] = image
        }
        print("[AppObservableObject] 已缓存图片到内存和 ImageCache，pageId：\(pageId)")
        return image
    }
    
    /// 生成语音：传入文本，返回 Base64 音频字符串
    func generateAudio(text: String) async -> String? {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        var request = URLRequest(url: generateAudioURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 120.0 // 语音合成涉及神经网络运算，建议不低于 30 秒
        let body: [String: String] = ["text": text]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        request.httpBody = bodyData
        print("[AppObservableObject] 任务 C：语音生成请求开始，text 长度：\(text.count)")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let http = response as? HTTPURLResponse
            let code = http?.statusCode ?? -1
            if code != 200 {
                let msg = String(data: data, encoding: .utf8) ?? ""
                if code == 400 {
                    print("[AppObservableObject] 语音生成 400（可能触发了敏感词过滤），body：\(msg.prefix(200))")
                } else {
                    print("[AppObservableObject] 语音生成非 200：\(code)，body：\(msg.prefix(200))")
                }
                return nil
            }
            struct AudioResponse: Codable {
                let audio: String?
                let audioBase64: String?
                let audioContent: String?
                enum CodingKeys: String, CodingKey {
                    case audio
                    case audioBase64 = "audio_base64"
                    case audioContent = "audioContent"  // 后端返回驼峰格式
                }
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decoded = try decoder.decode(AudioResponse.self, from: data)
            
            // 调试：打印各字段内容长度
            if let a = decoded.audio {
                print("[AppObservableObject] DEBUG: audio 字段长度 \(a.count)")
            }
            if let ab = decoded.audioBase64 {
                print("[AppObservableObject] DEBUG: audioBase64 字段长度 \(ab.count)")
            }
            if let ac = decoded.audioContent {
                print("[AppObservableObject] DEBUG: audioContent 字段长度 \(ac.count)")
            }
            
            let result = decoded.audio ?? decoded.audioBase64 ?? decoded.audioContent
            if let r = result {
                print("[AppObservableObject] 语音生成成功，Base64 长度：\(r.count)")
            } else {
                let raw = String(data: data, encoding: .utf8) ?? ""
                print("[AppObservableObject] 语音生成 200 但响应中无音频字段（请核对接口返回 key），body 前 200 字：\(raw.prefix(200))")
            }
            return result
        } catch {
            print("[AppObservableObject] 语音生成请求异常：\(error)")
            return nil
        }
    }
    
    /// 翻到该页时调用：若该页有 imagePrompt 且尚无 imageUrl，则间隔 2 秒后请求生图并更新
    func requestImageGenerationIfNeeded(for page: StoryPage) async {
        let prompt = page.imagePrompt ?? ""
        guard !prompt.isEmpty, page.imageUrl.isEmpty else { return }
        await MainActor.run {
            if pageIdsGenerationStarted.contains(page.id) {
                return
            }
            pageIdsGenerationStarted.insert(page.id)
        }
        let interval: TimeInterval = 2.0
        let elapsed = Date().timeIntervalSince(lastImageGenerationStartTime)
        let delay = max(0, interval - elapsed)
        if delay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        await MainActor.run { lastImageGenerationStartTime = Date() }
        print("[AppObservableObject] 开始为该页生图，pageId：\(page.id)")
        guard let url = await generateImage(prompt: prompt) else { return }
        await MainActor.run {
            updatePageImageUrl(pageId: page.id, imageUrl: url)
        }
    }
}//
//  AppObservableObject.swift
//  AI Picture Book
//
//  Created by LazyG on 2026/2/7.
//

