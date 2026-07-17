import CoreMIDI
import Foundation

public enum AgentMIDITransportError: Error, LocalizedError, Sendable {
    case clientCreationFailed(OSStatus)
    case sourceCreationFailed(OSStatus)
    case packetCreationFailed
    case transmissionFailed(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .clientCreationFailed(let status):
            return "CoreMIDI could not create the Agent MIDI client. Status: \(status)."
        case .sourceCreationFailed(let status):
            return "CoreMIDI could not create the Agent MIDI virtual source. Status: \(status)."
        case .packetCreationFailed:
            return "CoreMIDI could not create a MIDI packet."
        case .transmissionFailed(let status):
            return "CoreMIDI could not transmit the MIDI packet. Status: \(status)."
        }
    }
}

public final class AgentMIDIVirtualSource: @unchecked Sendable {
    public private(set) var clientReference = MIDIClientRef()
    public private(set) var sourceReference = MIDIEndpointRef()
    public private(set) var isRunning = false
    public let displayName: String

    private let lock = NSLock()

    public init(displayName: String = "Agent MIDI") {
        self.displayName = displayName
    }

    deinit {
        stop()
    }

    public func start() throws {
        lock.lock()
        defer {
            lock.unlock()
        }

        guard !isRunning else {
            return
        }

        var newClientReference = MIDIClientRef()
        let clientStatus = MIDIClientCreate(
            "\(displayName) Client" as CFString,
            nil,
            nil,
            &newClientReference
        )
        guard clientStatus == noErr else {
            throw AgentMIDITransportError.clientCreationFailed(clientStatus)
        }

        var newSourceReference = MIDIEndpointRef()
        let sourceStatus = MIDISourceCreate(
            newClientReference,
            displayName as CFString,
            &newSourceReference
        )
        guard sourceStatus == noErr else {
            MIDIClientDispose(newClientReference)
            throw AgentMIDITransportError.sourceCreationFailed(sourceStatus)
        }

        clientReference = newClientReference
        sourceReference = newSourceReference
        isRunning = true
    }

    public func stop() {
        lock.lock()
        defer {
            lock.unlock()
        }

        guard isRunning else {
            return
        }

        if sourceReference != 0 {
            MIDIEndpointDispose(sourceReference)
        }
        if clientReference != 0 {
            MIDIClientDispose(clientReference)
        }

        sourceReference = 0
        clientReference = 0
        isRunning = false
    }

    public func sendNoteOn(channel: Int, note: Int, velocity: Int) throws {
        try send(
            status: UInt8(0x90 | normalizedChannel(channel)),
            data1: UInt8(clamping: note),
            data2: UInt8(clamping: velocity)
        )
    }

    public func sendNoteOff(channel: Int, note: Int, velocity: Int = 0) throws {
        try send(
            status: UInt8(0x80 | normalizedChannel(channel)),
            data1: UInt8(clamping: note),
            data2: UInt8(clamping: velocity)
        )
    }

    public func sendControlChange(channel: Int, controller: Int, value: Int) throws {
        try send(
            status: UInt8(0xB0 | normalizedChannel(channel)),
            data1: UInt8(clamping: controller),
            data2: UInt8(clamping: value)
        )
    }

    public func sendProgramChange(channel: Int, program: Int) throws {
        try send(
            status: UInt8(0xC0 | normalizedChannel(channel)),
            data1: UInt8(clamping: program),
            data2: nil
        )
    }

    private func send(status: UInt8, data1: UInt8, data2: UInt8?) throws {
        if !isRunning {
            try start()
        }

        lock.lock()
        defer {
            lock.unlock()
        }

        var bytes = [status, data1]
        if let data2 {
            bytes.append(data2)
        }

        var packetList = MIDIPacketList()
        let packetListSize = MemoryLayout<MIDIPacketList>.size
        var packetCreationFailed = false
        let transmissionStatus = bytes.withUnsafeBufferPointer { byteBuffer -> OSStatus in
            withUnsafeMutablePointer(to: &packetList) { packetListPointer -> OSStatus in
                let packetPointer = MIDIPacketListInit(packetListPointer)
                guard MIDIPacketListAdd(
                    packetListPointer,
                    packetListSize,
                    packetPointer,
                    0,
                    byteBuffer.count,
                    byteBuffer.baseAddress!
                ) != nil else {
                    packetCreationFailed = true
                    return noErr
                }
                return MIDIReceived(sourceReference, packetListPointer)
            }
        }

        if packetCreationFailed {
            throw AgentMIDITransportError.packetCreationFailed
        }
        guard transmissionStatus == noErr else {
            throw AgentMIDITransportError.transmissionFailed(transmissionStatus)
        }
    }

    private func normalizedChannel(_ channel: Int) -> UInt8 {
        UInt8(min(max(channel, 1), 16) - 1)
    }
}
