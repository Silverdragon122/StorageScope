import Darwin
import Foundation

actor SafeCleanupService: StorageCleaning {
    private let catalog: CleanupCatalog
    private let homeURL: URL
    private let fileManager: FileManager
    private let commandRunner: any CommandRunning
    private let administratorFileOperator: any AdministratorFileOperating
    private let journal: CleanupJournal
    private let validator: PathBoundaryValidator

    init(
        catalog: CleanupCatalog = .standard,
        homeURL: URL = FileManager.default.homeDirectoryForCurrentUser,
        recoveryRootURL: URL? = nil,
        fileManager: FileManager = .default,
        commandRunner: any CommandRunning = ProcessCommandRunner(),
        administratorFileOperator: (any AdministratorFileOperating)? = nil,
        approvedAbsoluteCleanupRootPaths: [String] =
            PathBoundaryValidator.approvedAbsoluteCleanupRootPaths
    ) {
        let standardizedHomeURL = homeURL.standardizedFileURL
        let defaultRecoveryRoot = standardizedHomeURL
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("StorageScope", isDirectory: true)
            .appendingPathComponent("Interrupted Cleanups", isDirectory: true)

        let cleanupJournal = CleanupJournal(
            recoveryRootURL: recoveryRootURL ?? defaultRecoveryRoot,
            fileManager: fileManager
        )

        self.catalog = catalog
        self.homeURL = standardizedHomeURL
        self.fileManager = fileManager
        self.commandRunner = commandRunner
        self.administratorFileOperator = administratorFileOperator
            ?? AuthorizationServicesFileOperator(
                recoveryRootURL: cleanupJournal.recoveryRootURL
            )
        self.journal = cleanupJournal
        self.validator = PathBoundaryValidator(
            catalog: catalog,
            homeURL: standardizedHomeURL,
            fileManager: fileManager,
            approvedAbsoluteCleanupRootPaths: approvedAbsoluteCleanupRootPaths
        )
    }

    func cleanup(
        request: CleanupRequest,
        progress: @escaping @Sendable (CleanupProgress) async -> Void
    ) async -> CleanupReport {
        var results: [CleanupItemResult] = []
        var seenItemIDs: Set<String> = []
        let uniqueItems = request.items.filter {
            seenItemIDs.insert($0.id).inserted
        }

        for (index, item) in uniqueItems.enumerated() {
            if Task.isCancelled { break }

            let outcome: CleanupItemOutcome
            do {
                let validated = try validator.validate(
                    item: item,
                    activeBundleIdentifiers: request.activeBundleIdentifiers
                )

                switch item.cleanupAction {
                case .simulatorDevice(let identifier):
                    outcome = await deleteSimulatorDevice(
                        identifier: identifier,
                        estimatedBytes: item.allocatedBytes
                    )
                case .deleteItem, .deleteContents:
                    outcome = await deleteFiles(validated)
                case .none:
                    outcome = .failed(.protectedItem)
                }
            } catch let error as CleanupValidationError {
                outcome = .failed(error.reason)
            } catch is CancellationError {
                break
            } catch {
                outcome = .failed(.couldNotDelete)
            }

            results.append(
                CleanupItemResult(
                    id: item.id,
                    title: item.title,
                    outcome: outcome
                )
            )
            await progress(
                CleanupProgress(
                    completedItemCount: index + 1,
                    totalItemCount: uniqueItems.count,
                    currentItemTitle: item.title
                )
            )
        }

        await administratorFileOperator.invalidateAuthorization()
        return CleanupReport(results: results, completedAt: Date())
    }

    func recoverInterruptedCleanups() async -> RecoveryReport {
        try? journal.prepareRecoveryRoot()

        var restoredItemCount = 0
        var preservedItemCount = 0

        for operationURL in journal.operationURLs() {
            let loadedManifest: CleanupManifest
            do {
                loadedManifest = try journal.load(from: operationURL)
            } catch {
                preservedItemCount += countNonManifestItems(in: operationURL)
                continue
            }
            var manifest = loadedManifest

            for index in manifest.entries.indices {
                guard manifest.entries[index].state == .staged else { continue }

                let entry = manifest.entries[index]
                guard
                    let stagedURL = try? journal.stagedURL(
                        for: entry,
                        operationURL: operationURL
                    )
                else {
                    preservedItemCount += 1
                    continue
                }
                guard fileManager.fileExists(atPath: stagedURL.path) else {
                    manifest.entries[index].state = .deleted
                    continue
                }

                guard
                    let stagedIdentity = try? FileIdentity(url: stagedURL),
                    stagedIdentity == entry.expectedIdentity,
                    let destination = try? validator.validateRecoveryDestination(
                        for: entry
                    )
                else {
                    preservedItemCount += 1
                    continue
                }

                // A persisted user-writable journal must never initiate a root
                // operation. Privileged interrupted items remain available for
                // explicit manual recovery instead.
                guard !destination.requiresAdministratorPrivileges else {
                    preservedItemCount += 1
                    continue
                }

                let originalURL = destination.url
                guard !fileManager.fileExists(atPath: originalURL.path) else {
                    preservedItemCount += 1
                    continue
                }

                try? fileManager.createDirectory(
                    at: originalURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )

                let restoreResult = await moveItem(
                    at: stagedURL,
                    to: originalURL,
                    requiresAdministratorPrivileges: false,
                    prompt: AppCopy.Core.restoreAuthorizationPrompt
                )
                if restoreResult == .succeeded {
                    restoredItemCount += 1
                    manifest.entries[index].state = .deleted
                } else {
                    preservedItemCount += 1
                }
            }

            try? journal.save(manifest, at: operationURL)
            journal.removeOperationIfEmpty(operationURL)
        }

        await administratorFileOperator.invalidateAuthorization()
        return RecoveryReport(
            restoredItemCount: restoredItemCount,
            preservedItemCount: preservedItemCount,
            preservedLocation: preservedItemCount > 0
                ? journal.recoveryRootURL
                : nil
        )
    }

    private func deleteSimulatorDevice(
        identifier: String,
        estimatedBytes: Int64
    ) async -> CleanupItemOutcome {
        guard UUID(uuidString: identifier) != nil else {
            return .failed(.outsideAllowedLocation)
        }

        let executable = URL(fileURLWithPath: "/usr/bin/xcrun")
        guard fileManager.isExecutableFile(atPath: executable.path) else {
            return .failed(.commandUnavailable)
        }

        let result = await commandRunner.run(
            executable: executable,
            arguments: ["simctl", "delete", identifier]
        )
        guard result.terminationStatus == 0 else {
            return .failed(.commandFailed)
        }
        return .deleted(bytes: estimatedBytes)
    }

    private func deleteFiles(_ cleanup: ValidatedCleanup) async -> CleanupItemOutcome {
        guard !cleanup.targets.isEmpty else {
            return .deleted(bytes: 0)
        }

        let operationID = UUID()
        let operationURL: URL
        do {
            operationURL = try journal.createOperation(id: operationID)
        } catch {
            return .failed(.couldNotStage)
        }

        guard
            let operationIdentity = try? FileIdentity(url: operationURL),
            operationIdentity.device == cleanup.item.identity.device
        else {
            journal.removeOperationIfEmpty(operationURL)
            return .failed(.couldNotStage)
        }

        var manifest = CleanupManifest(operationID: operationID, entries: [])

        for (index, target) in cleanup.targets.enumerated() {
            if Task.isCancelled {
                await restoreStagedEntries(
                    manifest: &manifest,
                    operationURL: operationURL,
                    prompt: restorePrompt(for: cleanup.item)
                )
                return .failed(.couldNotStage)
            }

            let stagedName = String(index)
            let entry = StagedEntry(
                ruleID: cleanup.item.ruleID,
                originalPath: target.url.path,
                stagedName: stagedName,
                expectedIdentity: target.identity,
                allocatedBytes: target.allocatedBytes,
                requiresAdministratorPrivileges:
                    cleanup.requiresAdministratorPrivileges,
                state: .staged
            )
            guard
                let stagedURL = try? journal.stagedURL(
                    for: entry,
                    operationURL: operationURL
                )
            else {
                await restoreStagedEntries(
                    manifest: &manifest,
                    operationURL: operationURL,
                    prompt: restorePrompt(for: cleanup.item)
                )
                return .failed(.couldNotStage)
            }

            manifest.entries.append(entry)
            do {
                try journal.save(manifest, at: operationURL)
            } catch {
                manifest.entries.removeLast()
                await restoreStagedEntries(
                    manifest: &manifest,
                    operationURL: operationURL,
                    prompt: restorePrompt(for: cleanup.item)
                )
                return .failed(.couldNotStage)
            }

            let moveResult = await moveItem(
                at: target.url,
                to: stagedURL,
                requiresAdministratorPrivileges:
                    cleanup.requiresAdministratorPrivileges,
                prompt: authorizationPrompt(for: cleanup.item)
            )
            guard moveResult == .succeeded else {
                manifest.entries.removeAll {
                    $0.stagedName == stagedName
                        && !fileManager.fileExists(atPath: stagedURL.path)
                }
                try? journal.save(manifest, at: operationURL)
                await restoreStagedEntries(
                    manifest: &manifest,
                    operationURL: operationURL,
                    prompt: restorePrompt(for: cleanup.item)
                )
                return .failed(
                    cleanupFailure(
                        for: moveResult,
                        usedAdministratorPrivileges:
                            cleanup.requiresAdministratorPrivileges,
                        fallback: .couldNotStage
                    )
                )
            }

            guard
                let stagedIdentity = try? FileIdentity(url: stagedURL),
                stagedIdentity == target.identity
            else {
                await restoreStagedEntries(
                    manifest: &manifest,
                    operationURL: operationURL,
                    prompt: restorePrompt(for: cleanup.item)
                )
                return .failed(.changedSinceScan)
            }
        }

        var deletedBytes: Int64 = 0
        for index in manifest.entries.indices {
            guard
                let stagedURL = try? journal.stagedURL(
                    for: manifest.entries[index],
                    operationURL: operationURL
                )
            else {
                await restoreStagedEntries(
                    manifest: &manifest,
                    operationURL: operationURL,
                    prompt: restorePrompt(for: cleanup.item)
                )
                return deletedBytes > 0
                    ? .partiallyDeleted(bytes: deletedBytes, reason: .couldNotDelete)
                    : .failed(.couldNotDelete)
            }
            let removeResult = await removeItem(
                at: stagedURL,
                requiresAdministratorPrivileges:
                    manifest.entries[index].requiresAdministratorPrivileges
                        ?? false,
                prompt: authorizationPrompt(for: cleanup.item)
            )
            if removeResult == .succeeded {
                deletedBytes += manifest.entries[index].allocatedBytes
                manifest.entries[index].state = .deleted
                do {
                    try journal.save(manifest, at: operationURL)
                } catch {
                    await restoreStagedEntries(
                        manifest: &manifest,
                        operationURL: operationURL,
                        prompt: restorePrompt(for: cleanup.item)
                    )
                    return .partiallyDeleted(
                        bytes: deletedBytes,
                        reason: .couldNotDelete
                    )
                }
            } else {
                await restoreStagedEntries(
                    manifest: &manifest,
                    operationURL: operationURL,
                    prompt: restorePrompt(for: cleanup.item)
                )
                if deletedBytes > 0 {
                    return .partiallyDeleted(
                        bytes: deletedBytes,
                        reason: cleanupFailure(
                            for: removeResult,
                            usedAdministratorPrivileges:
                                cleanup.requiresAdministratorPrivileges,
                            fallback: .couldNotDelete
                        )
                    )
                }
                return .failed(
                    cleanupFailure(
                        for: removeResult,
                        usedAdministratorPrivileges:
                            cleanup.requiresAdministratorPrivileges,
                        fallback: .couldNotDelete
                    )
                )
            }
        }

        journal.removeOperationIfEmpty(operationURL)
        return .deleted(bytes: cleanup.item.allocatedBytes)
    }

    private func restoreStagedEntries(
        manifest: inout CleanupManifest,
        operationURL: URL,
        prompt: String
    ) async {
        for index in manifest.entries.indices.reversed() {
            guard manifest.entries[index].state == .staged else { continue }

            guard
                let stagedURL = try? journal.stagedURL(
                    for: manifest.entries[index],
                    operationURL: operationURL
                ),
                let stagedIdentity = try? FileIdentity(url: stagedURL),
                stagedIdentity == manifest.entries[index].expectedIdentity
            else {
                continue
            }
            let originalURL = URL(
                fileURLWithPath: manifest.entries[index].originalPath
            )
            guard
                fileManager.fileExists(atPath: stagedURL.path),
                !fileManager.fileExists(atPath: originalURL.path)
            else {
                continue
            }

            let requiresAdministratorPrivileges =
                manifest.entries[index].requiresAdministratorPrivileges
                    ?? false
            if !requiresAdministratorPrivileges {
                try? fileManager.createDirectory(
                    at: originalURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
            }

            let result = await moveItem(
                at: stagedURL,
                to: originalURL,
                requiresAdministratorPrivileges:
                    requiresAdministratorPrivileges,
                prompt: prompt
            )
            if result == .succeeded {
                manifest.entries[index].state = .deleted
            } else {
                continue
            }
        }

        try? journal.save(manifest, at: operationURL)
        journal.removeOperationIfEmpty(operationURL)
    }

    private func moveItem(
        at sourceURL: URL,
        to destinationURL: URL,
        requiresAdministratorPrivileges: Bool,
        prompt: String
    ) async -> AdministratorFileOperationResult {
        if requiresAdministratorPrivileges {
            return await administratorFileOperator.moveItem(
                at: sourceURL,
                to: destinationURL,
                prompt: prompt
            )
        }

        do {
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            return .succeeded
        } catch {
            return .failed
        }
    }

    private func removeItem(
        at url: URL,
        requiresAdministratorPrivileges: Bool,
        prompt: String
    ) async -> AdministratorFileOperationResult {
        if requiresAdministratorPrivileges {
            return await administratorFileOperator.removeItem(
                at: url,
                prompt: prompt
            )
        }

        do {
            try fileManager.removeItem(at: url)
            return .succeeded
        } catch {
            return .failed
        }
    }

    private func cleanupFailure(
        for result: AdministratorFileOperationResult,
        usedAdministratorPrivileges: Bool,
        fallback: CleanupFailureReason
    ) -> CleanupFailureReason {
        guard usedAdministratorPrivileges else { return fallback }

        return switch result {
        case .succeeded:
            fallback
        case .canceled:
            .administratorAuthorizationCanceled
        case .failed:
            .administratorAuthorizationFailed
        }
    }

    private func authorizationPrompt(for item: StorageItem) -> String {
        AppCopy.Core.removeAuthorizationPrompt(item.title)
    }

    private func restorePrompt(for item: StorageItem) -> String {
        AppCopy.Core.rollbackAuthorizationPrompt(item.title)
    }

    private func countNonManifestItems(in operationURL: URL) -> Int {
        guard journal.isValidOperationURL(operationURL) else { return 1 }
        guard
            let urls = try? fileManager.contentsOfDirectory(
                at: operationURL,
                includingPropertiesForKeys: nil
            )
        else {
            return 0
        }
        return urls.count { $0.lastPathComponent != "manifest.json" }
    }
}
