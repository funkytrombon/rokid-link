import Foundation

/// The public entry point.
///
/// ```swift
/// let link = RokidLink()
/// try await link.connect()
/// let jpeg = try await link.capturePhoto()
/// try await link.showOnHUD("Merhaba")
/// ```
public actor RokidLink {

    /// The HUD is roughly 480x400, monochrome. See docs/ARCHITECTURE.md.
    public static let maxHUDLines = 5
    public static let maxHUDLineLength = 25

    private var transport: Transport?
    private var eventContinuation: AsyncStream<GlassesEvent>.Continuation?
    private var photoWaiters: [String: CheckedContinuation<Data, Error>] = [:]

    public nonisolated let events: AsyncStream<GlassesEvent>

    public init() {
        var cont: AsyncStream<GlassesEvent>.Continuation!
        self.events = AsyncStream { cont = $0 }
        self.eventContinuation = cont
    }

    /// Try Wi-Fi first, then fall back. Currently Wi-Fi only; BLE L2CAP is on the roadmap.
    public func connect(transport: Transport? = nil) async throws {
        let t = transport ?? WiFiTransport()
        try await t.connect()
        self.transport = t
        Task { await self.pump(t) }
        eventContinuation?.yield(.connected)
    }

    public func disconnect() async {
        await transport?.disconnect()
        transport = nil
        eventContinuation?.yield(.disconnected)
    }

    // MARK: - Commands

    /// Show text on the HUD. Split long text before calling: the display cannot scroll.
    public func showOnHUD(_ lines: [String], ttlMs: Int = 4000) async throws {
        guard lines.count <= Self.maxHUDLines else {
            throw RokidLinkError.hudOverflow(lines: lines.count, maxLines: Self.maxHUDLines)
        }
        guard let transport else { throw RokidLinkError.notConnected }
        let payload: [String: AnyCodable] = [
            "lines": AnyCodable(lines),
            "ttlMs": AnyCodable(ttlMs)
        ]
        try await transport.send(Envelope(type: "hud.show", payload: payload))
    }

    public func showOnHUD(_ text: String, ttlMs: Int = 4000) async throws {
        try await showOnHUD(Self.wrap(text), ttlMs: ttlMs)
    }

    public func clearHUD() async throws {
        guard let transport else { throw RokidLinkError.notConnected }
        try await transport.send(Envelope(type: "hud.clear"))
    }

    /// Ask the glasses for a photo. They downscale and compress before sending.
    public func capturePhoto(maxEdge: Int = 1024, quality: Int = 80) async throws -> Data {
        guard let transport else { throw RokidLinkError.notConnected }
        let envelope = Envelope(type: "photo.capture", payload: [
            "maxEdge": AnyCodable(maxEdge),
            "quality": AnyCodable(quality)
        ])
        try await transport.send(envelope)
        return try await withCheckedThrowingContinuation { cont in
            photoWaiters[envelope.id] = cont
        }
    }

    // MARK: - Inbound

    private func pump(_ transport: Transport) async {
        for await frame in transport.inbound {
            switch frame.envelope.type {
            case "photo.data":
                if let waiter = photoWaiters.removeValue(forKey: frame.envelope.id) {
                    if let data = frame.binary {
                        waiter.resume(returning: data)
                    } else {
                        waiter.resume(throwing: RokidLinkError.transport("photo.data without payload"))
                    }
                }
            case "event.tap":
                let fingers = (frame.envelope.payload["fingers"]?.value as? Int) ?? 1
                eventContinuation?.yield(.touchpadTap(fingers: fingers))
            case "event.wake":
                let phrase = (frame.envelope.payload["phrase"]?.value as? String) ?? ""
                eventContinuation?.yield(.wakePhrase(phrase))
            case "device.status":
                let battery = (frame.envelope.payload["battery"]?.value as? Int) ?? 0
                let wifi = (frame.envelope.payload["wifi"]?.value as? Bool) ?? false
                eventContinuation?.yield(.status(battery: battery, wifi: wifi))
            case "error":
                let code = (frame.envelope.payload["code"]?.value as? String) ?? "unknown"
                let message = (frame.envelope.payload["message"]?.value as? String) ?? ""
                eventContinuation?.yield(.failure(code: code, message: message))
            default:
                break
            }
        }
        eventContinuation?.yield(.disconnected)
    }

    // MARK: - Helpers

    /// Naive word wrap to the HUD's line length. Apps with real typography needs should wrap themselves.
    public static func wrap(_ text: String, width: Int = maxHUDLineLength) -> [String] {
        var lines: [String] = []
        var current = ""
        for word in text.split(separator: " ") {
            if current.isEmpty {
                current = String(word)
            } else if current.count + 1 + word.count <= width {
                current += " " + word
            } else {
                lines.append(current)
                current = String(word)
            }
        }
        if !current.isEmpty { lines.append(current) }
        return Array(lines.prefix(maxHUDLines))
    }
}
