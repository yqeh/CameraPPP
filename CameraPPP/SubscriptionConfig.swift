//
//  SubscriptionConfig.swift
//  CameraPPP
//
//  訂閱方案設定（Product ID 與試用期）
//

import Foundation

enum SubscriptionConfig {
    /// 月訂閱 Product ID（須與 App Store Connect 一致）
    static let monthlyProductID = "com.lin.energysaving.premium.monthly"
    /// 年訂閱 Product ID（須與 App Store Connect 一致）
    static let yearlyProductID = "com.lin.energysaving.premium.yearly"

    static let allProductIDs: [String] = [
        monthlyProductID,
        yearlyProductID
    ]

    /// App Store Connect 建議定價（台幣，實際價格由 StoreKit 回傳）
    static let fallbackMonthlyPrice = "NT$299"
    static let fallbackYearlyPrice = "NT$899"

    /// 新下載試用時長：3 小時（Debug 模式為 60 秒方便測試）
    #if DEBUG
    static let trialDuration: TimeInterval = 60
    #else
    static let trialDuration: TimeInterval = 3 * 60 * 60
    #endif

    static let firstInstallDateKey = "premiumFirstInstallDate"
    static let premiumStatusKey = "isPremiumUnlocked"

    /// 隱私權與服務條款（上架前請替換為正式網址）
    static let privacyPolicyURL = "https://example.com/privacy"
    static let termsOfUseURL = "https://example.com/terms"
}
