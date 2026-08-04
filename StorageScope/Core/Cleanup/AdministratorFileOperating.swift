import Foundation

#if SWIFT_PACKAGE
import AuthorizationShim
#endif

enum AdministratorFileOperationResult: Error, Equatable, Sendable {
    case succeeded
    case canceled
    case failed
}

protocol AdministratorFileOperating: Sendable {
    func moveItem(
        at sourceURL: URL,
        to destinationURL: URL,
        prompt: String
    ) async -> AdministratorFileOperationResult

    func removeItem(
        at url: URL,
        prompt: String
    ) async -> AdministratorFileOperationResult

    func invalidateAuthorization() async
}

extension AdministratorFileOperating {
    func invalidateAuthorization() async {}
}

actor AuthorizationServicesFileOperator: AdministratorFileOperating {
    private let recoveryRootPath: String
    private var session: AuthorizationSession?

    init(recoveryRootURL: URL) {
        recoveryRootPath = recoveryRootURL.standardizedFileURL.path
    }

    func moveItem(
        at sourceURL: URL,
        to destinationURL: URL,
        prompt: String
    ) async -> AdministratorFileOperationResult {
        guard let session = authorizationSession() else { return .failed }

        let result = sourceURL.path.withCString { sourcePath in
            destinationURL.path.withCString { destinationPath in
                prompt.withCString { promptText in
                    NSDAuthorizationMoveItem(
                        session.pointer,
                        sourcePath,
                        destinationPath,
                        promptText
                    )
                }
            }
        }
        let operationResult = Self.result(for: result)
        guard operationResult == .succeeded else { return operationResult }
        guard
            !FileManager.default.fileExists(atPath: sourceURL.path),
            FileManager.default.fileExists(atPath: destinationURL.path)
        else {
            return .failed
        }
        return .succeeded
    }

    func removeItem(
        at url: URL,
        prompt: String
    ) async -> AdministratorFileOperationResult {
        guard let session = authorizationSession() else { return .failed }

        let result = url.path.withCString { path in
            prompt.withCString { promptText in
                NSDAuthorizationRemoveItem(
                    session.pointer,
                    path,
                    promptText
                )
            }
        }
        let operationResult = Self.result(for: result)
        guard operationResult == .succeeded else { return operationResult }
        return FileManager.default.fileExists(atPath: url.path)
            ? .failed
            : .succeeded
    }

    func invalidateAuthorization() async {
        session = nil
    }

    private func authorizationSession() -> AuthorizationSession? {
        if let session { return session }
        let pointer = recoveryRootPath.withCString {
            NSDAuthorizationSessionCreate($0)
        }
        guard let pointer else { return nil }
        let createdSession = AuthorizationSession(pointer: pointer)
        session = createdSession
        return createdSession
    }

    private static func result(
        for rawValue: Int32
    ) -> AdministratorFileOperationResult {
        switch rawValue {
        case Int32(NSDAuthorizationResultSucceeded):
            .succeeded
        case Int32(NSDAuthorizationResultCanceled):
            .canceled
        default:
            .failed
        }
    }
}

private final class AuthorizationSession {
    let pointer: UnsafeMutableRawPointer

    // The pointer is created, used, and released only by the owning operator actor.
    init(pointer: UnsafeMutableRawPointer) {
        self.pointer = pointer
    }

    deinit {
        NSDAuthorizationSessionDestroy(pointer)
    }
}
