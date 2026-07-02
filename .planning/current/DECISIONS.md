# Decisions

## 2026-06-26 — macOS-first pivot

- Pivot to macOS first to validate AirPods posture tracking faster.
- Keep iOS and macOS in one monorepo.
- Preserve old iOS planning context in `.planning/specs-legacy-20260626/`.
- Use the current repo source layout first; defer Swift package extraction until target sharing becomes painful.
- Use Dorso as a reference for macOS AirPods detection and compact desktop UX, not as an architecture to copy wholesale.
- First macOS slice skips private `IOBluetooth`, camera fallback, screen blur, and new dependencies.
