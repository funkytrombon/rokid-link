# Architecture

## The constraint that shapes everything

Rokid's documented device transports are BLE GATT, classic Bluetooth socket, and Wi-Fi Direct. On iOS:

- **Classic Bluetooth SPP** requires the ExternalAccessory framework and MFi certification. Not available to an independent developer.
- **Wi-Fi Direct** has no iOS equivalent.
- **BLE GATT** works, but characteristic-based transfer tops out low enough that moving a compressed photo takes tens of seconds.

So the naive port of an Android companion app to iOS doesn't work. RokidLink routes around it instead.

## Wi-Fi over Personal Hotspot

The glasses have no SIM. To reach any cloud model they need the phone's connection regardless. So Personal Hotspot isn't an extra burden — it's a step the user was going to take anyway, and it happens to put both devices on one subnet.

On an iPhone hotspot the phone is `172.20.10.1` and clients get `172.20.10.x`. Traffic between them stays local and doesn't consume mobile data; only the model API calls do.

Caveats we've hit:

- The app cannot enable Hotspot programmatically on iOS. Onboarding has to walk the user through it once; the glasses remember the SSID afterwards.
- `NSLocalNetworkUsageDescription` and `NSBonjourServices` must be in Info.plist. Without them iOS blocks the socket with no error.
- Keep an audio session active so the app survives backgrounding. An assistant app needs audio output anyway, so this costs nothing.
- Hotspot plus continuous Wi-Fi drains the glasses' 210 mAh battery fast, and both devices get warm. Measure this before designing around always-on streaming.

## BLE L2CAP fallback

When there's no hotspot, `CBL2CAPChannel` (iOS) and `BluetoothDevice.createL2capChannel` (Android 10+) open a connection-oriented stream channel over BLE. This is a genuine socket, not GATT characteristics — a 40–60 KB JPEG crosses in one to two seconds.

Not enough for live video. Plenty for capture → analyse → HUD, which is the interaction most glasses apps actually need.

## Why not CXR-M?

Rokid documents CXR-M as supporting Android and iOS mobile companions. In practice the quick start, the Maven distribution, and the sample code are Android-only, and the iOS artifact's availability is unclear.

Even if it exists, it's a closed binary in a stack where the community keeps needing to reverse-engineer things. Shipping our own glasses-side app costs one Kotlin file and removes the dependency entirely. Everything in RokidLink is source you can read.

The tradeoff: users must install our companion APK on the glasses. Given that sideloading is already the normal way to install anything on this device, that's acceptable.

## Layering

```
        your app
            │
      RokidLink (public API)
            │
     Transport (protocol)
       ╱          ╲
WiFiTransport   BLETransport
```

`Transport` is a protocol with four requirements: connect, disconnect, send, and an event stream. Adding a transport means conforming to it — nothing above changes. `RokidLink` probes Wi-Fi first and falls back automatically.

## HUD constraints

The display is monochrome green Micro-LED, roughly 480×400 per eye, narrow field of view. Practical limits:

- ~25 characters per line, 4–5 lines at once
- No colour coding — hierarchy has to come from position and brevity
- Transient beats persistent: show for a few seconds, then clear

Any app that pushes translated sentences to this display needs a formatter that segments text to fit. That belongs in the app, not the library, but the library's `hud.show` refuses oversized payloads so the problem surfaces early.
