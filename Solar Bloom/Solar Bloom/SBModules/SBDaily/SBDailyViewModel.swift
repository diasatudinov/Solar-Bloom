//
//  SBDailyViewModel.swift
//  Solar Bloom
//
//

import SwiftUI

class SBDailyViewModel: ObservableObject {
    
    @Published var achievements: [NEGAchievement] = [
        NEGAchievement(image: "daily1ImageSB", title: "daily1TextCB", isAchieved: false),
        NEGAchievement(image: "daily2ImageSB", title: "daily2TextCB", isAchieved: false),
        NEGAchievement(image: "daily3ImageSB", title: "daily3TextCB", isAchieved: false),
        NEGAchievement(image: "daily4ImageSB", title: "daily4TextCB", isAchieved: false),
        NEGAchievement(image: "daily5ImageSB", title: "daily5TextCB", isAchieved: false),
    ] {
        didSet {
            saveAchievementsItem()
        }
    }
        
    init() {
        loadAchievementsItem()
    }
    
    private let userDefaultsAchievementsKey = "dailyKeySB"
    
    func achieveToggle(_ achive: NEGAchievement) {
        guard let index = achievements.firstIndex(where: { $0.id == achive.id })
        else {
            return
        }
        achievements[index].isAchieved.toggle()
        
    }
   
    
    
    func saveAchievementsItem() {
        if let encodedData = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encodedData, forKey: userDefaultsAchievementsKey)
        }
        
    }
    
    func loadAchievementsItem() {
        if let savedData = UserDefaults.standard.data(forKey: userDefaultsAchievementsKey),
           let loadedItem = try? JSONDecoder().decode([NEGAchievement].self, from: savedData) {
            achievements = loadedItem
        } else {
            print("No saved data found")
        }
    }
}
