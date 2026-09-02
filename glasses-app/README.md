[README.md](https://github.com/user-attachments/files/31743571/README.md)
# Glasses-side companion

Not written yet. This is the piece that runs on the glasses (YodaOS-Sprite, Android 12 base) and speaks the protocol in `docs/PROTOCOL.md`.

## What it has to do

- Discover the phone via Bonjour `_rokidlink._tcp`, falling back to `172.20.10.1:8975`
- Hold a WebSocket open and reconnect when the hotspot drops
- On `photo.capture`: take a frame, downscale to `maxEdge`, compress to JPEG, send `photo.data` plus one binary frame
- On `hud.show`: render up to 5 short lines, clear after `ttlMs`
- Forward touchpad taps and swipes as `event.*`
- Report battery and Wi-Fi state as `device.status`

It makes no decisions and calls no external APIs. All of that lives on the phone.

## Building

Needs Android Studio and the Rokid Glasses SDK from `maven.rokid.com`.

Use the Glass3 data debug cable, not the charging cable. The charging cable powers the device but Android Studio will not see it, which is the most common reason setup appears broken.

## Wake phrases

`Hi Rokid` is reserved by the system. Custom offline phrases go through the SDK's offline command service.
