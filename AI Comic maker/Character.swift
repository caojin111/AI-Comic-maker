//
//  Character.swift
//  AI Comic maker
//
//  角色数据模型

import Foundation

struct Character: Identifiable, Codable {
    let id: UUID
    let name: String
    let imageUrl: String
    let gender: String                   // 角色性别
    let description: String              // 角色视觉特征描述
    let createdAt: Date
    
    init(id: UUID = UUID(), name: String, imageUrl: String, gender: String = "unknown", description: String = "", createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.imageUrl = imageUrl
        self.gender = gender
        self.description = description
        self.createdAt = createdAt
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: createdAt)
    }
}

