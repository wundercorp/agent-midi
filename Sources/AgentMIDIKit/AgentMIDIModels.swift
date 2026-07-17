import Foundation

public enum AgentMIDIControlKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case pad
    case widePad
    case knob
    case indicator

    public var id: String {
        rawValue
    }

    public var displayName: String {
        switch self {
        case .pad:
            return "Pad"
        case .widePad:
            return "Wide Pad"
        case .knob:
            return "Knob"
        case .indicator:
            return "Indicator"
        }
    }
}

public enum AgentMIDIMessageKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case note
    case controlChange
    case programChange

    public var id: String {
        rawValue
    }

    public var displayName: String {
        switch self {
        case .note:
            return "Note"
        case .controlChange:
            return "Control Change"
        case .programChange:
            return "Program Change"
        }
    }
}

public struct AgentMIDIMapping: Codable, Hashable, Sendable {
    public var kind: AgentMIDIMessageKind
    public var channel: Int
    public var number: Int
    public var value: Int

    public init(
        kind: AgentMIDIMessageKind = .note,
        channel: Int = 1,
        number: Int = 60,
        value: Int = 100
    ) {
        self.kind = kind
        self.channel = min(max(channel, 1), 16)
        self.number = min(max(number, 0), 127)
        self.value = min(max(value, 0), 127)
    }
}

public enum AgentMIDICommandKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case none
    case host
    case codex
    case claudeCode
    case visualStudioCode
    case cursor
    case zed
    case xcode
    case shell
    case openURL

    public var id: String {
        rawValue
    }

    public var displayName: String {
        switch self {
        case .none:
            return "None"
        case .host:
            return "Host IDE"
        case .codex:
            return "Codex CLI"
        case .claudeCode:
            return "Claude Code"
        case .visualStudioCode:
            return "Visual Studio Code"
        case .cursor:
            return "Cursor"
        case .zed:
            return "Zed"
        case .xcode:
            return "Xcode"
        case .shell:
            return "Shell"
        case .openURL:
            return "Open URL"
        }
    }
}

public struct AgentMIDICommand: Codable, Hashable, Sendable {
    public var kind: AgentMIDICommandKind
    public var command: String
    public var arguments: [String]
    public var prompt: String

    public init(
        kind: AgentMIDICommandKind = .none,
        command: String = "",
        arguments: [String] = [],
        prompt: String = ""
    ) {
        self.kind = kind
        self.command = command
        self.arguments = arguments
        self.prompt = prompt
    }
}

public struct AgentMIDIControl: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var kind: AgentMIDIControlKind
    public var row: Int
    public var column: Int
    public var columnSpan: Int
    public var title: String
    public var subtitle: String
    public var symbolName: String
    public var accentRole: String
    public var midi: AgentMIDIMapping?
    public var command: AgentMIDICommand

    public init(
        id: UUID = UUID(),
        kind: AgentMIDIControlKind,
        row: Int,
        column: Int,
        columnSpan: Int = 1,
        title: String,
        subtitle: String = "",
        symbolName: String = "circle.fill",
        accentRole: String = "primary",
        midi: AgentMIDIMapping? = nil,
        command: AgentMIDICommand = AgentMIDICommand()
    ) {
        self.id = id
        self.kind = kind
        self.row = max(row, 0)
        self.column = max(column, 0)
        self.columnSpan = max(columnSpan, 1)
        self.title = title
        self.subtitle = subtitle
        self.symbolName = symbolName
        self.accentRole = accentRole
        self.midi = midi
        self.command = command
    }
}

public struct AgentMIDILayout: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var columns: Int
    public var rows: Int
    public var controls: [AgentMIDIControl]

    public init(
        id: String,
        name: String,
        columns: Int = 4,
        rows: Int = 4,
        controls: [AgentMIDIControl]
    ) {
        self.id = id
        self.name = name
        self.columns = max(columns, 1)
        self.rows = max(rows, 1)
        self.controls = controls
    }
}

