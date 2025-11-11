//
//  ZZAchievementsViewModel.swift
//  Solar Bloom
//
//  Created by Dias Atudinov on 10.11.2025.
//


class ZZAchievementsViewModel: ObservableObject {
    
    @Published var achievements: [NEGAchievement] = [
        NEGAchievement(image: "achieve1ImageSB", title: "achieve1TextCB", isAchieved: false),
        NEGAchievement(image: "achieve2ImageSB", title: "achieve2TextCB", isAchieved: false),
        NEGAchievement(image: "achieve3ImageSB", title: "achieve3TextCB", isAchieved: false),
        NEGAchievement(image: "achieve4ImageSB", title: "achieve4TextCB", isAchieved: false),
        NEGAchievement(image: "achieve5ImageSB", title: "achieve5TextCB", isAchieved: false),
    ] {
        didSet {
            saveAchievementsItem()
        }
    }
        
    init() {
        loadAchievementsItem()
    }
    
    private let userDefaultsAchievementsKey = "achievementsKeyCB"
    
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