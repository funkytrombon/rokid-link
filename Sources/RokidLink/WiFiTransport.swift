import Foundation

/// Primary transport: a WebSocket over the local network, normally the iPhone's Personal Hotspot.
///
/// Requires `NSLocalNetworkUsageDescription` and `NSBonjourServices` in Info.plist.
/// Without them iOS blocks the connection without reporting an error.
public final class WiFiTransport: NSObject, Transport, @unchecked Sendable {

    /// Default address when Bonjour resolution fails. On an iPhone hotspot the phone is the gateway.
    public static let hotspotGateway = "172.20.10.1"
    public static let defaultPort = 8975

    private var task: URLSessionWebSocketTask?
    private var session: URLSession?
    private var continuation: AsyncStream<InboundFrame>.Continuation?
    private var pendingEnvelope: Envelope?

    public private(set) var isConnected = false
    public let inbound: AsyncStream<InboundFrame>

    private let host: String
    private let port: Int

    public init(host: String = WiFiTransport.hotspotGateway, port: Int = WiFiTransport.defaultPort) {
        self.host = host
        self.port = port
        var cont: AsyncStream<InboundFrame>.Continuation!
        self.inbound = AsyncStream { cont = $0 }
        super.init()
        self.continuation = cont
    }

    public func connect() async throws {
        guard let url = URL(string: "ws://\(host):\(port)/link") else {
            throw RokidLinkError.transport("bad url")
        }
        let session = URLSession(configuration: .default)
        let task = session.webSocketTask(with: url)
        task.resume()

        self.session = session
        self.task = task
        self.isConnected = true

        receiveLoop()
    }

    public func disconnect() async {
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        isConnected = false
        continuation?.finish()
    }

    public func send(_ envelope: Envelope, binary: Data?) async throws {
        guard let task, isConnected else { throw RokidLinkError.notConnected }
        let json = try JSONEncoder().encode(envelope)
        guard let text = String(data: json, encoding: .utf8) else {
            throw RokidLinkError.transport("encoding failed")
        }
        try await task.send(.string(text))
        if let binary {
            try await task.send(.data(binary))
        }
    }

    // MARK: - Receiving

    /// Text frames carry an envelope. A binary frame belongs to the envelope that preceded it.
    private func receiveLoop() {
        guard let task else { return }
        task.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure:
                self.isConnected = false
                self.continuation?.finish()
            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8),
                       let envelope = try? JSONDecoder().decode(Envelope.self, from: data) {
                        if self.expectsBinary(envelope) {
                            self.pendingEnvelope = envelope
                        } else {
                            self.continuation?.yield(InboundFrame(envelope: envelope))
                        }
                    }
                case .data(let data):
                    if let envelope = self.pendingEnvelope {
                        self.pendingEnvelope = nil
                        self.continuation?.yield(InboundFrame(envelope: envelope, binary: data))
                    }
                @unknown default:
                    break
                }
                self.receiveLoop()
            }
        }
    }

    private func expectsBinary(_ envelope: Envelope) -> Bool {
        envelope.type == "photo.data" || envelope.type == "audio.chunk"
    }
}
