//
//  BackgroundMusicManager.swift
//  AI Comic maker
//
//  Background music: plays a random track from the music folder when entering the story book.
//

import AVFoundation
internal import Combine
import SwiftUI

/// Manages background music for the story book. Plays a random mp3 from the music folder.
final class BackgroundMusicManager: ObservableObject {
    static let shared = BackgroundMusicManager()
    @Published private(set) var isPlaying = false

    private var player: AVAudioPlayer?
    private let musicFolder = "music"
    private var currentTrackIdentifier: String?

    private init() {}

    /// 播放指定的背景音乐文件
    /// - Parameters:
    ///   - fileName: 文件名（不含扩展名）
    ///   - ext: 扩展名（默认 "mp3"）
    ///   - subdirectory: 子目录（默认 "music"）
    ///   - volume: 音量（0.0-1.0，默认 0.3）
    ///   - loops: 是否循环（默认 true）
    func playMusic(fileName: String, ext: String = "mp3", subdirectory: String? = "music", volume: Float = 0.3, loops: Bool = true, restartIfSameTrack: Bool = false) {
        let trackIdentifier = [subdirectory ?? "", fileName, ext].joined(separator: "/")
        if !restartIfSameTrack,
           currentTrackIdentifier == trackIdentifier,
           let player,
           player.isPlaying {
            print("[BackgroundMusicManager] 继续播放当前音乐: \(fileName).\(ext)")
            return
        }

        guard let url = Bundle.main.url(forResource: fileName, withExtension: ext, subdirectory: subdirectory)
            ?? Bundle.main.url(forResource: fileName, withExtension: ext) else {
            print("[BackgroundMusicManager] 未找到音乐文件: \(fileName).\(ext)")
            return
        }
        stop()
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = loops ? -1 : 0
            player?.volume = volume
            player?.prepareToPlay()
            player?.play()
            currentTrackIdentifier = trackIdentifier
            isPlaying = true
            print("[BackgroundMusicManager] 播放音乐: \(fileName).\(ext)")
        } catch {
            print("[BackgroundMusicManager] 播放音乐失败: \(error)")
        }
    }

    /// Start playing a random track from the music folder. Loops until stopped.
    func playRandomTrack() {
        guard let url = randomMusicURL() else {
            print("[BackgroundMusicManager] No music files found in \(musicFolder)")
            return
        }
        stop()
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1 // loop forever
            player?.volume = 0.5 // moderate volume
            player?.prepareToPlay()
            player?.play()
            isPlaying = true
            print("[BackgroundMusicManager] Playing: \(url.lastPathComponent)")
        } catch {
            print("[BackgroundMusicManager] Failed to play: \(error)")
        }
    }

    /// Pause background music (can resume later).
    func pause() {
        player?.pause()
        isPlaying = false
        print("[BackgroundMusicManager] Paused")
    }
    
    /// Resume background music from where it was paused.
    func resume() {
        guard let player = player else {
            // 如果没有播放器，则播放新曲目
            playRandomTrack()
            return
        }
        player.play()
        isPlaying = true
        print("[BackgroundMusicManager] Resumed")
    }

    /// Stop background music.
    func stop() {
        player?.stop()
        player = nil
        currentTrackIdentifier = nil
        isPlaying = false
    }

    private func randomMusicURL() -> URL? {
        // Try multiple subdirectory paths (Xcode bundle layout may vary)
        let candidates = [musicFolder, "AI Comic maker/\(musicFolder)", nil as String?]
        for subdir in candidates {
            let urls = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: subdir) ?? []
            if !urls.isEmpty {
                print("[BackgroundMusicManager] Found \(urls.count) mp3 in subdir: \(subdir ?? "(root)")")
                return urls.randomElement()
            }
        }
        // Fallback: enumerate bundle resource path for music folder
        if let resourcePath = Bundle.main.resourcePath {
            let musicPath = (resourcePath as NSString).appendingPathComponent(musicFolder)
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: musicPath, isDirectory: &isDir), isDir.boolValue {
                let contents = (try? FileManager.default.contentsOfDirectory(atPath: musicPath))?
                    .filter { ($0 as NSString).pathExtension.lowercased() == "mp3" }
                    .map { URL(fileURLWithPath: (musicPath as NSString).appendingPathComponent($0)) }
                if let list = contents, !list.isEmpty {
                    print("[BackgroundMusicManager] Found \(list.count) mp3 via FileManager in \(musicFolder)")
                    return list.randomElement()
                }
            }
        }
        print("[BackgroundMusicManager] No music files found in bundle")
        return nil
    }
}
