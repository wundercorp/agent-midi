import SwiftUI

public struct AgentMIDIDeckView: View {
    @ObservedObject private var controller: AgentMIDIController

    public init(controller: AgentMIDIController) {
        self.controller = controller
    }

    public var body: some View {
        HStack(spacing: 18) {
            VStack(spacing: 12) {
                toolbar
                deck
                statusBar
            }
            .frame(minWidth: 540, idealWidth: 620, maxWidth: .infinity)

            if controller.isEditing {
                AgentMIDIControlEditorView(controller: controller)
                    .frame(width: 290)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(18)
        .animation(.easeInOut(duration: 0.2), value: controller.isEditing)
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Picker("Layout", selection: Binding(
                get: { controller.activeLayoutID },
                set: { controller.selectLayout($0) }
            )) {
                ForEach(controller.layouts) { layout in
                    Text(layout.name)
                        .tag(layout.id)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 180)

            Picker("Skin", selection: Binding(
                get: { controller.activeThemeID },
                set: { controller.selectTheme($0) }
            )) {
                ForEach(controller.themes) { theme in
                    Text(theme.name)
                        .tag(theme.id)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 170)

            Spacer()

            Menu {
                Button("Duplicate Layout") {
                    controller.duplicateActiveLayout()
                }
                Button("Reload Layouts and Skins") {
                    controller.reloadDocuments()
                }
                Divider()
                Button("Open Layout Folder") {
                    controller.revealLayoutsDirectory()
                }
                Button("Open Skin Folder") {
                    controller.revealThemesDirectory()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)

            Button {
                controller.isEditing.toggle()
                if controller.isEditing, controller.selectedControlID == nil {
                    controller.selectedControlID = controller.activeLayout.controls.first?.id
                }
            } label: {
                Label(editingButtonTitle, systemImage: editingButtonSymbolName)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var editingButtonTitle: String {
        if controller.isEditing {
            return "Done"
        }
        return "Program"
    }

    private var editingButtonSymbolName: String {
        if controller.isEditing {
            return "checkmark"
        }
        return "slider.horizontal.3"
    }

    private var deck: some View {
        let theme = controller.activeTheme
        return VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("AGENT MIDI")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.8)
                    Text(controller.activeLayout.name)
                        .font(.caption)
                        .opacity(0.64)
                }

                Spacer()

                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("NATIVE SWIFT")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .tracking(1.1)
                    Text("Build with agents")
                        .font(.caption2)
                        .opacity(0.64)
                }
            }
            .foregroundStyle(theme.textColor)
            .padding(.horizontal, 8)

            AgentMIDIGridView(controller: controller)

            Text("Let’s build")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(theme.secondaryTextColor)
        }
        .padding(18)
        .background(theme.panelColor, in: RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                .stroke(theme.borderColor, lineWidth: 1.2)
        }
        .shadow(color: .black.opacity(0.15), radius: 22, y: 10)
        .padding(10)
        .background(theme.backgroundColor, in: RoundedRectangle(cornerRadius: theme.cornerRadius + 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: theme.cornerRadius + 8, style: .continuous)
                .stroke(theme.borderColor.opacity(0.8), lineWidth: 1)
        }
        .aspectRatio(1.03, contentMode: .fit)
    }

    private var statusBar: some View {
        HStack(spacing: 10) {
            Label(controller.transportStatus, systemImage: "pianokeys")
                .lineLimit(1)
            Spacer()
            Text(controller.commandStatus)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if let lastEvent = controller.lastEvent {
                Text("\(lastEvent.controlTitle) · \(lastEvent.value)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .font(.caption)
    }
}

private struct AgentMIDIGridView: View {
    @ObservedObject var controller: AgentMIDIController

    var body: some View {
        let layout = controller.activeLayout
        let theme = controller.activeTheme
        Grid(horizontalSpacing: theme.controlSpacing, verticalSpacing: theme.controlSpacing) {
            ForEach(0..<layout.rows, id: \.self) { row in
                GridRow {
                    ForEach(gridCells(for: row, layout: layout)) { gridCell in
                        if let control = gridCell.control {
                            AgentMIDIControlView(
                                controller: controller,
                                control: control
                            )
                            .gridCellColumns(gridCell.columnSpan)
                        } else {
                            Color.clear
                                .frame(minHeight: 76)
                                .gridCellColumns(gridCell.columnSpan)
                        }
                    }
                }
            }
        }
    }

    private func gridCells(for row: Int, layout: AgentMIDILayout) -> [AgentMIDIGridCell] {
        let controls = layout.controls
            .filter { control in
                control.row == row
            }
            .sorted { leftControl, rightControl in
                leftControl.column < rightControl.column
            }

        var cells: [AgentMIDIGridCell] = []
        var nextColumn = 0

        for control in controls {
            if control.column > nextColumn {
                cells.append(
                    AgentMIDIGridCell(
                        id: "spacer-\(row)-\(nextColumn)",
                        columnSpan: control.column - nextColumn,
                        control: nil
                    )
                )
            }
            let availableSpan = max(min(control.columnSpan, layout.columns - control.column), 1)
            cells.append(
                AgentMIDIGridCell(
                    id: control.id.uuidString,
                    columnSpan: availableSpan,
                    control: control
                )
            )
            nextColumn = control.column + availableSpan
        }

        if nextColumn < layout.columns {
            cells.append(
                AgentMIDIGridCell(
                    id: "spacer-\(row)-\(nextColumn)",
                    columnSpan: layout.columns - nextColumn,
                    control: nil
                )
            )
        }

        return cells
    }
}

private struct AgentMIDIGridCell: Identifiable {
    var id: String
    var columnSpan: Int
    var control: AgentMIDIControl?
}

private struct AgentMIDIControlView: View {
    @ObservedObject var controller: AgentMIDIController
    let control: AgentMIDIControl

    var body: some View {
        Group {
            switch control.kind {
            case .pad, .widePad:
                AgentMIDIPadView(controller: controller, control: control)
            case .knob:
                AgentMIDIKnobView(controller: controller, control: control)
            case .indicator:
                AgentMIDIIndicatorView(controller: controller, control: control)
            }
        }
        .frame(minHeight: minimumControlHeight)
        .overlay {
            if controller.isEditing, controller.selectedControlID == control.id {
                RoundedRectangle(cornerRadius: controller.activeTheme.controlCornerRadius + 2, style: .continuous)
                    .stroke(controller.activeTheme.primaryAccentColor, lineWidth: 3)
                    .padding(-3)
            }
        }
    }

    private var minimumControlHeight: CGFloat {
        if control.kind == .widePad {
            return 86
        }
        return 76
    }
}

private struct AgentMIDIPadView: View {
    @ObservedObject var controller: AgentMIDIController
    let control: AgentMIDIControl
    @State private var isPressed = false

    var body: some View {
        let theme = controller.activeTheme
        VStack(spacing: 6) {
            Image(systemName: control.symbolName)
                .font(.system(size: symbolSize, weight: .medium))
                .foregroundStyle(accentColor(theme: theme))
            Text(control.title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .lineLimit(1)
            if !control.subtitle.isEmpty {
                Text(control.subtitle)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.secondaryTextColor)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(theme.textColor)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 9)
        .background(
            padBackgroundColor(theme: theme),
            in: RoundedRectangle(cornerRadius: theme.controlCornerRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: theme.controlCornerRadius, style: .continuous)
                .stroke(theme.borderColor.opacity(0.75), lineWidth: 1)
        }
        .shadow(color: .black.opacity(shadowOpacity), radius: shadowRadius, y: shadowOffset)
        .scaleEffect(padScale)
        .contentShape(RoundedRectangle(cornerRadius: theme.controlCornerRadius, style: .continuous))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                    controller.trigger(control)
                }
        )
    }

    private var symbolSize: CGFloat {
        if control.kind == .widePad {
            return 25
        }
        return 21
    }

    private var shadowOpacity: Double {
        if isPressed {
            return 0.04
        }
        return 0.12
    }

    private var shadowRadius: CGFloat {
        if isPressed {
            return 2
        }
        return 6
    }

    private var shadowOffset: CGFloat {
        if isPressed {
            return 1
        }
        return 3
    }

    private var padScale: CGFloat {
        if isPressed {
            return 0.975
        }
        return 1
    }

    private func padBackgroundColor(theme: AgentMIDITheme) -> Color {
        if isPressed {
            return theme.controlPressedColor
        }
        return theme.controlColor
    }

    private func accentColor(theme: AgentMIDITheme) -> Color {
        if control.accentRole == "secondary" {
            return theme.secondaryAccentColor
        }
        return theme.primaryAccentColor
    }
}

private struct AgentMIDIKnobView: View {
    @ObservedObject var controller: AgentMIDIController
    let control: AgentMIDIControl
    @State private var dragStartValue: Int?

    var body: some View {
        let theme = controller.activeTheme
        let value = controller.knobValues[control.id] ?? control.midi?.value ?? 64
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .stroke(theme.borderColor.opacity(0.8), lineWidth: 7)
                Circle()
                    .trim(from: 0.12, to: 0.12 + 0.76 * CGFloat(value) / 127)
                    .stroke(theme.primaryAccentColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(68))
                Circle()
                    .fill(theme.secondaryAccentColor)
                    .padding(10)
                    .shadow(color: .black.opacity(0.22), radius: 5, y: 3)
                Capsule()
                    .fill(theme.panelColor)
                    .frame(width: 4, height: 15)
                    .offset(y: -12)
                    .rotationEffect(.degrees(-135 + 270 * Double(value) / 127))
            }
            .frame(width: 56, height: 56)

            Text(control.title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
            Text("\(value)")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(theme.secondaryTextColor)
        }
        .foregroundStyle(theme.textColor)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 7)
        .background(theme.controlColor, in: RoundedRectangle(cornerRadius: theme.controlCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: theme.controlCornerRadius, style: .continuous)
                .stroke(theme.borderColor.opacity(0.75), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: theme.controlCornerRadius, style: .continuous))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { gestureValue in
                    if controller.isEditing {
                        controller.selectControl(control.id)
                        return
                    }
                    let startingValue = dragStartValue ?? value
                    if dragStartValue == nil {
                        dragStartValue = value
                    }
                    let verticalDelta = Int((-gestureValue.translation.height / 120) * 127)
                    controller.updateKnob(
                        control,
                        value: startingValue + verticalDelta,
                        phase: .changed
                    )
                }
                .onEnded { _ in
                    if controller.isEditing {
                        controller.selectControl(control.id)
                    } else {
                        let finalValue = controller.knobValues[control.id] ?? value
                        controller.updateKnob(control, value: finalValue, phase: .ended)
                    }
                    dragStartValue = nil
                }
        )
    }
}

private struct AgentMIDIIndicatorView: View {
    @ObservedObject var controller: AgentMIDIController
    let control: AgentMIDIControl

