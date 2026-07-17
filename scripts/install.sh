#!/bin/bash
set -euo pipefail
SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIRECTORY="$(cd "$SCRIPT_DIRECTORY/.." && pwd)"
INSTALL_DIRECTORY="${AGENT_MIDI_INSTALL_DIRECTORY:-$HOME/Applications}"
APPLICATION_DIRECTORY="$INSTALL_DIRECTORY/Agent MIDI.app"
CONTENTS_DIRECTORY="$APPLICATION_DIRECTORY/Contents"
MACOS_DIRECTORY="$CONTENTS_DIRECTORY/MacOS"

cd "$PROJECT_DIRECTORY"
swift build -c release --product AgentMIDIApp
BINARY_PATH="$(swift build -c release --show-bin-path)/AgentMIDIApp"

rm -rf "$APPLICATION_DIRECTORY"
mkdir -p "$MACOS_DIRECTORY"
cp "$BINARY_PATH" "$MACOS_DIRECTORY/AgentMIDIApp"
chmod +x "$MACOS_DIRECTORY/AgentMIDIApp"

cat > "$CONTENTS_DIRECTORY/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>Agent MIDI</string>
    <key>CFBundleExecutable</key>
    <string>AgentMIDIApp</string>
    <key>CFBundleIdentifier</key>
    <string>com.wundercorp.agentmidi</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Agent MIDI</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.music</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

printf 'APPL????' > "$CONTENTS_DIRECTORY/PkgInfo"
printf 'Installed Agent MIDI at %s\n' "$APPLICATION_DIRECTORY"
