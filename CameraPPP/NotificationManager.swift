//
//  NotificationManager.swift
//  CameraPPP
//
//  Created by Otis Lin on 2026/5/22.
//

import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print(AppLanguage.current.localized("Notification permission granted", "已允許通知權限"))
            } else if let error = error {
                print(AppLanguage.current.localized("Notification permission error: \(error.localizedDescription)", "通知權限錯誤：\(error.localizedDescription)"))
            }
        }
    }
    
    func scheduleNotification(at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = AppLanguage.current.localized("Recording Schedule Reminder", "錄影排程提醒")
        content.body = AppLanguage.current.localized(
            "Your scheduled recording time has arrived. Tap this notification to open the app and start recording.",
            "您設定的排程錄影時間已到！請點擊此通知開啟 App 開始錄影。"
        )
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print(AppLanguage.current.localized("Failed to schedule notification: \(error.localizedDescription)", "排程推播失敗：\(error.localizedDescription)"))
            } else {
                print(AppLanguage.current.localized("Notification scheduled for: \(date)", "已成功設定推播於：\(date)"))
            }
        }
    }
}
