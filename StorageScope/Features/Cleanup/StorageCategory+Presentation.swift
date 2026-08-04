import Foundation

extension StorageFilter {
    var title: String {
        switch self {
        case .all:
            AppCopy.Sidebar.allStorage
        case .category(let category):
            category.displayName
        }
    }
}

extension StorageCategory {
    var displayName: String {
        switch self {
        case .developer:
            AppCopy.Category.developer
        case .creative:
            AppCopy.Category.creative
        case .appCaches:
            AppCopy.Category.appCaches
        case .browsers:
            AppCopy.Category.browsers
        case .backups:
            AppCopy.Category.backups
        case .logsAndTemporary:
            AppCopy.Category.logsAndTemporary
        case .localModels:
            AppCopy.Category.localModels
        case .largeAppData:
            AppCopy.Category.largeAppData
        case .systemManaged:
            AppCopy.Category.systemManaged
        }
    }

    var systemImage: String {
        switch self {
        case .developer:
            "hammer"
        case .creative:
            "film"
        case .appCaches:
            "shippingbox"
        case .browsers:
            "safari"
        case .backups:
            "externaldrive"
        case .logsAndTemporary:
            "doc.text"
        case .localModels:
            "square.stack.3d.up"
        case .largeAppData:
            "folder"
        case .systemManaged:
            "lock"
        }
    }
}

extension CleanupSafety {
    var displayName: String {
        switch self {
        case .reclaimable:
            AppCopy.Safety.readyToRemove
        case .reviewRequired:
            AppCopy.Safety.reviewCarefully
        case .protected:
            AppCopy.Safety.managedElsewhere
        }
    }

    var sectionTitle: String {
        switch self {
        case .reclaimable:
            AppCopy.Safety.readyToRemove
        case .reviewRequired:
            AppCopy.Safety.reviewCarefully
        case .protected:
            AppCopy.Safety.managedElsewhere
        }
    }

    var systemImage: String {
        switch self {
        case .reclaimable:
            "checkmark.circle"
        case .reviewRequired:
            "exclamationmark.triangle"
        case .protected:
            "lock"
        }
    }
}
