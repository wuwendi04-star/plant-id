import UIKit
import Foundation

enum PhotoStorageService {
    private static var plantsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("plants", isDirectory: true)
    }

    static func save(image: UIImage, plantId: UUID) throws -> String {
        let dir = plantsDirectory
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let filename = "plant_\(plantId.uuidString)_\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
        let url = dir.appendingPathComponent(filename)
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw PhotoStorageError.compressionFailed
        }
        try data.write(to: url)
        return url.path
    }

    static func delete(filePath: String) {
        let url = URL(fileURLWithPath: filePath)
        try? FileManager.default.removeItem(at: url)
    }

    static func fileExists(at filePath: String) -> Bool {
        FileManager.default.fileExists(atPath: filePath)
    }

    static func newPhotoURL(plantId: UUID) throws -> URL {
        let dir = plantsDirectory
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let filename = "plant_\(plantId.uuidString)_\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
        return dir.appendingPathComponent(filename)
    }
}

enum PhotoStorageError: LocalizedError {
    case compressionFailed

    var errorDescription: String? {
        switch self {
        case .compressionFailed: return "Failed to compress image"
        }
    }
}
