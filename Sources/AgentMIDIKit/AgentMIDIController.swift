import Combine
import Foundation

@MainActor
public final class AgentMIDIController: ObservableObject {
    public typealias HostCommandHandler = @MainActor (AgentMIDICommand, AgentMIDIEvent) -> Void

    @Published public private(set) var layouts: [AgentMIDILayout]
    @Published public private(set) var themes: [AgentMIDITheme]
    @Published public var activeLayoutID: String
    @Published public var activeThemeID: String
    @Published public var knobValues: [UUID: Int]
    @Published public var isEditing: Bool
    @Published public var selectedControlID: UUID?
    @Published public private(set) var transportStatus: String
    @Published public private(set) var commandStatus: String
    @Published public private(set) var lastEvent: AgentMIDIEvent?

    public var workspaceURL: URL?
    public var hostCommandHandler: HostCommandHandler?

    public var activeLayout: AgentMIDILayout {
        layouts.first { layout in
            layout.id == activeLayoutID
        } ?? AgentMIDIBuiltIns.defaultLayout
    }

    public var activeTheme: AgentMIDITheme {
        themes.first { theme in
            theme.id == activeThemeID
        } ?? AgentMIDIBuiltIns.defaultTheme
    }

    public var selectedControl: AgentMIDIControl? {
        guard let selectedControlID else {
            return nil
        }
        return activeLayout.controls.first { control in
            control.id == selectedControlID
        }
    }

    private let documentStore: AgentMIDIDocumentStore
    private let virtualSource: AgentMIDIVirtualSource
    private let commandRunner: AgentMIDICommandRunner
    private let eventEncoder: JSONEncoder

    public init(
        workspaceURL: URL? = nil,
        documentStore: AgentMIDIDocumentStore = AgentMIDIDocumentStore(),
        virtualSource: AgentMIDIVirtualSource = AgentMIDIVirtualSource(),
        commandRunner: AgentMIDICommandRunner = AgentMIDICommandRunner()
    ) {
        self.workspaceURL = workspaceURL
        self.documentStore = documentStore
        self.virtualSource = virtualSource
        self.commandRunner = commandRunner
        layouts = AgentMIDIBuiltIns.layouts
        themes = AgentMIDIBuiltIns.themes
        activeLayoutID = AgentMIDIBuiltIns.defaultLayout.id
        activeThemeID = AgentMIDIBuiltIns.defaultTheme.id
        knobValues = [:]
        isEditing = false
        selectedControlID = nil
        transportStatus = "Starting MIDI"
        commandStatus = "Ready"
        lastEvent = nil
        eventEncoder = JSONEncoder()
        reloadDocuments()
        initializeKnobValues()
        startTransport()
    }

    public func startTransport() {
        do {
            try virtualSource.start()
            transportStatus = "Agent MIDI online"
        } catch {
            transportStatus = error.localizedDescription
        }
    }

    public func stopTransport() {
        virtualSource.stop()
        transportStatus = "Agent MIDI offline"
    }

    public func reloadDocuments() {
        let customThemes = documentStore.loadThemes()
        let customLayouts = documentStore.loadLayouts()
        themes = mergedDocuments(builtIns: AgentMIDIBuiltIns.themes, customDocuments: customThemes)
        layouts = mergedDocuments(builtIns: AgentMIDIBuiltIns.layouts, customDocuments: customLayouts)

        if !themes.contains(where: { theme in theme.id == activeThemeID }) {
            activeThemeID = AgentMIDIBuiltIns.defaultTheme.id
        }
        if !layouts.contains(where: { layout in layout.id == activeLayoutID }) {
            activeLayoutID = AgentMIDIBuiltIns.defaultLayout.id
        }
        initializeKnobValues()
    }

    public func selectLayout(_ layoutID: String) {
        guard layouts.contains(where: { layout in layout.id == layoutID }) else {
            return
        }
        activeLayoutID = layoutID
        selectedControlID = nil
        initializeKnobValues()
    }

    public func selectTheme(_ themeID: String) {
        guard themes.contains(where: { theme in theme.id == themeID }) else {
            return
        }
        activeThemeID = themeID
    }

    public func selectControl(_ controlID: UUID) {
        selectedControlID = controlID
    }

    public func trigger(_ control: AgentMIDIControl) {
        if isEditing {
            selectControl(control.id)
            return
        }
        guard control.kind != .indicator else {
            return
        }

        let eventValue = control.midi?.value ?? knobValues[control.id] ?? 127
        let event = createEvent(control: control, phase: .triggered, value: eventValue)
        publish(event)

        if let mapping = control.midi {
            do {
                try sendTrigger(mapping)
                transportStatus = "Sent \(control.title)"
            } catch {
                transportStatus = error.localizedDescription
            }
        }

        dispatch(command: control.command, event: event)
    }

    public func updateKnob(_ control: AgentMIDIControl, value: Int, phase: AgentMIDIEventPhase) {
        let normalizedValue = min(max(value, 0), 127)
        knobValues[control.id] = normalizedValue
        let event = createEvent(control: control, phase: phase, value: normalizedValue)
        publish(event)

        if var mapping = control.midi {
            mapping.value = normalizedValue
            do {
                try sendContinuous(mapping)
                transportStatus = "\(control.title) \(normalizedValue)"
            } catch {
                transportStatus = error.localizedDescription
            }
        }

        if phase == .ended {
            dispatch(command: control.command, event: event)
        }
    }

