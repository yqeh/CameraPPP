//
//  AppLanguage.swift
//  CameraPPP
//
//  Created by OpenAI on 2026/6/5.
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case traditionalChinese = "zh-Hant"
    case english = "en"
    
    static let storageKey = "appLanguage"
    
    var id: String { rawValue }
    
    var localeIdentifier: String {
        rawValue
    }
    
    var localizedName: String {
        switch self {
        case .traditionalChinese:
            return AppLanguage.current == .traditionalChinese ? "繁體中文" : "Traditional Chinese"
        case .english:
            return "English"
        }
    }

    var displayName: String {
        switch self {
        case .traditionalChinese:
            return "中文"
        case .english:
            return "English"
        }
    }
    
    func localized(_ english: String, _ traditionalChinese: String) -> String {
        switch self {
        case .traditionalChinese:
            return traditionalChinese
        case .english:
            return english
        }
    }
    
    static var current: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? traditionalChinese.rawValue) ?? .traditionalChinese
    }
}
