//
//  AudioPlayerManager.swift
//  AI Picture Book
//
//  语音播放：从本地缓存播放，无网络请求
//

import AVFoundation
import SwiftUI
internal import Combine

/// 单例语音播放管理（优先 AVAudioPlayer，失败时用 AVAudioEngine 兜底）
class AudioPlayerManager: ObservableObject {
    static let shared = AudioPlayerManager()
    @Published var isPlaying = false
    @Published var currentPageId: UUID?
    
    private var player: AVAudioPlayer?
    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private let delegateHolder = AudioPlayerDelegateHolder()
    
    private init() {}
    
    /// 播放指定页的语音（从 AudioCache 加载）
    func play(pageId: UUID) {
        guard let url = AudioCache.shared.load(pageId: pageId) else {
            print("[AudioPlayerManager] 无缓存，pageId：\(pageId)")
            return
        }
        stop()
        let onFinish = { [weak self] in
            DispatchQueue.main.async {
                self?.isPlaying = false
                self?.currentPageId = nil
                print("[AudioPlayerManager] 播放完成")
            }
        }
        delegateHolder.onFinish = onFinish
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[AudioPlayerManager] AVAudioSession 配置失败：\(error)")
            return
        }
        
        // 1. 优先用 AVAudioPlayer(contentsOf:) 从 URL 播放（对 WAV 兼容性更好）
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = delegateHolder
            player?.prepareToPlay()
            player?.play()
            isPlaying = true
            currentPageId = pageId
            print("[AudioPlayerManager] 开始播放（AVAudioPlayer），pageId：\(pageId)")
            return
        } catch let err as NSError where err.domain == NSOSStatusErrorDomain && err.code == 1954115647 {
            print("[AudioPlayerManager] AVAudioPlayer 报 1954115647，改用 AVAudioEngine 兜底")
            player = nil
        } catch {
            print("[AudioPlayerManager] AVAudioPlayer 失败：\(error)，尝试 AVAudioEngine")
            player = nil
        }
        
        // 2. 兜底：用 AVAudioEngine + AVAudioPlayerNode 播放
        guard playWithEngine(url: url, pageId: pageId, onFinish: onFinish) else {
            print("[AudioPlayerManager] 播放失败（AVAudioPlayer 与 AVAudioEngine 均不可用）")
            return
        }
    }
    
    /// 使用 AVAudioEngine 播放（兼容非常规 WAV）
    private func playWithEngine(url: URL, pageId: UUID, onFinish: @escaping () -> Void) -> Bool {
        do {
            let file = try AVAudioFile(forReading: url)
            let format = file.processingFormat
            let frameCount = UInt32(file.length)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                print("[AudioPlayerManager] AVAudioEngine 创建 buffer 失败")
                return false
            }
            try file.read(into: buffer)
            
            let engine = AVAudioEngine()
            let playerNode = AVAudioPlayerNode()
            engine.attach(playerNode)
            engine.connect(playerNode, to: engine.mainMixerNode, format: format)
            try engine.start()
            
            playerNode.scheduleBuffer(buffer) { [weak self] in
                DispatchQueue.main.async {
                    self?.engine?.stop()
                    self?.engine = nil
                    self?.playerNode = nil
                    onFinish()
                }
            }
            playerNode.play()
            
            self.engine = engine
            self.playerNode = playerNode
            isPlaying = true
            currentPageId = pageId
            print("[AudioPlayerManager] 开始播放（AVAudioEngine），pageId：\(pageId)")
            return true
        } catch {
            print("[AudioPlayerManager] AVAudioEngine 播放失败：\(error)")
            return false
        }
    }
    
    /// 停止播放
    func stop() {
        player?.stop()
        player = nil
        if let node = playerNode {
            node.stop()
            engine?.stop()
        }
        engine = nil
        playerNode = nil
        delegateHolder.onFinish = nil
        isPlaying = false
        currentPageId = nil
    }
}

private final class AudioPlayerDelegateHolder: NSObject, AVAudioPlayerDelegate {
    var onFinish: (() -> Void)?
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish?()
    }
}
