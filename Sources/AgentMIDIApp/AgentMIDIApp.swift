import AgentMIDIKit
import SwiftUI

@main
struct AgentMIDIStandaloneApp: App {
    @StateObject private var controller = AgentMIDIController()

    var body: some Scene {
        WindowGroup("Agent MIDI") {
            AgentMIDIDeckView(controller: controller)
                .frame(minWidth: 650, minHeight: 680)
                .onAppear {
                    controller.startTransport()
                }
        }
        .defaultSize(width: 720, height: 760)
        .windowResizability(.contentMinSize)
        .commands {
            CommandMenu("Agent MIDI") {
                Button("Program Controls") {
                    controller.isEditing.toggle()
                }
                .keyboardShortcut(",", modifiers: [.command, .shift])

                Button("Duplicate Layout") {
                    controller.duplicateActiveLayout()
                }

                Divider()

                Button("Open Layout Folder") {
                    controller.revealLayoutsDirectory()
                }

                Button("Open Skin Folder") {
                    controller.revealThemesDirectory()
                }

                Button("Reload Layouts and Skins") {
                    controller.reloadDocuments()
                }
            }
        }
    }
}
