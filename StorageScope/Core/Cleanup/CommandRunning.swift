import Foundation

struct CommandResult: Equatable, Sendable {
    let terminationStatus: Int32
}

protocol CommandRunning: Sendable {
    func run(executable: URL, arguments: [String]) async -> CommandResult
}

actor ProcessCommandRunner: CommandRunning {
    func run(executable: URL, arguments: [String]) async -> CommandResult {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            return CommandResult(terminationStatus: process.terminationStatus)
        } catch {
            return CommandResult(terminationStatus: -1)
        }
    }
}