    public func updateSelectedControl(_ transform: (inout AgentMIDIControl) -> Void) {
        guard let selectedControlID else {
            return
        }
        guard let layoutIndex = layouts.firstIndex(where: { layout in layout.id == activeLayoutID }) else {
            return
        }
        guard let controlIndex = layouts[layoutIndex].controls.firstIndex(where: { control in control.id == selectedControlID }) else {
            return
        }

        transform(&layouts[layoutIndex].controls[controlIndex])
        objectWillChange.send()
        saveActiveLayout()
    }

    public func duplicateActiveLayout() {
        let sourceLayout = activeLayout
        let identifier = "\(sourceLayout.id)-\(UUID().uuidString.prefix(8).lowercased())"
        let duplicateLayout = AgentMIDILayout(
            id: identifier,
            name: "\(sourceLayout.name) Copy",
            columns: sourceLayout.columns,
            rows: sourceLayout.rows,
            controls: sourceLayout.controls.map { sourceControl in
                var control = sourceControl
                control.id = UUID()
                return control
            }
        )
        layouts.append(duplicateLayout)
        activeLayoutID = duplicateLayout.id
        selectedControlID = duplicateLayout.controls.first?.id
        try? documentStore.save(layout: duplicateLayout)
        initializeKnobValues()
    }

    public func saveActiveLayout() {
        guard let layout = layouts.first(where: { candidateLayout in candidateLayout.id == activeLayoutID }) else {
            return
        }
        do {
            try documentStore.save(layout: layout)
            commandStatus = "Layout saved"
        } catch {
            commandStatus = error.localizedDescription
        }
    }

    public func revealThemesDirectory() {
        documentStore.revealThemesDirectory()
    }

    public func revealLayoutsDirectory() {
        documentStore.revealLayoutsDirectory()
    }

    private func createEvent(
        control: AgentMIDIControl,
        phase: AgentMIDIEventPhase,
        value: Int
    ) -> AgentMIDIEvent {
        AgentMIDIEvent(
            layoutID: activeLayout.id,
            controlID: control.id,
            controlTitle: control.title,
            phase: phase,
            value: value,
            midi: control.midi,
            command: control.command
        )
    }

    private func publish(_ event: AgentMIDIEvent) {
        lastEvent = event
        guard let data = try? eventEncoder.encode(event) else {
            return
        }
        let json = String(decoding: data, as: UTF8.self)
        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name("com.wundercorp.agentmidi.event"),
            object: "AgentMIDI",
            userInfo: ["event": json],
            deliverImmediately: true
        )
    }

    private func dispatch(command: AgentMIDICommand, event: AgentMIDIEvent) {
        switch command.kind {
        case .none:
            commandStatus = "Ready"
        case .host:
            if command.command.isEmpty {
                commandStatus = "Host action"
            } else {
                commandStatus = command.command
            }
            hostCommandHandler?(command, event)
        case .codex, .claudeCode, .visualStudioCode, .cursor, .zed, .xcode, .shell, .openURL:
            commandStatus = "Running \(command.kind.displayName)"
            Task {
                do {
                    let result = try await commandRunner.run(command, workspaceURL: workspaceURL)
                    if result.succeeded {
                        let output = result.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines)
                        if output.isEmpty {
                            commandStatus = "\(command.kind.displayName) completed"
                        } else {
                            commandStatus = output
                        }
                    } else {
                        let errorOutput = result.standardError.trimmingCharacters(in: .whitespacesAndNewlines)
                        if errorOutput.isEmpty {
                            commandStatus = "\(command.kind.displayName) exited \(result.exitCode)"
                        } else {
                            commandStatus = errorOutput
                        }
                    }
                } catch {
                    commandStatus = error.localizedDescription
                }
            }
        }
    }

    private func sendTrigger(_ mapping: AgentMIDIMapping) throws {
        switch mapping.kind {
        case .note:
            try virtualSource.sendNoteOn(
                channel: mapping.channel,
                note: mapping.number,
                velocity: mapping.value
            )
            Task {
                try? await Task.sleep(for: .milliseconds(75))
                try? virtualSource.sendNoteOff(
                    channel: mapping.channel,
                    note: mapping.number
                )
            }
        case .controlChange:
            try virtualSource.sendControlChange(
                channel: mapping.channel,
                controller: mapping.number,
                value: mapping.value
            )
        case .programChange:
            try virtualSource.sendProgramChange(
                channel: mapping.channel,
                program: mapping.number
            )
        }
    }

    private func sendContinuous(_ mapping: AgentMIDIMapping) throws {
        switch mapping.kind {
        case .note:
            try virtualSource.sendNoteOn(
                channel: mapping.channel,
                note: mapping.number,
                velocity: mapping.value
            )
        case .controlChange:
            try virtualSource.sendControlChange(
                channel: mapping.channel,
                controller: mapping.number,
                value: mapping.value
            )
        case .programChange:
            try virtualSource.sendProgramChange(
                channel: mapping.channel,
                program: mapping.number
            )
        }
    }

    private func initializeKnobValues() {
        var updatedValues = knobValues
        for control in activeLayout.controls where control.kind == .knob {
            if updatedValues[control.id] == nil {
                updatedValues[control.id] = control.midi?.value ?? 64
            }
        }
        knobValues = updatedValues
    }

    private func mergedDocuments<Document: Identifiable>(
        builtIns: [Document],
        customDocuments: [Document]
    ) -> [Document] where Document.ID == String {
        var documentsByIdentifier: [String: Document] = [:]
        for document in builtIns {
            documentsByIdentifier[document.id] = document
        }
        for document in customDocuments {
            documentsByIdentifier[document.id] = document
        }
        return documentsByIdentifier.values.sorted { leftDocument, rightDocument in
            leftDocument.id.localizedCaseInsensitiveCompare(rightDocument.id) == .orderedAscending
        }
    }
}
