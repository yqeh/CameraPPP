//
//  PrivacyCamApp.swift
//  CameraPPP
//
//  Created by Otis Lin on 2026/5/21.
//

import SwiftUI

@main
struct PrivacyCamApp: App {
    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw = AppLanguage.traditionalChinese.rawValue
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var trialManager = TrialManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainContainerView()
                .preferredColorScheme(.dark)
                .environment(\.locale, Locale(identifier: appLanguageRaw))
                .environmentObject(subscriptionManager)
                .environmentObject(trialManager)
        }
    }
}
