//
//  TrialManager.swift
//  CameraPPP
//
//  新下載 3 小時試用期管理
//

import Foundation

@MainActor
final class TrialManager: ObservableObject {
    static let shared = TrialManager()

    @Published private(set) var firstInstallDate: Date

    private init() {
        if let savedDate = UserDefaults.standard.object(forKey: SubscriptionConfig.firstInstallDateKey) as? Date {
            firstInstallDate = savedDate
        } else {
            let now = Date()
            firstInstallDate = now
            UserDefaults.standard.set(now, forKey: SubscriptionConfig.firstInstallDateKey)
        }
    }

    /// 試用期是否仍在進行中
    var isTrialActive: Bool {
        Date().timeIntervalSince(firstInstallDate) < SubscriptionConfig.trialDuration
    }

    /// 試用剩餘秒數
    var remainingTrialSeconds: TimeInterval {
        max(0, SubscriptionConfig.trialDuration - Date().timeIntervalSince(firstInstallDate))
    }

    /// 試用剩餘時間文字
    var remainingTrialText: String {
        let totalSeconds = Int(remainingTrialSeconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 {
            return AppLanguage.current.localized(
                "\(hours)h \(minutes)m remaining",
                "剩餘 \(hours) 小時 \(minutes) 分鐘"
            )
        }

        return AppLanguage.current.localized(
            "\(minutes)m remaining",
            "剩餘 \(minutes) 分鐘"
        )
    }

    /// 是否應顯示付費牆（試用結束且未訂閱）
    func shouldShowPaywall(isPremium: Bool) -> Bool {
        !isPremium && !isTrialActive
    }
}
