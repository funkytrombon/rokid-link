import XCTest
@testable import RokidLink

final class RokidLinkTests: XCTestCase {

    func testWrapRespectsLineWidth() {
        let lines = RokidLink.wrap("the quick brown fox jumps over the lazy dog", width: 12)
        XCTAssertTrue(lines.allSatisfy { $0.count <= 12 })
    }

    func testWrapNeverExceedsHUDCapacity() {
        let long = String(repeating: "word ", count: 200)
        XCTAssertLessThanOrEqual(RokidLink.wrap(long).count, RokidLink.maxHUDLines)
    }

    func testEnvelopeRoundTrip() throws {
        let envelope = Envelope(type: "hud.show", payload: ["ttlMs": AnyCodable(4000)])
        let data = try JSONEncoder().encode(envelope)
        let decoded = try JSONDecoder().decode(Envelope.self, from: data)
        XCTAssertEqual(decoded.type, "hud.show")
        XCTAssertEqual(decoded.v, 1)
    }
}
