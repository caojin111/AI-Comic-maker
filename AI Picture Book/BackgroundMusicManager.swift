//
//  BackgroundMusicManager.swift
//  AI Picture Book
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

    private init() {}

    /// Start playing a random track from the music folder. Loops until stopped.
    func playRandomTrack() {
        guard let url = randomMusicURL() else {
            print("[BackgroundMusicManager] No music files found in \(musicFolder)")
            return
        }
        stop()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
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
        isPlaying = false
    }

    private func randomMusicURL() -> URL? {
        // Try multiple subdirectory paths (Xcode bundle layout may vary)
        let candidates = [musicFolder, "AI Picture Book/\(musicFolder)", nil as String?]
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
