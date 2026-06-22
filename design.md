# Synthesis — Design System ("Sage")

> Living document. Source of truth: Claude Design project **"Posture IOS"**
> (`Posture - Walkthrough.dc.html`, `Posture - Hi-Fi`, `Posture - Direction`).
> Last updated 2026-06-22 — pivoted to Synthesis: app for office workers to live well.

## Identity

A calm desk companion. AirPods Pro IMU reads tiny head movements; the app reflects your
alignment as one of three live states via a plant mascot that mirrors your posture. Nudges
gently — quietly by default, loudly only when you ignore it. Plus water (litres), walk (steps),
and sunlight (daylight-aware). Fully on-device. No account, no backend.

Tone: warm, sage, unalarming. Invite, don't scold. The loud moment is rare.

## Principles

- Calm by default. Quiet Dynamic Island + AirPods chime is the primary nudge; the banner is
  the only loud moment and must stay rare.
- Status without alarm: state word + matching colour change together (plant, word, tint).
  Never a full-screen red flash.
- Never show stale data. If the IMU stream drops, replace the screen with Disconnected.
- One plant mascot, three poses. Posture is data: the plant bends with the live angle.
- Motion matches mood: soft springs on pose/state changes, calm numbers.

## Color (Sage — light)

| Token | Hex | Use |
| --- | --- | --- |
| `bg` | `#F4F2EC` | app background |
| `surface` | `#FBFAF6` | cards / raised surfaces |
| `ink` | `#2A2A26` | primary text + icon stroke |
| `ink.soft` | `#6F685E` | secondary text |
| `ink.faint` | `#9A9183` | tertiary / captions |
| `accent` | `#4F8A7B` | the one accent (teal) — selection, CTAs, water |
| `state.aligned` | `#5F9A78` | sage green — good posture |
| `state.drift` | `#CC8A5A` | clay/ochre — past threshold |
| `state.slouch` | `#B05A38` | terracotta — sustained slouch |

State colours appear as the plant stroke + state word, with soft tints on surfaces.
Max one accent (teal). Dark warm mode — later.

## Typography

SF Pro / system (`system-ui`). The wireframe uses Kalam (hand-sketch) only as a wireframe
convention — ship with SF Pro.

- Hero / numbers: semibold, slightly tight tracking, monospaced digits.
- Body / labels: regular, `ink.soft`.
- Scale: caption 12 · body 15 · title 20 · large 27 · hero 40.

## The plant mascot (core asset)

Procedural SwiftUI Canvas — zero image assets. Each plant maps `bend` (0=aligned, 1=slouch)
to its own visual: stem tilts, leaves/petals droop, color warms sage→clay→terracotta.

Three plants (user-selectable in Settings → Plant mascot):

- **Sunflower** 🌻 — stem + round head + petals. Head bows forward as you slouch.
- **Cactus** 🌵 — rounded body + arms. Body leans, arms sag with bend.
- **Monstera** 🪴 — stem + split leaves. Leaves droop forward as bend grows.

Each plant: `bend=0` = tall/happy (sage), `bend=1` = drooped/warm (terracotta).
Spring between poses (response 0.5, bounce 0.2). Reduced Motion drops the animation.

## Motion

| Token | Value | Use |
| --- | --- | --- |
| `ui.spring` | response 0.35, bounce 0.15 | cards, controls |
| `pose.spring` | response 0.5, bounce 0.2 | state/pose changes |
| press | `scale 0.97`, 140ms ease-out | any pressable |
| fade / tint | 200–250ms ease-out | crossfades, state tint |
| calibrate ring | 5s linear sweep | baseline countdown |

State changes spring the plant + crossfade the colour. Reduced Motion keeps fades + colour,
drops the plant animation.

## Posture model

Sensing: **AirPods Pro IMU** via `CMHeadphoneMotionManager`, angle vs a calibrated baseline.
On-device only.

Three live states, driven by the engine off the smoothed forward angle:

