RokidLink wire protocol v1
Transport-agnostic. The same messages travel over the Wi-Fi WebSocket and the BLE L2CAP stream.
Framing
Text frames carry a JSON envelope. Binary frames carry payload bytes belonging to the envelope that immediately preceded them.
```json
{
  "v": 1,
  "id": "8f14e45f",
  "type": "photo.capture",
  "payload": {}
}
```
Field	Meaning
`v`	Protocol version. Always `1` for now.
`id`	Correlation id. A response reuses the id of its request.
`type`	Namespaced message type, see below.
`payload`	Type-specific object. May be empty.
Over BLE L2CAP there are no frame boundaries, so each frame is prefixed with a 4-byte big-endian length and a 1-byte kind (`0x01` text, `0x02` binary).
Messages
Phone → glasses
Type	Payload	Notes
`hud.show`	`{ "lines": ["..."], "ttlMs": 4000 }`	Max 5 lines, ~25 chars each. Longer input is the sender's problem to split.
`hud.clear`	`{}`	
`photo.capture`	`{ "maxEdge": 1024, "quality": 80 }`	Glasses downscale and compress before sending.
`audio.start`	`{ "sampleRate": 16000 }`	
`audio.stop`	`{}`	
`device.query`	`{}`	
Glasses → phone
Type	Payload	Notes
`photo.data`	`{ "mime": "image/jpeg", "bytes": 48213 }`	Followed by one binary frame.
`audio.chunk`	`{ "seq": 12 }`	Followed by one binary frame of PCM.
`event.tap`	`{ "fingers": 1 }`	Touchpad.
`event.swipe`	`{ "dir": "fwd" }`	
`event.wake`	`{ "phrase": "..." }`	Custom offline wake phrase. `Hi Rokid` is reserved by the system.
`device.status`	`{ "battery": 62, "wifi": true }`	
`error`	`{ "code": "...", "message": "..." }`	
Handshake
Phone opens a listener on `0.0.0.0:8975`.
Phone advertises Bonjour service `_rokidlink._tcp`.
Glasses resolve it, or fall back to the hotspot gateway at `172.20.10.1`.
Glasses connect and send `device.status`.
Phone replies `hud.show` with a connection confirmation.
If Bonjour resolution fails within 5 seconds, the glasses retry the gateway address directly. iOS requires `NSLocalNetworkUsageDescription` and an `NSBonjourServices` entry in Info.plist, or the socket fails silently.
Design rules
The phone is the brain. The glasses app captures, transmits, and renders. It makes no decisions and calls no external APIs. This keeps the glasses-side app small enough to stay reliable on 2 GB of RAM, and keeps model choice on the phone where you can change it.
The glasses never hold state. After a reconnect, the phone re-establishes whatever should be on screen.
Compress at the source. A 12 MP frame never crosses the wire. The glasses downscale before sending.
Open questions
Reconnect semantics when the hotspot drops mid-capture.
Whether `audio.chunk` should carry Opus instead of raw PCM.
Backpressure when the phone is slower than the capture rate.
