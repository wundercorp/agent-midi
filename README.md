# Agent MIDI - Virtual Agentic Keyboard

Agent MIDI is a native Swift programmable MIDI deck for macOS. It runs as an independent virtual MIDI keyboard and can also be embedded inside a SwiftUI IDE.  Join the Discord for any issues or troubleshooting https://discord.gg/w6htGsCkx6

Inspired by @xikhar | http://x.com/xikhar

<img width="1436" height="1438" alt="Bazaart_766A631B-D3BE-47F6-8BA1-633CF321260E" src="https://github.com/user-attachments/assets/c421fdda-4ec0-4906-8bbb-9d8045c71959" />

Interoperable with Codex, Claude Code, BuilderStudio, and many other IDEs.

Easy to run, just download and run via

```
swift run AgentMIDIApp
```

## Current implementation

- Native SwiftUI interface inspired by compact programmable hardware decks
- CoreMIDI virtual source named `Agent MIDI`
- Note, control-change, and program-change mappings
- Built-in visual programming inspector for every control
- JSON layouts and skins loaded from Application Support
- Host IDE commands for BuilderStudio
- Codex CLI and Claude Code command adapters
- Workspace launch adapters for Visual Studio Code, Cursor, Zed, and Xcode
- Distributed notification event bridge for other native macOS applications
- Reusable `AgentMIDIKit` Swift package

## Run independently

```bash
cd AgentMIDI
swift run AgentMIDIApp
```

The virtual `Agent MIDI` source appears in CoreMIDI-aware applications while Agent MIDI is running.

## Install as a macOS application

```bash
cd AgentMIDI
./scripts/install.sh
open "$HOME/Applications/Agent MIDI.app"
```

Set `AGENT_MIDI_INSTALL_DIRECTORY` to install somewhere else.

## Use inside BuilderStudio

Open BuilderStudio and choose **Agent MIDI > Open Agent MIDI**, press **Shift-Command-M**, or select the piano-keys toolbar button.

The built-in layout maps pads to BuilderStudio modes, submit, approve, cancel, build, test, Codex, and Claude Code actions.

## Program controls

Choose **Program** and select a control. The inspector edits:

- Control type, row, column, and span
- Title, subtitle, and SF Symbol
- MIDI message type, channel, number, and value
- Host, agent CLI, editor, shell, and URL actions
- Agent prompts and command arguments

Edits are saved as JSON layouts in:

```text
~/Library/Application Support/AgentMIDI/Layouts
```

Skins are loaded from:

```text
~/Library/Application Support/AgentMIDI/Themes
```

The interface includes buttons that reveal both folders in Finder.

## Custom layouts

Copy a JSON layout from `Examples/Layouts` into the layouts folder and reload layouts. A layout controls the grid size, control placement, MIDI mapping, and command action.

Supported command kinds:

```text
none
host
codex
claudeCode
visualStudioCode
cursor
zed
xcode
shell
openURL
```

Use `${workspace}` or `$WORKSPACE` inside shell commands, prompts, and arguments to inject the active workspace path.

## Custom skins

Copy a JSON skin from `Examples/Themes` into the themes folder and reload skins. Skins control the deck colors, border colors, corner radii, and spacing.

## Interoperability

Agent MIDI uses three layers:

1. Standard CoreMIDI messages for DAWs, automation tools, and MIDI-aware applications.
2. Configurable CLI adapters for coding agents and editors.
3. A macOS distributed notification named `com.wundercorp.agentmidi.event` with the encoded event JSON in the `event` user-info field.

A host IDE can embed `AgentMIDIDeckView`, assign `workspaceURL`, and provide `hostCommandHandler` on `AgentMIDIController`.

## Repository split

The `AgentMIDI` directory is self-contained and can be moved into its own repository. BuilderStudio compiles the shared source files directly from `AgentMIDI/Sources/AgentMIDIKit`, which keeps the packaged and embedded implementations on one code path.
