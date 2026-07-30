//
//  PhotoSettingsView.swift
//  CameraPPP
//
//  Created by Otis Lin on 2026/5/22.
//

import SwiftUI

struct PhotoSettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("photo_notifyComplete") private var notifyComplete = true
    @AppStorage("photo_vibrateStart") private var vibrateStart = true
    @AppStorage("photo_vibrateComplete") private var vibrateComplete = true
    @AppStorage("photo_flashlight") private var flashlight = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                Text("Photo settings (BETA)")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding()
            .background(Color.black)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    
                    // MARK: - GENERAL SETTINGS
                    SectionHeader(title: "GENERAL SETTINGS")
                    
                    SettingsToggleRow(
                        icon: "bell.fill",
                        title: "Capturing complete",
                        subtitle: "Show a notification when taking photo completed",
                        isOn: $notifyComplete
                    )
                    
                    SettingsToggleRow(
                        icon: "iphone.radiowaves.left.and.right",
                        title: "Vibrate when start",
                        subtitle: nil,
                        isOn: $vibrateStart
                    )
                    
                    SettingsToggleRow(
                        icon: "iphone.radiowaves.left.and.right",
                        title: "Vibrate when complete",
                        subtitle: nil,
                        isOn: $vibrateComplete
                    )
                    
                    Divider().padding(.vertical, 5)
                    
                    // MARK: - VIEW SETTINGS
                    SectionHeader(title: "VIEW SETTINGS")
                    
                    SettingsActionRow(
                        icon: "camera.aperture",
                        title: "Camera",
                        subtitle: "Back"
                    ) {}
                    
                    SettingsActionRow(
                        icon: "camera.fill",
                        title: "Back camera resolution",
                        subtitle: "Full resolution ratio 4:3"
                    ) {}
                    
                    SettingsActionRow(
                        icon: "person.crop.square.fill",
                        title: "Front camera resolution",
                        subtitle: "Full resolution ratio 4:3"
                    ) {}
                    
                    SettingsActionRow(
                        icon: "hq",
                        title: "Capture mode",
                        subtitle: "Maximize quality"
                    ) {}
                    
                    SettingsToggleRow(
                        icon: "bolt.fill",
                        title: "Flashlight",
                        subtitle: "Enable flashlight when take photo",
                        isOn: $flashlight
                    )
                    
                    Divider().padding(.vertical, 5)
                    
                    // MARK: - SHORTCUT SETTINGS
                    SectionHeader(title: "SHORTCUT SETTINGS")
                    
                    ColoredIconActionRow(
                        icon: "camera.fill",
                        iconBgColor: Color.red.opacity(0.8),
                        title: "Take Photo",
                        subtitle: "Take Photo"
                    ) {}
                    
                    ColoredIconActionRow(
                        icon: "camera.fill",
                        iconBgColor: Color.red.opacity(0.8),
                        title: "Back Camera Photo",
                        subtitle: nil
                    ) {}
                    
                    ColoredIconActionRow(
                        icon: "person.crop.square.fill",
                        iconBgColor: Color.red.opacity(0.8),
                        title: "Front Camera Photo",
                        subtitle: nil
                    ) {}
                    
                    Divider().padding(.vertical, 5)
                    
                    // MARK: - WIDGET SETTINGS
                    SectionHeader(title: "WIDGET SETTINGS")
                    
                    ColoredIconActionRow(
                        icon: "camera.fill",
                        iconBgColor: Color(UIColor.darkGray),
                        title: "Back camera photo widget",
                        subtitle: "Choose icon to change"
                    ) {}
                    
                    ColoredIconActionRow(
                        icon: "person.crop.square.fill",
                        iconBgColor: Color(UIColor.darkGray),
                        title: "Front camera photo widget",
                        subtitle: "Choose icon to change"
                    ) {}
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .background(Color.black)
    }
}

// MARK: - 專屬 UI 元件

struct SectionHeader: View {
    var title: LocalizedStringKey
    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(Color.red.opacity(0.8))
            .padding(.horizontal, 20)
            .padding(.top, 15)
            .padding(.bottom, 10)
    }
}

struct ColoredIconActionRow: View {
    var icon: String
    var iconBgColor: Color
    var title: LocalizedStringKey
    var subtitle: LocalizedStringKey?
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 20) {
                // 圓形背景 Icon
                ZStack {
                    Circle()
                        .fill(iconBgColor)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
