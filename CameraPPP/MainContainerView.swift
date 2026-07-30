//
//  MainContainerView.swift
//  CameraPPP
//
//  Created by Otis Lin on 2026/5/22.
//
import SwiftUI
import UIKit

struct MainContainerView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var trialManager: TrialManager
    @State private var isMenuOpen = false
    @State private var selectedTab = 0
    @AppStorage(CameraFacing.storageKey) private var preferredCameraFacingRaw = CameraFacing.back.rawValue
    @State private var navigationPath: [SideMenuDestination] = []
    @State private var showPaywall = false
    
    @State private var cameraManager: CameraManager
    
    init() {
        let savedFacing = CameraFacing(rawValue: UserDefaults.standard.integer(forKey: CameraFacing.storageKey)) ?? .back
        _cameraManager = State(initialValue: CameraManager(initialCameraFacing: savedFacing))
    }
    
    private var preferredCameraFacing: CameraFacing {
        CameraFacing(rawValue: preferredCameraFacingRaw) ?? .back
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .leading) {
                CameraPreview(session: cameraManager.session)
                    .ignoresSafeArea()
                    .opacity(cameraManager.isRecording ? 1 : 0.01)
                
                VStack(spacing: 0) {
                    CustomTopAppBar(isMenuOpen: $isMenuOpen, selectedTab: $selectedTab)
                        .opacity(cameraManager.isRecording ? 0 : 1)
                    
                    TabView(selection: $selectedTab) {
                        RecordView(cameraManager: cameraManager)
                            .tag(0)
                        
                        ScheduleView()
                            .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .ignoresSafeArea(.container, edges: .bottom)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(cameraManager.isRecording ? 0 : 1)
                .allowsHitTesting(!cameraManager.isRecording)
                
                if isMenuOpen {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation { isMenuOpen = false } }
                        .zIndex(1)
                    
                    SideMenuView(
                        isMenuOpen: $isMenuOpen,
                        openDestination: openDestination
                    )
                    .frame(width: UIScreen.main.bounds.width * 0.75)
                    .transition(.move(edge: .leading))
                    .zIndex(2)
                }

                if cameraManager.isRecording {
                    RecordingOverlayView(cameraManager: cameraManager)
                        .ignoresSafeArea()
                        .zIndex(100)
                }
            }
            .navigationDestination(for: SideMenuDestination.self) { destination in
                switch destination {
                case .gallery:
                    GalleryView()
                        .navigationBarBackButtonHidden(true)
                case .trimmer:
                    VideoTrimmerView()
                        .navigationBarBackButtonHidden(true)
                case .settings:
                    SettingsView()
                        .navigationBarBackButtonHidden(true)
                case .photoSettings:
                    PhotoSettingsView()
                        .navigationBarBackButtonHidden(true)
                case .support:
                    SupportView()
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
        .task(id: preferredCameraFacingRaw) {
            cameraManager.updateCameraFacing(preferredCameraFacing)
        }
        .onAppear {
            evaluatePaywallPresentation()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            evaluatePaywallPresentation()
        }
        .onChange(of: subscriptionManager.isPremium) { _, isPremium in
            if isPremium {
                showPaywall = false
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall)
                .environmentObject(subscriptionManager)
                .environmentObject(trialManager)
        }
    }

    private func openDestination(_ destination: SideMenuDestination) {
        navigationPath.append(destination)
    }

    /// 試用結束後自動顯示付費牆
    private func evaluatePaywallPresentation() {
        showPaywall = trialManager.shouldShowPaywall(isPremium: subscriptionManager.isPremium)
    }
}
