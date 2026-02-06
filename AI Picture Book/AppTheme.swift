//
//  AppTheme.swift
//  AI Picture Book
//
//  主题色与设计常量
//

import SwiftUI

enum AppTheme {
    /// 行动唤起色 / 主题色（亮紫色 #6347F1）
    static let primary = Color(hex: "6347F1")
    
    /// 背景色
    static let bgPrimary = Color(hex: "FFF8F0")
    
    /// 次要文字色
    static let textSecondary = Color(hex: "6B6B6B")
    
    /// 主文字色
    static let textPrimary = Color(hex: "2C2C2C")
    
    /// 次要填充色（进度条轨道等）
    static let secondary = Color(hex: "D9D9DB")
    
    /// OB开始页背景色（深紫色 #21164F）
    static let obStartBackground = Color(hex: "21164F")
    
    /// 卡片阴影
    static let shadowColor = Color.black.opacity(0.05)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
