# Hardware-notch floating capsule

Base: official tag `v3.5`, commit `475f30966c80b8f4a984cf12c1475f7fa7153fd6` (`Update 3.5` by Shariq Charolia). Fork `main` is 35 commits ahead of that tag. This change does not include those commits and does not rewrite remote history.

## Problem

On a built-in hardware-notch MacBook, Sapphire's closed and live-activity shapes are flush with the top of the screen. The weather status in the attached screenshot is that shape: a black rounded panel whose top edge is the screen edge, covering the camera housing.

`ResolvedNotchConfiguration` sets `isFloatingIsland` only when the display has no hardware notch. `DisplaySettingsView` hides the floating-island controls on a hardware notch. The existing floating inset is only the user's extra offset (default 3pt) and ignores the safe area. Removing that gate alone would turn the notchless default (`floatingIslandOnNotchlessDisplays = true`) on for the built-in display and would draw the capsule through the camera.

## Desired behavior

Opt-in, per display, default off. While off, a hardware-notch display keeps today's attached notch, content, and hover settings.

While on, that display uses the existing floating-island capsule:

- Idle size comes from the measured menu-bar / safe-area height (`height + 2`, width `height * 3.5`, minimum height 30), not from a fixed 59 by 40 point rectangle and not from the camera width.
- The top of the idle capsule, the expanded panel, and the hover hit rectangle sit `safeAreaTop + userOffset` below the screen top. `safeAreaTop` is the runtime value already stored as `menuBarHeight` for a hardware notch. `userOffset` is the existing per-display island offset (default 3pt) and is extra space below the safe area.
- Hover opens Sapphire's own widget panel through the existing Expand on Hover path (same delay, 0.12s leave grace, 0.3s expanded leave grace, pin). This is part of the opt-in only. Notchless displays and an attached hardware notch still follow the global `expandOnHover` setting, which stays default off.
- Pointer leave collapses unless the panel is pinned. Upward hover and collapse margins are cut off at the capsule top so the camera housing is not a hover target. Sideways and downward margins stay as they are.
- Notchless and external displays keep today's floating-island default, inset, and hover behavior. Their opt-in flag is ignored.

This is Sapphire's window, not a macOS menu bar.

## Double notch

The physical camera housing does not move and cannot be painted away. macOS still reserves it. With the opt-in on, that black housing remains at the top of the screen and Sapphire's black capsule floats underneath it. You see two stacked dark shapes. That is expected. The gap between them is the safe area plus the extra offset, so the capsule does not cover the camera.

## Decision, not a deleted condition

```text
floating = hardware notch ? per-display opt-in (default false)
                          : existing notchless floating choice (default true)
```

The notchless choice is a different setting from the hardware opt-in. Apply to All from a notchless display does not turn the hardware capsule on.

## Placement

`topInset` already shifts the flipped stage band down and shifts the hover rectangle down with it. The outline grows downward from the top of that band, so a taller open panel keeps the same top. The host window stays pinned to the screen top and grows taller by `topInset`; the pixels above the capsule stay clear.

Hover rectangles for the hardware capsule are clamped so their top is the capsule top. Detection (8pt), expanded stay (24pt), and collapse (60pt) margins still apply left, right, and down.

## Settings

New stored dictionary `perDisplayFloatingCapsuleBelowHardwareNotch`, missing key means false. Old settings files gain that default through the existing tolerant decoder. No schema bump. The display card for a hardware notch shows **Float Below the Hardware Notch** and, when on, the existing island offset and spacing controls. The offset label says the value is extra space below the safe area.

## Out of scope

No change to widget content, live-activity choice, signing, the installed app, or upstream `cshariq/Sapphire`. No hardcoded model-specific notch size.