| State | Condition | Colour | Copy example |
| --- | --- | --- | --- |
| `aligned` | within threshold | `state.aligned` | "Aligned · head & neck look good" |
| `drift` | past sensitivity threshold | `state.drift` | "Easing forward · −11° · 2 min" |
| `slouch` | deep + sustained | `state.slouch` | "Slouching · −19° · 6 min" |

**Sensitivity** (Settings, segmented): Relaxed 22° · Balanced 15° · Strict 8°.
**Calibration**: 5-second still hold captures the baseline; re-runnable from Settings.

## Water

Target: daily litres (default 2.0L, adjustable 1.0–4.0L in Settings). One tap = 250ml glass.
Now chip shows `"1.0L / 2.0L"` with a teal progress ring. Reminder: "Stay hydrated — grab a
glass of water" at configurable intervals.

## Walk

Target: daily steps (default 8000, adjustable 2000–15000 in Settings). Reads from **HealthKit**
(`HKQuantityType.stepCount`). Now chip shows `"2.1k"` with a clay progress ring. Walk nudge
fires at the interval boundary only when behind pace — skips if you're already on track.
Simulator: step count = 0, falls back to interval mode.

## Sunlight

Daylight-aware nudge using **CoreLocation** (one-shot) + NOAA sunrise/sunset formula. Schedules
two local notifications: mid-morning (~2h after sunrise) and mid-afternoon (~2h before sunset).
"Catch some sunlight — step near a window for a few minutes." Toggle in Settings.
Simulator: uses default latitude (SF 37.77°N).

## Nudges

- **Quiet nudge (default):** Dynamic Island Live Activity goes clay + a soft AirPods chime,
  on Drifting/Slouch while backgrounded. (Deferred — needs WidgetKit extension target.)
- **Escalation banner:** local notification, gated by Settings "Escalate" toggle + ~6 min
  sustained Slouch. The only loud moment — chime + haptic, tap deep-links to Home.

## Navigation & screens

Root = tab bar: **Now · Trends · Settings**. Onboarding gates the first run; nudges +
Disconnected appear over any screen.

### Onboarding (first run, linear, each step gates the next)

1. **Connect AirPods** — "Use the AirPods already in your ears."
2. **Permissions** — Motion & Fitness (required), Notifications, Apple Health (optional).
3. **Calibrate baseline** — 5s countdown ring → auto-advance to Home.

### Now (Home, hero)

Connection chip. Plant mascot mirrors live posture. State word + colour + sub-copy.
`42 min upright` streak. Three secondary chips: water (litres + teal ring), walk (steps +
clay ring), sunlight (next nudge time). Tab bar at bottom.

### Trends (read-only history)

Three KPIs (upright %, nudges, best run). Day timeline = stacked bar per hour
(up/drift/slouch) with legend. "Earlier this week" list scrolls below.

### Settings (the knobs)

AirPods row · Nudge style (segmented) · Escalate toggle · Slouch sensitivity (segmented) ·
Plant mascot picker · Water target (slider, litres) · Walk target (slider, steps) ·
Sunlight nudges (toggle) · Recalibrate baseline.

### Disconnected (critical, replaces any screen)

Warning triangle (clay). "AirPods not connected." CTA "Open Bluetooth settings".
"waiting for AirPods…" pulse. Auto-dismiss + restore on reconnect.

## Simulator harness

All simulator-only code lives in `Sources/SimulatorSupport/` — `SimulatedMotionSource` +
floating `SimulatorOverlay` (collapsed SIM chip, expands to presets + pitch slider +
connection toggle). Visible on ALL screens including onboarding + disconnected. Doesn't
shift app layout. Delete the folder + strip `#if targetEnvironment(simulator)` guards to
ship production.

## Evolve later

Dark warm mode · Dynamic Island Live Activity quiet nudge (needs WidgetKit extension) ·
streaks · haptic personality · Apple Watch companion.
