import Foundation

/// A protocol envelope. See docs/PROTOCOL.md.
public struct Envelope: Codable, Sendable {
    public let v: Int
    public let id: String
    public let type: String
    public let payload: [String: AnyCodable]

    public init(type: String, id: String = UUID().uuidString.prefix(8).lowercased(), payload: [String: AnyCodable] = [:]) {
        self.v = 1
        self.id = id
        self.type = type
        self.payload = payload
    }
}

/// Something the glasses reported.
public enum GlassesEvent: Sendable {
    case connected
    case disconnected
    case touchpadTap(fingers: Int)
    case swipe(direction: SwipeDirection)
    case wakePhrase(String)
    case status(battery: Int, wifi: Bool)
    case failure(code: String, message: String)
}

public enum SwipeDirection: String, Codable, Sendable {
    case forward = "fwd"
    case back
}

public enum RokidLinkError: Error, Sendable {
    /// No transport could reach the glasses.
    case notConnected
    /// hud.show was given more than the display can hold. See docs/ARCHITECTURE.md.
    case hudOverflow(lines: Int, maxLines: Int)
    case transport(String)
    case timedOut
}

/// Minimal type-erased JSON value, so payloads stay Codable without a concrete type per message.
public struct AnyCodable: Codable, Sendable {
    public let value: Sendable

    public init(_ value: Sendable) { self.value = value }

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(Bool.self) { value = v }
        else if let v = try? c.decode(Int.self) { value = v }
        else if let v = try? c.decode(Double.self) { value = v }
        else if let v = try? c.decode(String.self) { value = v }
        else if let v = try? c.decode([String].self) { value = v }
        else { value = "" }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch value {
        case let v as Bool: try c.encode(v)
        case let v as Int: try c.encode(v)
        case let v as Double: try c.encode(v)
        case let v as String: try c.encode(v)
        case let v as [String]: try c.encode(v)
        default: try c.encodeNil()
        }
    }
}
