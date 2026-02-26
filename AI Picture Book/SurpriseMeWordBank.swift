//
//  SurpriseMeWordBank.swift
//  AI Picture Book
//
//  从本地 JSON 加载 Surprise me 词库，支持双主角与 lesson 概率。
//

import Foundation

struct SurpriseMeWordBank: Codable {
    let characters: [String]
    let locations: [String]
    let actions: [String]
    let lessons: [String]
}

enum SurpriseMeWordBankLoader {
    private static let filename = "SurpriseMeWordBank"
    
    /// 双主角出现概率 (0...1)，例如 0.35 表示 35% 概率出现第二个角色
    static let dualCharacterProbability: Double = 0.35
    
    /// lesson 出现概率 (0...1)，例如 0.3 表示 30% 概率加上「学会了什么」
    static let lessonProbability: Double = 0.3
    
    private static var cached: SurpriseMeWordBank?
    
    static func load() -> SurpriseMeWordBank? {
        if let c = cached { return c }
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(SurpriseMeWordBank.self, from: data) else {
            print("[SurpriseMeWordBank] 无法加载 \(filename).json")
            return nil
        }
        cached = decoded
        print("[SurpriseMeWordBank] 已加载：characters=\(decoded.characters.count), locations=\(decoded.locations.count), actions=\(decoded.actions.count), lessons=\(decoded.lessons.count)")
        return decoded
    }
    
    /// 生成一句随机主题：character(s) + location + action，概率加 lesson
    static func generateTheme() -> String {
        guard let bank = load(),
              !bank.characters.isEmpty,
              !bank.locations.isEmpty,
              !bank.actions.isEmpty else {
            return "A little cat in the clouds dancing"
        }
        
        let c1 = bank.characters.randomElement()!
        let loc = bank.locations.randomElement()!
        let act = bank.actions.randomElement()!
        
        var who: String
        if Double.random(in: 0..<1) < dualCharacterProbability, let c2 = bank.characters.randomElement(), c2 != c1 {
            who = "\(c1) and \(c2)"
        } else {
            who = c1
        }
        
        var sentence = "\(who) \(loc) \(act)"
        if !bank.lessons.isEmpty, Double.random(in: 0..<1) < lessonProbability {
            let lesson = bank.lessons.randomElement()!
            sentence += ". They learned that \(lesson)."
        }
        return sentence
    }
}
