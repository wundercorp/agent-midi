import AppKit
import Foundation

public final class AgentMIDIDocumentStore: @unchecked Sendable {
    public let rootDirectoryURL: URL
    public let themesDirectoryURL: URL
    public let layoutsDirectoryURL: URL

    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let applicationSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
        rootDirectoryURL = applicationSupportURL.appendingPathComponent("AgentMIDI", isDirectory: true)
        themesDirectoryURL = rootDirectoryURL.appendingPathComponent("Themes", isDirectory: true)
        layoutsDirectoryURL = rootDirectoryURL.appendingPathComponent("Layouts", isDirectory: true)
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        decoder = JSONDecoder()
        createDirectories()
    }

    public func loadThemes() -> [AgentMIDITheme] {
        loadDocuments(from: themesDirectoryURL, as: AgentMIDITheme.self)
    }

    public func loadLayouts() -> [AgentMIDILayout] {
        loadDocuments(from: layoutsDirectoryURL, as: AgentMIDILayout.self)
    }

    public func save(theme: AgentMIDITheme) throws {
        let fileURL = themesDirectoryURL.appendingPathComponent(safeFileName(theme.id)).appendingPathExtension("json")
        try save(theme, to: fileURL)
    }

    public func save(layout: AgentMIDILayout) throws {
        let fileURL = layoutsDirectoryURL.appendingPathComponent(safeFileName(layout.id)).appendingPathExtension("json")
        try save(layout, to: fileURL)
    }

    public func revealThemesDirectory() {
        createDirectories()
        NSWorkspace.shared.activateFileViewerSelecting([themesDirectoryURL])
    }

    public func revealLayoutsDirectory() {
        createDirectories()
        NSWorkspace.shared.activateFileViewerSelecting([layoutsDirectoryURL])
    }

    private func createDirectories() {
        try? fileManager.createDirectory(at: themesDirectoryURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: layoutsDirectoryURL, withIntermediateDirectories: true)
    }

    private func loadDocuments<Document: Decodable>(from directoryURL: URL, as documentType: Document.Type) -> [Document] {
        createDirectories()
        guard let fileURLs = try? fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return fileURLs
            .filter { fileURL in
                fileURL.pathExtension.lowercased() == "json"
            }
            .sorted { leftURL, rightURL in
                leftURL.lastPathComponent.localizedCaseInsensitiveCompare(rightURL.lastPathComponent) == .orderedAscending
            }
            .compactMap { fileURL in
                guard let data = try? Data(contentsOf: fileURL) else {
                    return nil
                }
                return try? decoder.decode(Document.self, from: data)
            }
    }

    private func save<Document: Encodable>(_ document: Document, to fileURL: URL) throws {
        createDirectories()
        let data = try encoder.encode(document)
        try data.write(to: fileURL, options: .atomic)
    }

    private func safeFileName(_ rawValue: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let transformedScalars = rawValue.unicodeScalars.map { scalar -> Character in
            if allowedCharacters.contains(scalar) {
                return Character(String(scalar))
            }
            return "-"
        }
        let candidate = String(transformedScalars)
            .replacingOccurrences(of: "--", with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        if candidate.isEmpty {
            return UUID().uuidString.lowercased()
        }
        return candidate.lowercased()
    }
}
