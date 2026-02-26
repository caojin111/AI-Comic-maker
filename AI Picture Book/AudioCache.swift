//
//  AudioCache.swift
//  AI Picture Book
//
//  语音存储：按 pageId 持久化。使用 Application Support 以在系统清理缓存、低存储时保留，仅随故事删除而删除。
//

import Foundation

/// 语音存储服务（与故事生命周期绑定，存在 Application Support 以提升持久性）
final class AudioCache {
    static let shared = AudioCache()
    
    private let fileManager = FileManager.default
    private let diskCacheDirectory: URL
    
    private init() {
        // 使用 Application Support，避免被系统当作“可清理缓存”在低存储时删除；仅升级客户端时目录会保留
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        diskCacheDirectory = appSupport.appendingPathComponent("AudioCache", isDirectory: true)
        try? fileManager.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
        migrateFromCachesIfNeeded()
    }
    
    /// 一次性迁移：将旧版存在 Caches/AudioCache 的语音迁移到 Application Support，升级后仍保留原有语音
    private func migrateFromCachesIfNeeded() {
        let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let oldDir = cachesURL.appendingPathComponent("AudioCache", isDirectory: true)
        guard fileManager.fileExists(atPath: oldDir.path) else { return }
        guard let entries = try? fileManager.contentsOfDirectory(at: oldDir, includingPropertiesForKeys: nil) else { return }
        var migrated = 0
        for src in entries where src.pathExtension.lowercased() == "wav" || src.pathExtension.lowercased() == "mp3" {
            let dst = diskCacheDirectory.appendingPathComponent(src.lastPathComponent)
            if !fileManager.fileExists(atPath: dst.path), (try? fileManager.copyItem(at: src, to: dst)) != nil {
                migrated += 1
            }
        }
        if migrated > 0 {
            print("[AudioCache] 已从 Caches 迁移 \(migrated) 个语音文件到 Application Support")
        }
    }
    
    /// 缓存 key
    private func cacheKey(for pageId: UUID) -> String {
        "audio_\(pageId.uuidString)"
    }
    
    /// 保存 Base64 音频数据到缓存（支持 data URL 前缀如 data:audio/mpeg;base64,）
    func save(pageId: UUID, base64Data: String) -> Bool {
        var b64 = base64Data.trimmingCharacters(in: .whitespaces)
        if let range = b64.range(of: "base64,") {
            b64 = String(b64[range.upperBound...])
        }
        // 去掉所有空白（含换行），避免接口返回多行 Base64 导致解码失败
        b64 = b64.filter { !$0.isWhitespace }
        guard let data = Data(base64Encoded: b64) else {
            print("[AudioCache] Base64 解码失败，字符串长度：\(b64.count)，前 50 字符：\(b64.prefix(50))")
            return false
        }
        // 诊断：打印前 20 字节的十六进制，确认是否为 WAV/PCM/MP3
        let hexPreview = data.prefix(20).map { String(format: "%02X", $0) }.joined(separator: " ")
        print("[AudioCache] 解码后数据前 20 字节（十六进制）：\(hexPreview)")
        
        // 若缺少 WAV 头（非 RIFF），尝试添加标准 WAV 头（假设 22050Hz, 单声道, 16-bit）
        let processedData: Data
        if data.count >= 4, data.prefix(4) == Data([0x52, 0x49, 0x46, 0x46]) {
            processedData = data // 已有 WAV 头
        } else {
            print("[AudioCache] 检测到非 WAV 格式（无 RIFF 头），尝试添加 WAV 头（假设 PCM 16-bit, 22050Hz, 单声道）")
            processedData = Self.addWAVHeader(to: data, sampleRate: 22050, channels: 1, bitsPerSample: 16)
        }
        
        // 按内容检测格式并选用对应扩展名（后端可能返回 WAV 或 MP3）
        let ext = Self.detectedAudioExtension(for: processedData)
        let path = diskCacheDirectory.appendingPathComponent(cacheKey(for: pageId) + "." + ext)
        // 删除该页旧缓存（可能曾存为 .wav，现为 .mp3），避免 load 命中错误文件
        let base = cacheKey(for: pageId)
        for oldExt in ["wav", "mp3", "m4a"] where oldExt != ext {
            let oldPath = diskCacheDirectory.appendingPathComponent(base + "." + oldExt)
            try? fileManager.removeItem(at: oldPath)
        }
        do {
            try processedData.write(to: path)
            print("[AudioCache] 已缓存语音，pageId：\(pageId)，检测格式：\(ext)，大小：\(processedData.count)")
            return true
        } catch {
            print("[AudioCache] 保存失败：\(error)")
            return false
        }
    }
    
