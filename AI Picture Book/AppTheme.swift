//
//  AppTheme.swift
//  AI Picture Book
//
//  主题色与设计常量
//

import SwiftUI

enum AppTheme {
    /// 行动唤起色 / 主题色（橙色 #FFB979）
    static let primary = Color(hex: "FFB979")
    
    /// 背景色（深紫色 #221750）
    static let bgPrimary = Color(hex: "221750")
    
    /// 次要文字色（浅灰色，用于深色背景）
    static let textSecondary = Color(hex: "B0B0B0")
    
    /// 主文字色（白色，用于深色背景）
    static let textPrimary = Color(hex: "FFFFFF")
    
    /// 浅色背景上的文字（深灰，用于 OB 白底卡片等）
    static let textOnLight = Color(hex: "333333")
    
    /// 次要填充色（进度条轨道等，使用蓝色 #2CD0FE）
    static let secondary = Color(hex: "2CD0FE")
    
    /// OB开始页背景色（深紫色 #221750，与主背景一致）
    static let obStartBackground = Color(hex: "221750")
    
    /// 卡片阴影（深色背景下的阴影）
    static let shadowColor = Color.black.opacity(0.3)
    
    // MARK: - 点缀色
    
    /// 橙色点缀色 #FFB979
    static let accentOrange = Color(hex: "FFB979")
    
    /// 蓝色点缀色 #2CD0FE
    static let accentBlue = Color(hex: "2CD0FE")
    
    /// 紫色点缀色 #594CE6
    static let accentPurple = Color(hex: "594CE6")
    
    /// 卡片背景色（深色背景下的卡片）
    static let cardBackground = Color(hex: "2A1F5A")
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
