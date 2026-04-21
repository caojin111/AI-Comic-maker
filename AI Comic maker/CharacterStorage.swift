//
//  CharacterStorage.swift
//  AI Comic maker
//
//  本地存储角色数据

import Foundation

final class CharacterStorage {
    static let shared = CharacterStorage()
    
    private let userDefaults = UserDefaults.standard
    private let key = "savedCharacters"
    private let fileManager = FileManager.default
    private let maxCharacters = 100
    
    private var charactersDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let charactersDir = documentsDirectory.appendingPathComponent("Characters", isDirectory: true)
        try? fileManager.createDirectory(at: charactersDir, withIntermediateDirectories: true)
        return charactersDir
    }
    
    private init() {}
    
    /// 保存新角色
    func save(character: Character, imageData: Data) {
        var list = loadAll()
        list.insert(character, at: 0)
        
        // 如果超过上限，删除最旧的角色
        if list.count > maxCharacters {
            let charactersToRemove = Array(list.suffix(list.count - maxCharacters))
            list = Array(list.prefix(maxCharacters))
            
            for removedCharacter in charactersToRemove {
                deleteImageFile(for: removedCharacter)
            }
        }
        
        // 保存图片
        saveImageFile(imageData, for: character)
        
        // 保存元数据
        saveAll(list)
        print("[CharacterStorage] 已保存角色，名称：\(character.name)")
    }
    
    /// 加载所有角色
    func loadAll() -> [Character] {
        guard let data = userDefaults.data(forKey: key) else { return [] }
        do {
            let list = try JSONDecoder().decode([Character].self, from: data)
            return list
        } catch {
            print("[CharacterStorage] 加载失败：\(error)")
            return []
        }
    }
    
    /// 根据ID获取角色
    func load(id: UUID) -> Character? {
        loadAll().first { $0.id == id }
    }
    
    /// 删除角色
    func delete(id: UUID) {
        var list = loadAll()
        if let characterToDelete = list.first(where: { $0.id == id }) {
            list.removeAll { $0.id == id }
            saveAll(list)
            deleteImageFile(for: characterToDelete)
            print("[CharacterStorage] 已删除角色：\(id)")
        }
    }
    
    /// 批量删除角色
    func delete(ids: [UUID]) {
        var list = loadAll()
        let charactersToDelete = list.filter { ids.contains($0.id) }
        list.removeAll { ids.contains($0.id) }
        saveAll(list)
        for character in charactersToDelete {
            deleteImageFile(for: character)
        }
        print("[CharacterStorage] 已批量删除 \(charactersToDelete.count) 个角色")
    }
    
    /// 保存图片文件
    private func saveImageFile(_ imageData: Data, for character: Character) {
        let filePath = charactersDirectory.appendingPathComponent("\(character.id).jpg")
        try? imageData.write(to: filePath)
    }
    
    /// 删除图片文件
    private func deleteImageFile(for character: Character) {
        let filePath = charactersDirectory.appendingPathComponent("\(character.id).jpg")
        try? fileManager.removeItem(at: filePath)
    }
    
    /// 获取角色图片URL
    func getImageUrl(for character: Character) -> URL? {
        let filePath = charactersDirectory.appendingPathComponent("\(character.id).jpg")
        if fileManager.fileExists(atPath: filePath.path) {
            return filePath
        }
        return nil
    }
    
    private func saveAll(_ list: [Character]) {
        do {
            let data = try JSONEncoder().encode(list)
            userDefaults.set(data, forKey: key)
        } catch {
            print("[CharacterStorage] 保存失败：\(error)")
        }
    }
}