    /// 根据数据头检测音频扩展名（RIFF=wav，ID3/0xFF 0xFB=mp3）
    private static func detectedAudioExtension(for data: Data) -> String {
        if data.count >= 4, data.prefix(4) == Data([0x52, 0x49, 0x46, 0x46]) { return "wav" }
        if data.count >= 3, data.prefix(3) == Data([0x49, 0x44, 0x33]) { return "mp3" }
        if data.count >= 2, data[0] == 0xFF, (data[1] & 0xE0) == 0xE0 { return "mp3" }
        return "wav"
    }
    
    /// 为 PCM 数据添加标准 WAV 头（44 字节）
    private static func addWAVHeader(to pcmData: Data, sampleRate: Int, channels: Int, bitsPerSample: Int) -> Data {
        let dataSize = UInt32(pcmData.count)
        let byteRate = UInt32(sampleRate * channels * bitsPerSample / 8)
        let blockAlign = UInt16(channels * bitsPerSample / 8)
        
        var header = Data()
        header.append(Data("RIFF".utf8)) // ChunkID (4 bytes)
        header.append(contentsOf: withUnsafeBytes(of: UInt32(36 + dataSize).littleEndian) { Data($0) }) // ChunkSize
        header.append(Data("WAVE".utf8)) // Format (4 bytes)
        header.append(Data("fmt ".utf8)) // Subchunk1ID (4 bytes)
        header.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) }) // Subchunk1Size (16 for PCM)
        header.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) }) // AudioFormat (1 = PCM)
        header.append(contentsOf: withUnsafeBytes(of: UInt16(channels).littleEndian) { Data($0) }) // NumChannels
        header.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Data($0) }) // SampleRate
        header.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian) { Data($0) }) // ByteRate
        header.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian) { Data($0) }) // BlockAlign
        header.append(contentsOf: withUnsafeBytes(of: UInt16(bitsPerSample).littleEndian) { Data($0) }) // BitsPerSample
        header.append(Data("data".utf8)) // Subchunk2ID (4 bytes)
        header.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian) { Data($0) }) // Subchunk2Size
        
        var wavFile = header
        wavFile.append(pcmData)
        return wavFile
    }
    
    /// 从缓存加载音频，返回本地文件 URL
    func load(pageId: UUID) -> URL? {
        let base = cacheKey(for: pageId)
        for ext in ["wav", "mp3", "m4a"] {
            let path = diskCacheDirectory.appendingPathComponent(base + "." + ext)
            if fileManager.fileExists(atPath: path.path) {
                print("[AudioCache] 命中缓存，pageId：\(pageId)")
                return path
            }
        }
        return nil
    }
    
    /// 检查是否有缓存
    func hasCache(for pageId: UUID) -> Bool {
        load(pageId: pageId) != nil
    }
    
    /// 删除指定 pageId 的音频缓存
    func delete(pageId: UUID) {
        let base = cacheKey(for: pageId)
        var deletedCount = 0
        for ext in ["wav", "mp3", "m4a"] {
            let path = diskCacheDirectory.appendingPathComponent(base + "." + ext)
            if fileManager.fileExists(atPath: path.path) {
                try? fileManager.removeItem(at: path)
                deletedCount += 1
            }
        }
        if deletedCount > 0 {
            print("[AudioCache] 已删除音频缓存，pageId：\(pageId)")
        }
    }
}