public struct AgentMIDITheme: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var backgroundHex: String
    public var panelHex: String
    public var controlHex: String
    public var controlPressedHex: String
    public var primaryAccentHex: String
    public var secondaryAccentHex: String
    public var textHex: String
    public var secondaryTextHex: String
    public var borderHex: String
    public var cornerRadius: Double
    public var controlCornerRadius: Double
    public var controlSpacing: Double

    public init(
        id: String,
        name: String,
        backgroundHex: String,
        panelHex: String,
        controlHex: String,
        controlPressedHex: String,
        primaryAccentHex: String,
        secondaryAccentHex: String,
        textHex: String,
        secondaryTextHex: String,
        borderHex: String,
        cornerRadius: Double = 30,
        controlCornerRadius: Double = 16,
        controlSpacing: Double = 10
    ) {
        self.id = id
        self.name = name
        self.backgroundHex = backgroundHex
        self.panelHex = panelHex
        self.controlHex = controlHex
        self.controlPressedHex = controlPressedHex
        self.primaryAccentHex = primaryAccentHex
        self.secondaryAccentHex = secondaryAccentHex
        self.textHex = textHex
        self.secondaryTextHex = secondaryTextHex
        self.borderHex = borderHex
        self.cornerRadius = cornerRadius
        self.controlCornerRadius = controlCornerRadius
        self.controlSpacing = controlSpacing
    }
}

public enum AgentMIDIEventPhase: String, Codable, Sendable {
    case began
    case changed
    case ended
    case triggered
}

public struct AgentMIDIEvent: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var timestamp: Date
    public var layoutID: String
    public var controlID: UUID
    public var controlTitle: String
    public var phase: AgentMIDIEventPhase
    public var value: Int
    public var midi: AgentMIDIMapping?
    public var command: AgentMIDICommand

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        layoutID: String,
        controlID: UUID,
        controlTitle: String,
        phase: AgentMIDIEventPhase,
        value: Int,
        midi: AgentMIDIMapping?,
        command: AgentMIDICommand
    ) {
        self.id = id
        self.timestamp = timestamp
        self.layoutID = layoutID
        self.controlID = controlID
        self.controlTitle = controlTitle
        self.phase = phase
        self.value = min(max(value, 0), 127)
        self.midi = midi
        self.command = command
    }
}

public enum AgentMIDIBuiltIns {
    public static let defaultTheme = AgentMIDITheme(
        id: "work-louder-white",
        name: "Work Louder White",
        backgroundHex: "E8EBF1",
        panelHex: "F5F7FA",
        controlHex: "F9FAFC",
        controlPressedHex: "DCE4F7",
        primaryAccentHex: "7F91D2",
        secondaryAccentHex: "111319",
        textHex: "16181E",
        secondaryTextHex: "6D7380",
        borderHex: "C8CED8",
        cornerRadius: 30,
        controlCornerRadius: 16,
        controlSpacing: 10
    )

    public static let darkTheme = AgentMIDITheme(
        id: "agent-dark",
        name: "Agent Dark",
        backgroundHex: "101116",
        panelHex: "191B22",
        controlHex: "232631",
        controlPressedHex: "353B50",
        primaryAccentHex: "8FA2FF",
        secondaryAccentHex: "F2F4FA",
        textHex: "F2F4FA",
        secondaryTextHex: "9EA5B4",
        borderHex: "343846",
        cornerRadius: 28,
        controlCornerRadius: 15,
        controlSpacing: 10
    )

    public static let neonTheme = AgentMIDITheme(
        id: "neon-terminal",
        name: "Neon Terminal",
        backgroundHex: "08110D",
        panelHex: "0D1A14",
        controlHex: "13261D",
        controlPressedHex: "1F4A35",
        primaryAccentHex: "58F09A",
        secondaryAccentHex: "D8FFE8",
        textHex: "E8FFF1",
        secondaryTextHex: "79AA8E",
        borderHex: "28543C",
        cornerRadius: 24,
        controlCornerRadius: 12,
        controlSpacing: 9
    )

