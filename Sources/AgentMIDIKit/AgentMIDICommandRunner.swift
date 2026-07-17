import Foundation

public struct AgentMIDICommandResult: Sendable {
    public var exitCode: Int32
    public var standardOutput: String
    public var standardError: String

    public init(exitCode: Int32, standardOutput: String, standardError: String) {
        self.exitCode = exitCode
        self.standardOutput = standardOutput
        self.standardError = standardError
    }

    public var succeeded: Bool {
        exitCode == 0
    }
}

public enum AgentMIDICommandRunnerError: Error, LocalizedError, Sendable {
    case emptyCommand
    case invalidURL(String)

    public var errorDescription: String? {
        switch self {
        case .emptyCommand:
            return "The Agent MIDI command is empty."
        case .invalidURL(let rawValue):
            return "Agent MIDI could not open the URL: \(rawValue)."
        }
    }
}

public actor AgentMIDICommandRunner {
    public init() {}

    public func run(
        _ command: AgentMIDICommand,
        workspaceURL: URL?
    ) async throws -> AgentMIDICommandResult {
        let processConfiguration = try configuration(for: command, workspaceURL: workspaceURL)
        let process = Process()
        let standardOutputPipe = Pipe()
        let standardErrorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [processConfiguration.executableName] + processConfiguration.arguments
        process.currentDirectoryURL = workspaceURL
        process.standardOutput = standardOutputPipe
        process.standardError = standardErrorPipe
        process.environment = processEnvironment()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                process.terminationHandler = { completedProcess in
                    let standardOutputData = standardOutputPipe.fileHandleForReading.readDataToEndOfFile()
                    let standardErrorData = standardErrorPipe.fileHandleForReading.readDataToEndOfFile()
                    continuation.resume(
                        returning: AgentMIDICommandResult(
                            exitCode: completedProcess.terminationStatus,
                            standardOutput: String(decoding: standardOutputData, as: UTF8.self),
                            standardError: String(decoding: standardErrorData, as: UTF8.self)
                        )
                    )
                }

                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: {
            if process.isRunning {
                process.terminate()
            }
        }
    }

    private func configuration(
        for command: AgentMIDICommand,
        workspaceURL: URL?
    ) throws -> (executableName: String, arguments: [String]) {
        let workspacePath = workspaceURL?.path ?? FileManager.default.currentDirectoryPath
        let expandedPrompt = expand(command.prompt, workspacePath: workspacePath)
        let expandedCommand = expand(command.command, workspacePath: workspacePath)
        let expandedArguments = command.arguments.map { argument in
            expand(argument, workspacePath: workspacePath)
        }

        switch command.kind {
        case .none, .host:
            throw AgentMIDICommandRunnerError.emptyCommand
        case .codex:
            let prompt = resolvedPrompt(expandedPrompt)
            return ("codex", ["exec", prompt] + expandedArguments)
        case .claudeCode:
            let prompt = resolvedPrompt(expandedPrompt)
            return ("claude", ["-p", prompt] + expandedArguments)
        case .visualStudioCode:
            return ("code", resolvedWorkspaceArguments(expandedArguments, workspacePath: workspacePath))
        case .cursor:
            return ("cursor", resolvedWorkspaceArguments(expandedArguments, workspacePath: workspacePath))
        case .zed:
            return ("zed", resolvedWorkspaceArguments(expandedArguments, workspacePath: workspacePath))
        case .xcode:
            return ("xed", resolvedWorkspaceArguments(expandedArguments, workspacePath: workspacePath))
        case .shell:
            guard !expandedCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw AgentMIDICommandRunnerError.emptyCommand
            }
            return ("/bin/zsh", ["-lc", expandedCommand])
        case .openURL:
            let rawValue: String
            if expandedCommand.isEmpty {
                rawValue = expandedPrompt
            } else {
                rawValue = expandedCommand
            }
            guard URL(string: rawValue) != nil else {
                throw AgentMIDICommandRunnerError.invalidURL(rawValue)
            }
            return ("open", [rawValue])
        }
    }

    private func resolvedPrompt(_ prompt: String) -> String {
        if prompt.isEmpty {
            return "Inspect this workspace and continue the highest-priority task."
        }
        return prompt
    }

    private func resolvedWorkspaceArguments(_ arguments: [String], workspacePath: String) -> [String] {
        if arguments.isEmpty {
            return [workspacePath]
        }
        return arguments
    }

    private func processEnvironment() -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        let homeDirectoryPath = FileManager.default.homeDirectoryForCurrentUser.path
        let additionalSearchPaths = [
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
            "\(homeDirectoryPath)/.local/bin",
            "\(homeDirectoryPath)/.npm-global/bin"
        ]
        let existingPath = environment["PATH"] ?? ""
        environment["PATH"] = (additionalSearchPaths + [existingPath])
            .filter { path in
                !path.isEmpty
            }
            .joined(separator: ":")
        return environment
    }

    private func expand(_ rawValue: String, workspacePath: String) -> String {
        rawValue
            .replacingOccurrences(of: "${workspace}", with: workspacePath)
            .replacingOccurrences(of: "$WORKSPACE", with: workspacePath)
    }
}