    var body: some View {
        let theme = controller.activeTheme
        VStack(spacing: 7) {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(indicatorColor(index: index, theme: theme))
                        .frame(width: 12, height: 5)
                }
            }
            Image(systemName: control.symbolName)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(theme.secondaryAccentColor)
            Text(control.title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
            Text(transportLabel)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(theme.secondaryTextColor)
        }
        .foregroundStyle(theme.textColor)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 7)
        .background(theme.controlColor, in: RoundedRectangle(cornerRadius: theme.controlCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: theme.controlCornerRadius, style: .continuous)
                .stroke(theme.borderColor.opacity(0.75), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: theme.controlCornerRadius, style: .continuous))
        .onTapGesture {
            if controller.isEditing {
                controller.selectControl(control.id)
            }
        }
    }

    private var transportLabel: String {
        if controller.transportStatus.contains("online") {
            return "ONLINE"
        }
        return "OFFLINE"
    }

    private func indicatorColor(index: Int, theme: AgentMIDITheme) -> Color {
        if index == 2 {
            return theme.primaryAccentColor
        }
        return theme.secondaryTextColor.opacity(0.45)
    }
}

private struct AgentMIDIControlEditorView: View {
    @ObservedObject var controller: AgentMIDIController

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Control Mapping", systemImage: "slider.horizontal.3")
                    .font(.headline)
                Spacer()
                Button {
                    controller.saveActiveLayout()
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .buttonStyle(.plain)
                .help("Save layout")
            }

