import Foundation

/// A way to move protocol frames between the phone and the glasses.
///
/// Conform to this to add a transport. Nothing above this layer changes.
public protocol Transport: AnyObject, Sendable {
    var isConnected: Bool { get }

    func connect() async throws
    func disconnect() async

    /// Send an envelope, optionally followed by one binary frame.
    func send(_ envelope: Envelope, binary: Data?) async throws

    /// Inbound frames, in arrival order.
    var inbound: AsyncStream<InboundFrame> { get }
}

public struct InboundFrame: Sendable {
    public let envelope: Envelope
    public let binary: Data?

    public init(envelope: Envelope, binary: Data? = nil) {
        self.envelope = envelope
        self.binary = binary
    }
}

public extension Transport {
    func send(_ envelope: Envelope) async throws {
        try await send(envelope, binary: nil)
    }
}
