// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "AgentMIDI",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AgentMIDIKit",
            targets: ["AgentMIDIKit"]
        ),
        .executable(
            name: "AgentMIDIApp",
            targets: ["AgentMIDIApp"]
        )
    ],
    targets: [
        .target(
            name: "AgentMIDIKit",
            path: "Sources/AgentMIDIKit",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("CoreMIDI"),
                .linkedFramework("SwiftUI")
            ]
        ),
        .executableTarget(
            name: "AgentMIDIApp",
            dependencies: ["AgentMIDIKit"],
            path: "Sources/AgentMIDIApp"
        )
    ]
)