            Divider()

            if controller.selectedControl != nil {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        editorTextField("Title", text: titleBinding)
                        editorTextField("Subtitle", text: subtitleBinding)
                        editorTextField("SF Symbol", text: symbolBinding)

                        Picker("Control", selection: kindBinding) {
                            ForEach(AgentMIDIControlKind.allCases) { kind in
                                Text(kind.displayName)
                                    .tag(kind)
                            }
                        }

                        HStack {
                            Stepper("Row \(rowBinding.wrappedValue + 1)", value: rowBinding, in: 0...15)
                            Stepper("Column \(columnBinding.wrappedValue + 1)", value: columnBinding, in: 0...15)
                        }
                        Stepper("Column span \(columnSpanBinding.wrappedValue)", value: columnSpanBinding, in: 1...8)

                        Divider()

                        Toggle("Emit MIDI", isOn: midiEnabledBinding)

                        if controller.selectedControl?.midi != nil {
                            Picker("Message", selection: midiKindBinding) {
                                ForEach(AgentMIDIMessageKind.allCases) { kind in
                                    Text(kind.displayName)
                                        .tag(kind)
                                }
                            }
                            Stepper("Channel \(midiChannelBinding.wrappedValue)", value: midiChannelBinding, in: 1...16)
                            Stepper("Number \(midiNumberBinding.wrappedValue)", value: midiNumberBinding, in: 0...127)
                            Stepper("Value \(midiValueBinding.wrappedValue)", value: midiValueBinding, in: 0...127)
                        }

                        Divider()

                        Picker("Action", selection: commandKindBinding) {
                            ForEach(AgentMIDICommandKind.allCases) { kind in
                                Text(kind.displayName)
                                    .tag(kind)
                            }
                        }

                        editorTextField("Command", text: commandBinding)
                        editorTextField("Prompt", text: promptBinding, axis: .vertical)
                        editorTextField("Arguments, one per line", text: argumentsBinding, axis: .vertical)
                    }
                }
            } else {
                ContentUnavailableView(
                    "Select a control",
                    systemImage: "cursorarrow.click",
                    description: Text("Choose a pad or knob on the deck to edit its MIDI and agent action mappings.")
                )
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.primary.opacity(0.1), lineWidth: 1)
        }
    }

    private func editorTextField(
        _ title: String,
        text: Binding<String>,
        axis: Axis = .horizontal
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(title, text: text, axis: axis)
                .textFieldStyle(.roundedBorder)
                .lineLimit(textFieldLineLimit(axis: axis))
        }
    }

    private func textFieldLineLimit(axis: Axis) -> ClosedRange<Int> {
        if axis == .vertical {
            return 2...5
        }
        return 1...1
    }

    private var titleBinding: Binding<String> {
        stringBinding(
            get: { control in control.title },
            set: { control, value in control.title = value }
        )
    }

    private var subtitleBinding: Binding<String> {
        stringBinding(
            get: { control in control.subtitle },
            set: { control, value in control.subtitle = value }
        )
    }

    private var symbolBinding: Binding<String> {
        stringBinding(
            get: { control in control.symbolName },
            set: { control, value in control.symbolName = value }
        )
    }

    private var commandBinding: Binding<String> {
        stringBinding(
            get: { control in control.command.command },
            set: { control, value in control.command.command = value }
        )
    }

    private var promptBinding: Binding<String> {
        stringBinding(
            get: { control in control.command.prompt },
            set: { control, value in control.command.prompt = value }
        )
    }

    private var argumentsBinding: Binding<String> {
        stringBinding(
            get: { control in control.command.arguments.joined(separator: "\n") },
            set: { control, value in
                control.command.arguments = value
                    .components(separatedBy: .newlines)
                    .map { argument in argument.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { argument in !argument.isEmpty }
            }
        )
    }

    private var kindBinding: Binding<AgentMIDIControlKind> {
        Binding(
            get: { controller.selectedControl?.kind ?? .pad },
            set: { newValue in
                controller.updateSelectedControl { control in
                    control.kind = newValue
                }
            }
        )
    }

    private var rowBinding: Binding<Int> {
        integerBinding(
            get: { control in control.row },
            set: { control, value in control.row = value }
        )
    }

    private var columnBinding: Binding<Int> {
        integerBinding(
            get: { control in control.column },
            set: { control, value in control.column = value }
        )
    }

    private var columnSpanBinding: Binding<Int> {
        integerBinding(
            get: { control in control.columnSpan },
            set: { control, value in control.columnSpan = value }
        )
    }

    private var midiEnabledBinding: Binding<Bool> {
        Binding(
            get: { controller.selectedControl?.midi != nil },
            set: { isEnabled in
                controller.updateSelectedControl { control in
                    if isEnabled, control.midi == nil {
                        control.midi = AgentMIDIMapping()
                    }
                    if !isEnabled {
                        control.midi = nil
                    }
                }
            }
        )
    }

    private var midiKindBinding: Binding<AgentMIDIMessageKind> {
        Binding(
            get: { controller.selectedControl?.midi?.kind ?? .note },
            set: { newValue in
                controller.updateSelectedControl { control in
                    control.midi?.kind = newValue
                }
            }
        )
    }

    private var midiChannelBinding: Binding<Int> {
        midiIntegerBinding(
            get: { mapping in mapping.channel },
            set: { mapping, value in mapping.channel = value }
        )
    }

    private var midiNumberBinding: Binding<Int> {
        midiIntegerBinding(
            get: { mapping in mapping.number },
            set: { mapping, value in mapping.number = value }
        )
    }

    private var midiValueBinding: Binding<Int> {
        midiIntegerBinding(
            get: { mapping in mapping.value },
            set: { mapping, value in mapping.value = value }
        )
    }

    private var commandKindBinding: Binding<AgentMIDICommandKind> {
        Binding(
            get: { controller.selectedControl?.command.kind ?? .none },
            set: { newValue in
                controller.updateSelectedControl { control in
                    control.command.kind = newValue
                }
            }
        )
    }

    private func stringBinding(
        get: @escaping (AgentMIDIControl) -> String,
        set: @escaping (inout AgentMIDIControl, String) -> Void
    ) -> Binding<String> {
        Binding(
            get: {
                guard let control = controller.selectedControl else {
                    return ""
                }
                return get(control)
            },
            set: { newValue in
                controller.updateSelectedControl { control in
                    set(&control, newValue)
                }
            }
        )
    }

    private func integerBinding(
        get: @escaping (AgentMIDIControl) -> Int,
        set: @escaping (inout AgentMIDIControl, Int) -> Void
    ) -> Binding<Int> {
        Binding(
            get: {
                guard let control = controller.selectedControl else {
                    return 0
                }
                return get(control)
            },
            set: { newValue in
                controller.updateSelectedControl { control in
                    set(&control, newValue)
                }
            }
        )
    }

    private func midiIntegerBinding(
        get: @escaping (AgentMIDIMapping) -> Int,
        set: @escaping (inout AgentMIDIMapping, Int) -> Void
    ) -> Binding<Int> {
        Binding(
            get: {
                guard let mapping = controller.selectedControl?.midi else {
                    return 0
                }
                return get(mapping)
            },
            set: { newValue in
                controller.updateSelectedControl { control in
                    guard var mapping = control.midi else {
                        return
                    }
                    set(&mapping, newValue)
                    control.midi = mapping
                }
            }
        )
    }
}

