import Foundation

enum StorageCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case developer
    case creative
    case appCaches
    case browsers
    case backups
    case logsAndTemporary
    case localModels
    case largeAppData
    case systemManaged

    var id: String { rawValue }
}

