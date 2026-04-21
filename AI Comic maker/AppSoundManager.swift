//
//  AppSoundManager.swift
//  AI Comic maker
//
//  全局点击音效：ui_click.wav
//

import AVFoundation
import SwiftUI

/// 播放 UI 点击音效（与其它音频混播，不打断）
final class AppSoundManager {
    static let shared = AppSoundManager()
    private var clickPlayer: AVAudioPlayer?
    private var soundEffectPlayers: [String: AVAudioPlayer] = [:]
    private let clickFileName = "ui_click"
    private let clickExt = "wav"

    private init() {}

    /// 播放点击音效（从 bundle 加载 ui_click.wav）
    func playClick() {
        guard let url = Bundle.main.url(forResource: clickFileName, withExtension: clickExt)
            ?? Bundle.main.url(forResource: clickFileName, withExtension: clickExt, subdirectory: nil) else {
            print("[AppSoundManager] 未找到 \(clickFileName).\(clickExt)，请加入 Target → Copy Bundle Resources")
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[AppSoundManager] AVAudioSession 配置失败: \(error)")
            return
        }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.volume = 1.0
            p.prepareToPlay()
            p.play()
            clickPlayer = p
            print("[AppSoundManager] 播放点击音效")
        } catch {
            print("[AppSoundManager] 播放失败: \(error)")
        }
    }
    
    /// 播放指定音效文件（支持 wav/mp3）
    /// - Parameters:
    ///   - fileName: 文件名（不含扩展名）
    ///   - ext: 扩展名（默认 "wav"）
    ///   - subdirectory: 子目录（如 "sound"）
    ///   - volume: 音量（0.0-1.0，默认 1.0）
    func playSoundEffect(fileName: String, ext: String = "wav", subdirectory: String? = "sound", volume: Float = 1.0) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: ext, subdirectory: subdirectory)
            ?? Bundle.main.url(forResource: fileName, withExtension: ext) else {
            print("[AppSoundManager] 未找到音效文件: \(fileName).\(ext)")
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[AppSoundManager] AVAudioSession 配置失败: \(error)")
            return
        }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.volume = volume
            p.prepareToPlay()
            p.play()
            soundEffectPlayers[fileName] = p
            print("[AppSoundManager] 播放音效: \(fileName).\(ext)")
        } catch {
            print("[AppSoundManager] 播放音效失败: \(error)")
        }
    }
}

// MARK: - 带点击音效的按钮样式（外观同 .plain）

struct ClickSoundButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed { AppSoundManager.shared.playClick() }
            }
    }
}
