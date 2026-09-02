# Contributing

The protocol in `docs/PROTOCOL.md` is still young enough to change. If something doesn't fit your use case, open an issue before working around it — a change here is cheaper than a fork.

## Useful contributions right now

- The glasses-side companion app (`glasses-app/`) — the biggest missing piece
- A `BLETransport` conforming to `Transport`, using `CBL2CAPChannel`
- Device reports: which Rokid models this works on, and where it breaks
- Battery and thermal measurements under sustained hotspot streaming

## Ground rules

- No dependency on closed Rokid binaries in the core package. The point of this project is that the connection layer is readable.
- The glasses stay dumb. Anything that makes a decision belongs on the phone.
- Every protocol change updates `docs/PROTOCOL.md` in the same commit.
