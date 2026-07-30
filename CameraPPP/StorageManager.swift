//
//  StorageManager.swift
//  CameraPPP
//
//  Created by Otis Lin on 2026/5/21.
//

import Foundation

actor StorageManager {
    static let shared = StorageManager()
    
    private let fileManager = FileManager.default
    private let mediaDirectory: URL
    
    private init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        mediaDirectory = appSupport.appendingPathComponent("SecureMedia", isDirectory: true)
        
        if !fileManager.fileExists(atPath: mediaDirectory.path) {
            try? fileManager.createDirectory(at: mediaDirectory, withIntermediateDirectories: true)
        }
    }
    
    func saveVideo(from tempURL: URL) throws -> URL {
        let fileName = UUID().uuidString + ".mp4"
        let destinationURL = mediaDirectory.appendingPathComponent(fileName)
        
        try fileManager.moveItem(at: tempURL, to: destinationURL)
        try fileManager.setAttributes([.extensionHidden: true, .posixPermissions: 0o600], ofItemAtPath: destinationURL.path)
        
        return destinationURL
    }

    func savePhoto(from data: Data) throws -> URL {
        let fileName = UUID().uuidString + ".jpg"
        let destinationURL = mediaDirectory.appendingPathComponent(fileName)

        try data.write(to: destinationURL, options: .atomic)
        try fileManager.setAttributes([.extensionHidden: true, .posixPermissions: 0o600], ofItemAtPath: destinationURL.path)

        return destinationURL
    }
    
    func fetchAllMedia() -> [URL] {
        fetchFiles(withExtensions: ["mp4"])
    }

    func fetchAllPhotos() -> [URL] {
        fetchFiles(withExtensions: ["jpg", "jpeg", "png"])
    }

    private func fetchFiles(withExtensions extensions: [String]) -> [URL] {
        guard let files = try? fileManager.contentsOfDirectory(
            at: mediaDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else {
            return []
        }

        return files
            .filter { extensions.contains($0.pathExtension.lowercased()) }
            .sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast

                return date1 > date2
            }
    }
}
