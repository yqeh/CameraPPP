//
//  CameraManager.swift
//  CameraPPP
//
//  Created by Otis Lin on 2026/5/21.
//

@preconcurrency import AVFoundation
import Combine
import SwiftUI

enum CameraFacing: Int, CaseIterable, Identifiable {
    case back = 0
    case front = 1
    
    static let storageKey = "preferredCameraFacing"
    
    var id: Int { rawValue }
    
    var displayName: LocalizedStringKey {
        switch self {
        case .back:
            return "Back camera"
        case .front:
            return "Front camera"
        }
    }

    var settingsDisplayName: String {
        switch self {
        case .back:
            return "後置鏡頭"
        case .front:
            return "前置鏡頭"
        }
    }
    
    var avCapturePosition: AVCaptureDevice.Position {
        switch self {
        case .back:
            return .back
        case .front:
            return .front
        }
    }
}

@Observable
final class CameraManager: NSObject, Sendable {
    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let fileOutput = AVCaptureMovieFileOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private var activePhotoCaptureDelegate: PhotoCaptureDelegate?
    
    private let sessionQueue = DispatchQueue(label: "com.app.camera.sessionQueue")
    private let motionDetector = MotionDetector()
    private var cameraFacing: CameraFacing

    var isRecording = false
    var isHumanDetected = false
    var isAuthorized = false
    
    init(initialCameraFacing: CameraFacing = .back) {
        self.cameraFacing = initialCameraFacing
        super.init()
        Task {
            await checkPermission()
            if isAuthorized {
                sessionQueue.async { self.configureSession() }
            } else {
                print("使用者拒絕了相機權限")
            }
        }
    }
    
    // MARK: - 權限檢查
     private func checkPermission() async {
         let status = AVCaptureDevice.authorizationStatus(for: .video)
         switch status {
         case .authorized:
             isAuthorized = true
         case .notDetermined:
             isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
         case .denied, .restricted:
             isAuthorized = false
         @unknown default:
             isAuthorized = false
         }
     }
     
    
    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .hd1280x720
        
        installCameraInput()
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.app.camera.videoQueue"))
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
        if session.canAddOutput(fileOutput) { session.addOutput(fileOutput) }
        if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
        photoOutput.maxPhotoQualityPrioritization = .quality
        
        session.commitConfiguration()
        session.startRunning()
    }

    func updateCameraFacing(_ facing: CameraFacing) {
        guard cameraFacing != facing else { return }
        cameraFacing = facing
        
        sessionQueue.async {
            guard self.session.isRunning, !self.fileOutput.isRecording else { return }
            self.session.beginConfiguration()
            self.installCameraInput()
            self.session.commitConfiguration()
        }
    }

    private func installCameraInput() {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraFacing.avCapturePosition) ??
                AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }
        
        for input in session.inputs {
            session.removeInput(input)
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
    }

    func startRecording() {
        sessionQueue.async {
            guard !self.fileOutput.isRecording else { return }
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
            self.fileOutput.startRecording(to: tempURL, recordingDelegate: self)
            Task { @MainActor in self.isRecording = true }
        }
    }
    
    func stopRecording() {
        sessionQueue.async {
            self.fileOutput.stopRecording()
            Task { @MainActor in self.isRecording = false }
        }
    }

    func capturePhoto() {
        sessionQueue.async {
            guard self.fileOutput.isRecording else { return }
            guard self.activePhotoCaptureDelegate == nil else { return }

            let settings = AVCapturePhotoSettings()
            settings.flashMode = .off
            settings.photoQualityPrioritization = .quality

            let delegate = PhotoCaptureDelegate(manager: self)

            self.activePhotoCaptureDelegate = delegate
            self.photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }

    fileprivate func handleCapturedPhoto(data: Data?, error: Error?) {
        sessionQueue.async {
            self.activePhotoCaptureDelegate = nil
        }

        if let error {
            print("Failed to capture photo: \(error)")
            return
        }

        guard let data else {
            print("Failed to generate photo data")
            return
        }

        Task {
            do {
                let savedURL = try await StorageManager.shared.savePhoto(from: data)
                print("Securely saved photo to sandbox: \(savedURL)")
            } catch {
                print("Failed to save photo: \(error)")
            }
        }
    }
}

// MARK: - Video Data Delegate (Vision Trigger)
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        Task {
            let detected = await motionDetector.detectHuman(in: sampleBuffer)
            if detected {
                await MainActor.run { self.isHumanDetected = true }
            }
        }
    }
}

// MARK: - File Output Delegate
extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        Task {
            do {
                let savedURL = try await StorageManager.shared.saveVideo(from: outputFileURL)
                print("Securely saved to sandbox: \(savedURL)")
            } catch {
                print("Failed to save video: \(error)")
            }
        }
    }
}

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private unowned let manager: CameraManager
    
    init(manager: CameraManager) {
        self.manager = manager
    }
    
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let data = photo.fileDataRepresentation()
        Task { @MainActor in
            manager.handleCapturedPhoto(data: data, error: error)
        }
    }
}
