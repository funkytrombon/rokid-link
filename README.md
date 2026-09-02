RokidLink
An open iOS ↔ Rokid Glasses transport layer. Swift Package + a small glasses-side Android companion, so iPhone apps can capture photos, stream audio, and draw on the HUD without reverse-engineering the connection first.
> Status: **early / work in progress.** The protocol is defined, the Swift API surface is stubbed, the Wi-Fi transport is being implemented. Contributions and issues welcome.
Why this exists
The Rokid community has built dozens of Android companion apps. On iOS there are two.
That gap isn't a lack of interest — it's that every iOS developer hits the same wall on day one: Rokid's documented transports are BLE GATT, classic Bluetooth SPP, and Wi-Fi Direct. On iOS, classic SPP needs MFi, Wi-Fi Direct doesn't exist, and plain BLE GATT is far too slow to move camera frames. So people give up before they build anything.
RokidLink solves that once, so the next person can start at their actual idea.
Design
RokidLink does not depend on Rokid's CXR-M SDK. It ships its own glasses-side app and speaks a documented JSON protocol over transports that iOS actually supports. Everything here is open source and inspectable.
```
┌──────────────┐                          ┌──────────────┐
│   iPhone     │   WebSocket (hotspot)    │   Glasses    │
│  Your app    │ ◄──────────────────────► │  companion   │
│      ↓       │        or                │     APK      │
│  RokidLink   │   BLE L2CAP (fallback)   │              │
└──────────────┘                          └──────────────┘
```
Primary transport — Wi-Fi. Turn on iPhone Personal Hotspot. The glasses join it, which they need anyway to reach any cloud API. Both devices land on the same subnet and talk over a local WebSocket. Full bandwidth, no MFi, no pairing dance.
Fallback transport — BLE L2CAP. When there's no hotspot, `CBL2CAPChannel` on iOS and `createL2capChannel` on Android give a real stream socket over BLE. A 50 KB compressed JPEG crosses in a second or two. Not live video, but enough for capture → analyse → HUD.
Your app writes to one API; RokidLink picks the transport.
API sketch
```swift
import RokidLink

let link = RokidLink()
try await link.connect()

let photo = try await link.capturePhoto()
try await link.showOnHUD("Merhaba dünya")

for await event in link.events {
    if case .touchpadTap = event { /* ... */ }
}
```
Repo layout
Path	What's in it
`Sources/RokidLink/`	The Swift package
`docs/ARCHITECTURE.md`	Transport design and the constraints behind it
`docs/PROTOCOL.md`	Wire protocol — implement this to write your own client
`glasses-app/`	Glasses-side Android companion (to be built)
Roadmap
[x] Protocol definition
[x] Swift API surface
[ ] Wi-Fi transport (WebSocket) — in progress
[ ] Glasses-side companion APK
[ ] Photo capture end to end
[ ] HUD text rendering with the 480×400 monochrome constraints
[ ] Audio streaming
[ ] BLE L2CAP fallback
[ ] Example app: live camera translation
Hardware
Developed against Rokid Glasses (YodaOS-Sprite, Android 12 base, monochrome green Micro-LED HUD). Untested on Glass3 / RV101 — reports welcome.
Contributing
Early enough that the protocol itself is still open to change. If you're building an iOS app for Rokid glasses and something here doesn't fit your use case, open an issue before you work around it.
License
MIT — see LICENSE.