private extension AgentMIDITheme {
    var backgroundColor: Color {
        Color(agentMIDIHex: backgroundHex)
    }

    var panelColor: Color {
        Color(agentMIDIHex: panelHex)
    }

    var controlColor: Color {
        Color(agentMIDIHex: controlHex)
    }

    var controlPressedColor: Color {
        Color(agentMIDIHex: controlPressedHex)
    }

    var primaryAccentColor: Color {
        Color(agentMIDIHex: primaryAccentHex)
    }

    var secondaryAccentColor: Color {
        Color(agentMIDIHex: secondaryAccentHex)
    }

    var textColor: Color {
        Color(agentMIDIHex: textHex)
    }

    var secondaryTextColor: Color {
        Color(agentMIDIHex: secondaryTextHex)
    }

    var borderColor: Color {
        Color(agentMIDIHex: borderHex)
    }
}

private extension Color {
    init(agentMIDIHex rawValue: String) {
        let normalizedValue = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var hexadecimalValue: UInt64 = 0
        Scanner(string: normalizedValue).scanHexInt64(&hexadecimalValue)

        let redValue: Double
        let greenValue: Double
        let blueValue: Double
        let alphaValue: Double

        switch normalizedValue.count {
        case 8:
            redValue = Double((hexadecimalValue >> 24) & 0xFF) / 255
            greenValue = Double((hexadecimalValue >> 16) & 0xFF) / 255
            blueValue = Double((hexadecimalValue >> 8) & 0xFF) / 255
            alphaValue = Double(hexadecimalValue & 0xFF) / 255
        default:
            redValue = Double((hexadecimalValue >> 16) & 0xFF) / 255
            greenValue = Double((hexadecimalValue >> 8) & 0xFF) / 255
            blueValue = Double(hexadecimalValue & 0xFF) / 255
            alphaValue = 1
        }

        self.init(.sRGB, red: redValue, green: greenValue, blue: blueValue, opacity: alphaValue)
    }
}
