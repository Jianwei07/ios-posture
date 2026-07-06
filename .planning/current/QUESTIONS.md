# Open Questions

## Session 14
1. "Respect Focus & Do Not Disturb" toggle (board section 03): UNNotification banners already respect Focus; no public macOS API to gate NSSound chime on Focus state (INFocusStatusCenter needs communication entitlement). Toggle omitted from Settings this session — revisit if entitlement added.
2. Banner default: board says notification banner "opt-in · off by default"; existing `escalateLongSlouches` default is `true` and live stores have it set. Kept existing default to avoid silently changing behavior — flip default only with user sign-off.
3. Walk card shows step counts in board (2.1k/4k); macOS has no HealthKit steps — popover walk card uses interval countdown ring instead. Steps return when iOS relaunch lands.