    public static let defaultLayout = AgentMIDILayout(
        id: "agent-midi-default",
        name: "Agent MIDI",
        columns: 4,
        rows: 4,
        controls: [
            AgentMIDIControl(
                id: UUID(uuidString: "A0000000-0000-0000-0000-000000000001")!,
                kind: .knob,
                row: 0,
                column: 0,
                title: "Model",
                subtitle: "CC 20",
                symbolName: "dial.medium",
                midi: AgentMIDIMapping(kind: .controlChange, channel: 1, number: 20, value: 64)
            ),
            AgentMIDIControl(
                id: UUID(uuidString: "A0000000-0000-0000-0000-000000000002")!,
                kind: .pad,
                row: 0,
                column: 1,
                title: "Ask",
                symbolName: "questionmark.bubble",
                midi: AgentMIDIMapping(kind: .note, channel: 1, number: 60, value: 108),
                command: AgentMIDICommand(kind: .host, command: "builderstudio.mode.ask")
            ),
            AgentMIDIControl(
                id: UUID(uuidString: "A0000000-0000-0000-0000-000000000003")!,
                kind: .pad,
                row: 0,
                column: 2,
                title: "Plan",
                symbolName: "list.bullet.clipboard",
                midi: AgentMIDIMapping(kind: .note, channel: 1, number: 61, value: 108),
                command: AgentMIDICommand(kind: .host, command: "builderstudio.mode.plan")
            ),
            AgentMIDIControl(
                id: UUID(uuidString: "A0000000-0000-0000-0000-000000000004")!,
                kind: .knob,
                row: 0,
                column: 3,
                title: "Gain",
                subtitle: "CC 21",
                symbolName: "dial.high",
                midi: AgentMIDIMapping(kind: .controlChange, channel: 1, number: 21, value: 96)
            ),
            AgentMIDIControl(
                id: UUID(uuidString: "A0000000-0000-0000-0000-000000000005")!,
                kind: .pad,
                row: 1,
                column: 0,
                title: "Codex",
                subtitle: "Run task",
                symbolName: "terminal",
                accentRole: "primary",
                midi: AgentMIDIMapping(kind: .note, channel: 1, number: 62, value: 112),
                command: AgentMIDICommand(kind: .codex, prompt: "Inspect the current workspace and continue the highest-priority implementation task.")
            ),
            AgentMIDIControl(
                id: UUID(uuidString: "A0000000-0000-0000-0000-000000000006")!,
                kind: .pad,
                row: 1,
                column: 1,
                title: "Claude",
                subtitle: "Review",
                symbolName: "sparkles",
                accentRole: "primary",
                midi: AgentMIDIMapping(kind: .note, channel: 1, number: 63, value: 112),
                command: AgentMIDICommand(kind: .claudeCode, prompt: "Review the current workspace, identify the most important problem, and propose the next concrete change.")
            ),
            AgentMIDIControl(
                id: UUID(uuidString: "A0000000-0000-0000-0000-000000000007")!,
                kind: .pad,
                row: 1,
                column: 2,
                title: "Build",
                subtitle: "Verify",
                symbolName: "hammer",
                midi: AgentMIDIMapping(kind: .note, channel: 1, number: 64, value: 112),
                command: AgentMIDICommand(kind: .host, command: "builderstudio.prompt", prompt: "Build the current workspace, fix any errors, and verify the result.")
            ),
            AgentMIDIControl(
                id: UUID(uuidString: "A0000000-0000-0000-0000-000000000008")!,
                kind: .pad,
                row: 1,
                column: 3,
                title: "Test",
                subtitle: "Run suite",
                symbolName: "checkmark.seal",
                midi: AgentMIDIMapping(kind: .note, channel: 1, number: 65, value: 112),
                command: AgentMIDICommand(kind: .host, command: "builderstudio.prompt", prompt: "Run the relevant tests, repair failures, and summarize what changed.")
            ),
            AgentMIDIControl(
                id: UUID(uuidString: "A0000000-0000-0000-0000-000000000009")!,
                kind: .pad,
                row: 2,
                column: 0,
                title: "Run",
                symbolName: "bolt.fill",
                accentRole: "primary",
                midi: AgentMIDIMapping(kind: .note, channel: 1, number: 66, value: 118),
                command: AgentMIDICommand(kind: .host, command: "builderstudio.submit")
            ),
            AgentMIDIControl(
                id: UUID(uuidString: "A0000000-0000-0000-0000-00000000000A")!,
                kind: .pad,
                row: 2,
                column: 1,
                title: "Approve",
                symbolName: "checkmark.circle",
                midi: AgentMIDIMapping(kind: .note, channel: 1, number: 67, value: 118),
                command: AgentMIDICommand(kind: .host, command: "builderstudio.approve")
            ),
            AgentMIDIControl(
                id: UUID(uuidString: "A0000000-0000-0000-0000-00000000000B")!,
                kind: .pad,
                row: 2,
                column: 2,
                title: "Cancel",
                symbolName: "xmark.circle",
                midi: AgentMIDIMapping(kind: .note, channel: 1, number: 68, value: 118),
                command: AgentMIDICommand(kind: .host, command: "builderstudio.cancel")
            ),
            AgentMIDIControl(
                id: UUID(uuidString: "A0000000-0000-0000-0000-00000000000C")!,
                kind: .pad,
                row: 2,
                column: 3,
                title: "Branch",
                symbolName: "point.3.connected.trianglepath.dotted",
                midi: AgentMIDIMapping(kind: .note, channel: 1, number: 69, value: 118),
                command: AgentMIDICommand(kind: .host, command: "builderstudio.mode.swarm")
            ),
            AgentMIDIControl(
                id: UUID(uuidString: "A0000000-0000-0000-0000-00000000000D")!,
                kind: .indicator,
                row: 3,
                column: 0,
                title: "Live",
                subtitle: "MIDI 1",
                symbolName: "circle.fill",
                accentRole: "primary"
            ),
            AgentMIDIControl(
                id: UUID(uuidString: "A0000000-0000-0000-0000-00000000000E")!,
                kind: .widePad,
                row: 3,
                column: 1,
                columnSpan: 2,
                title: "Prompt",
                subtitle: "Send current draft",
                symbolName: "mic.fill",
                midi: AgentMIDIMapping(kind: .note, channel: 1, number: 70, value: 120),
                command: AgentMIDICommand(kind: .host, command: "builderstudio.submit")
            ),
            AgentMIDIControl(
                id: UUID(uuidString: "A0000000-0000-0000-0000-00000000000F")!,
                kind: .pad,
                row: 3,
                column: 3,
                title: "Agent",
                symbolName: "brain.head.profile",
                midi: AgentMIDIMapping(kind: .note, channel: 1, number: 71, value: 120),
                command: AgentMIDICommand(kind: .host, command: "builderstudio.mode.gain")
            )
        ]
    )

    public static let codingLayout = AgentMIDILayout(
        id: "coding-agents",
        name: "Coding Agents",
        columns: 4,
        rows: 4,
        controls: defaultLayout.controls.map { control in
            var updatedControl = control
            if updatedControl.title == "Build" {
                updatedControl.command = AgentMIDICommand(kind: .codex, prompt: "Build the project, fix errors, and verify the finished result.")
            }
            if updatedControl.title == "Test" {
                updatedControl.command = AgentMIDICommand(kind: .claudeCode, prompt: "Run the test suite, repair failures, and report the verification result.")
            }
            return updatedControl
        }
    )

    public static let themes: [AgentMIDITheme] = [
        defaultTheme,
        darkTheme,
        neonTheme
    ]

    public static let layouts: [AgentMIDILayout] = [
        defaultLayout,
        codingLayout
    ]
}
