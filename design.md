# Posture App — Design System

> Living document. Built to evolve from posture → water → movement → lifestyle.
> Last updated 2026-06-21.

## Identity

A hand-drawn stickman that mirrors your posture. Warm, minimal, human — a wellness
companion, not a dashboard. The stickman IS you: sit tall, it sits tall; slouch,
it slouches. You straighten up so you don't leave it hunched.

## Principles (Emil Kowalski–derived)

- Unseen details compound; aim for invisible correctness.
- Motion matches mood: cozy = soft springs, not snappy.
- Never animate from nothing (`scale 0.96 → 1` + fade, never `scale 0`).
- Don't animate what's seen constantly (the live pitch number stays calm).
- Status without alarm: pose + warm tint, never a jarring red flash.
- Reduced Motion: keep fades/color, drop movement + boil.

## The Stickman (core asset)

Procedural SwiftUI `Canvas` — zero image assets. A skeleton of normalized joint
points (head, neck, shoulders, elbows, hands, spine base, hips, knees, feet);
joint angles drive every pose.

- **Hand-drawn look:** each bone stroked with a *seeded* wobble (small deterministic
  offset on path midpoints), rounded caps, slightly variable width, charcoal ink.
  Seed is stable per pose so it doesn't jitter every frame unless we want it to.
- **"Boil":** cycle 2–3 wobble seeds at ~5 fps to mimic hand-drawn animation life.
  Subtle. Off under Reduced Motion.
- **Pose = data.** Live filtered pitch → head-forward + spine-curve:
  - `good`: spine straight, head stacked
  - `warning`: slight forward head, gentle thoracic curve
  - `poor`: hunched, head down/forward, shoulders rolled
  - named event poses: `sip` (arm + mug), `walk` (stride), `sleep` (lying + "z"),
    `stretch` (later)
- **Pose interpolation:** spring between joint angles (response 0.5, bounce 0.2).
- **Live mirror:** during an active session, head/spine continuously track the
  smoothed pitch — the stickman is a real-time reflection.

## Color (warm minimal — light)

| Token | Hex | Use |
| --- | --- | --- |
| `bg.canvas` | `#F4EEE2` | app background (warm cream) |
| `bg.surface` | `#FBF7EF` | cards / raised surfaces |
| `ink` | `#2E2A25` | primary text + stickman stroke (charcoal) |
| `ink.soft` | `#6B6457` | secondary text |
| `accent.honey` | `#E0A33E` | the one accent |
| `status.good` | `#7C9A6B` | warm sage |
| `status.warn` | `#D8973C` | ochre |
| `status.poor` | `#C96F53` | clay |

Status colors appear as subtle tints (12–20% over bg); full saturation only on
tiny indicators. No full-screen alarm. **Max one accent** (honey). Dark mode
(warm brown-black) — later.

## Typography

SF Pro **Rounded** (system `.rounded`) — warm, friendly, native.

- Hero / numbers: rounded semibold, tracking slightly tight, **monospaced digits**.
- Body / labels: rounded regular, `ink.soft`.
- Scale: caption 12 · body 15 · title 20 · large 28 · hero 40.

## Motion

| Token | Value | Use |
| --- | --- | --- |
| `ui.spring` | response 0.35, bounce 0.15 | cards, controls |
| `mascot.spring` | response 0.5, bounce 0.2 | pose changes |
| press | `scale 0.97`, 140ms ease-out | any pressable |
| fade / tint | 200–250ms ease-out | crossfades, status tint |
| reveal | stagger 40–60ms | lists, tab content |
| breathing | `scale 1.0 ↔ 1.015` + tiny bob, ~4s ease-in-out loop | stickman alive |

Pose changes spring the joint angles (never `scale 0`). Reduced Motion drops
breathing / boil / bob / movement; keeps fades + color.

## Screens

### Today (home / hero)

Warm greeting + date (left-aligned). Stickman hero with asymmetric whitespace,
mirroring live posture; naps when AirPods are out. Kind status copy
("Sitting tall" / "Ease your neck") — no shouting numbers. Habit row of soft
cards/rings: Posture (today's score + time), Water (count + ring), Walk
(coming / locked). Gentle start/end control. Empty state: stickman naps,
"Pop your AirPods in to begin."

### History

Warm session cards with a warm-tinted score badge. Detail: pitch-over-time chart
drawn in the same hand-drawn ink stroke — honey under good zones, clay over poor.

### Settings

Grouped warm form. Posture thresholds, water interval. Respects Reduced Motion.

### Nudges (notifications)

Gentle copy; later a stickman pose thumbnail. Posture nudge + water nudge.

## Lifestyle expansion (room to evolve)

A habit is a module: `{ id, pose, ringMetric, reminderRule }`. The Today hub
renders a list of habit modules. Adding a new habit (walk, stretch, breathe,
eye-rest) = add a module + one stickman pose. No redesign needed.

- **Water** (phase 1): tap to log → ring fills → stickman sips on reminder.
- **Walk + HealthKit** (phase 2): step ring → stickman walks.

## Evolve later

Dark warm mode · streaks / accessories · richer rig (Rive) only if procedural
ever falls short · haptics + sound personality.
