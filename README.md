# StorageScope

StorageScope scans your Mac for caches, generated files, developer build data, logs, local backups, and other large storage. Each result shows what it contains, how much space it uses, and what removing it will change.

[Download StorageScope for macOS](https://github.com/Silverdragon122/StorageScope/releases/latest)

Requires macOS 14 Sonoma or later.

## Install

1. Download the App ZIP from the latest release.
2. Open it and drag StorageScope to your Applications folder.
3. Launch StorageScope and follow the Full Disk Access setup.

Full Disk Access lets StorageScope measure private app storage in one scan. Scanning only reads file metadata; it does not change your files.

## What it finds

StorageScope checks common macOS storage locations, including:

- Xcode builds, archives, simulators, and package-manager caches
- Browser and application caches
- Logs, diagnostic reports, temporary files, and tool downloads
- Generated media from creative applications
- iPhone and iPad backups
- Local models, virtual machines, cloud data, and macOS-managed storage

StorageScope separates results into three groups:

- **Ready to Remove** — caches and generated files that applications can recreate
- **Review Required** — items that may contain personal data, offline files, or application state
- **Managed Elsewhere** — protected or system-managed storage shown for context

Protected items cannot be selected in StorageScope.

## Before anything is deleted

You choose the items to remove. StorageScope shows every selection and its consequence before asking for final confirmation.

When cleanup begins, it checks each item again against the current scan and stops if the path, filesystem identity, or safety classification has changed. It does not follow symbolic links or cross into another mounted volume. If an application is using a selected item, cleanup pauses and asks you to quit it. Some system locations also require administrator approval.

Deletion is permanent. Keep a current backup and read the description for every item marked Review Required.

## Privacy

Scanning and cleanup happen on your Mac. StorageScope does not upload file contents or scan results, and it does not require an account.

## Build from source

StorageScope is a Swift 6 and SwiftUI project.

```sh
git clone https://github.com/Silverdragon122/StorageScope.git
cd StorageScope
open StorageScope.xcodeproj
```

Build the `StorageScope` scheme in Xcode. Core tests can also be run from the repository root:

```sh
swift test
```

## Reporting a problem

If StorageScope classifies a location incorrectly or fails during a scan or cleanup, [open an issue](https://github.com/Silverdragon122/StorageScope/issues). Include the item name and the error shown by the app, but remove usernames, file names, and other private information from paths or screenshots.
