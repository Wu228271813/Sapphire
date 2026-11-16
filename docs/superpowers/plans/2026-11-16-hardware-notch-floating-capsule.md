# Hardware-notch floating capsule implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an opt-in compact capsule that floats below a built-in hardware notch, clearing the runtime safe area, without changing notchless displays or the attached-notch default.

**Architecture:** Pure placement and hover decisions live in `NotchFloatingCapsule` (no AppKit). `ResolvedNotchConfiguration`, `NotchDisplayMetrics`, `NotchController`, and `DisplaySettingsView` call those functions. The hardware opt-in is a separate per-display setting that defaults off.

**Tech Stack:** Swift, AppKit, SwiftUI, XCTest. Linux can compile only the pure file.

## Global Constraints

- Base commit is official `v3.5` `475f30966c80b8f4a984cf12c1475f7fa7153fd6`. Do not include the 35 later `main` commits. Do not rewrite remote history.
- Default remains the attached hardware notch. Notchless `floatingIslandOnNotchlessDisplays` stays `true`.
- Do not hardcode a 59 by 40 point reserved region. Clearance is the measured safe-area height.
- Preserve hover delay, 0.12s / 0.3s leave grace, and pin. Do not change those constants.
- Preserve AGPL `LICENSE`. Do not accept an Xcode license, change signing, or install or overwrite the app.
- Pull request target is `Wu228271813/Sapphire` only.

---

### Task 1: Pure decisions

**Files:**
- Create: `Sapphire/Notch/NotchFloatingCapsule.swift`
- Create: `scripts/NotchFloatingCapsuleChecks.swift`
- Test: `SapphireTests/NotchFloatingCapsuleTests.swift`

**Interfaces:**
- Produces: `NotchFloatingCapsule.enablesFloatingIsland(hasHardwareNotch:notchlessFloating:hardwareNotchOptIn:) -> Bool`
- Produces: `NotchFloatingCapsule.opensPanelOnHover(expandOnHover:hardwareNotchCapsule:) -> Bool`
- Produces: `NotchFloatingCapsule.topInset(userOffset:safeAreaTop:hasHardwareNotch:scale:) -> Double`
- Produces: `NotchFloatingCapsule.closedSize(menuBarHeight:customWidth:customHeight:scale:minimumHeight:) -> (width: Double, height: Double)`
- Produces: `NotchFloatingCapsule.limitTop(_:to:) -> Rect` where `Rect.maxY` is the top edge

- [x] Write `scripts/NotchFloatingCapsuleChecks.swift` and run it. It must fail because the type is missing.
- [x] Add `NotchFloatingCapsule.swift` with the formulas below. Run the checker until it passes.
- [x] Add the same assertions to `SapphireTests/NotchFloatingCapsuleTests.swift`.

Enablement: hardware notch uses only `hardwareNotchOptIn`; notchless uses only `notchlessFloating`.

Hover panel: `expandOnHover || hardwareNotchCapsule`.

Top inset: `snap(max(0, userOffset) + (hasHardwareNotch ? max(0, safeAreaTop) : 0))`. Pixel snap is `(value * scale).rounded() / scale`. Notchless results stay 8, 0, 8.5, and 0 for the existing inputs. A 40pt safe area plus 3pt offset at scale 2 is 43. A 32.25pt safe area plus 0 at scale 2 is 32.5. A 59 by 40 input is not a special case: width is never read, and a 37.5pt safe area is not rewritten to 40.

Closed size: height is `max(customHeight > 0 ? customHeight : menuBarHeight + 2, minimumHeight)`, width is `customWidth > 0 ? customWidth : height * 3.5`, then even-pixel width and pixel height. Menu bar 29 at scale 2 is 109 by 31. Menu bar 40 at scale 2 is 147 by 42, not 59 by 40.

`limitTop` lowers `maxY` to the ceiling and keeps `minY`. A rect already under the ceiling is unchanged.

### Task 2: Wire geometry

**Files:**
- Modify: `Sapphire/Notch/NotchDisplayMetrics.swift`
- Modify: `Sapphire/Notch/NotchConfiguration.swift`
- Modify: `Sapphire/Models/SettingsModel.swift`
- Modify: `Sapphire/Models/SettingsFields+Generated.swift`
- Test: `SapphireTests/NotchDisplayMetricsTests.swift`

- [x] Add `perDisplayFloatingCapsuleBelowHardwareNotch: [String: Bool] = [:]` and `resolvedFloatingCapsuleBelowHardwareNotch`, missing key returns false. Register the field.
- [x] `isFloatingIsland` calls `enablesFloatingIsland`. Do not delete the hardware check and substitute the notchless default.
- [x] `floatingIslandTopInset` keeps its current labels and adds `safeAreaTop` and `hasHardwareNotch` (both defaulted so current tests still apply). It returns `NotchFloatingCapsule.topInset`. The resolved config passes `metrics.menuBarHeight` and `metrics.hasHardwareNotch`.
- [x] `resolvedClosedSize` returns `NotchFloatingCapsule.closedSize` when `isFloatingIsland` is true, before the hardware-notch minimum can widen it. Attached notches still cannot uncover the camera.
- [x] Floating or notchless expanded shadows use the existing notchless shadow (opacity 0.5, radius 28, y 14). An attached hardware notch keeps the current shadow.
- [x] Add XCTest coverage for the safe-area inset and for a floating hardware closed size that is not the camera size.

### Task 3: Hover, hit testing, and the setting

**Files:**
- Modify: `Sapphire/Notch/NotchController.swift`
- Modify: `Sapphire/App Settings/DisplaySettingsView.swift`

- [x] When `opensPanelOnHover` is true, use the existing expand-on-hover branch, including its delay task. The task's later guard uses the same function. Grace constants and `isPinned` stay untouched.
- [x] After a hover, stay, or collapse margin is applied, if this display is a hardware-notch capsule, `limitTop` the rectangle to `contentMaxY - topInset`. Sideways and downward growth stays.
- [x] On a hardware notch, show **Float Below the Hardware Notch**. Copy states that the physical notch remains, so both shapes show, and that the capsule, open panel, and hover area start below the safe area. When the switch is on, show the existing offset and spacing controls. Offset copy says it is extra space below the safe area. Notchless rows stay as they are.

### Task 4: Check and publish

- [x] Run `swiftc` on the pure file plus `scripts/NotchFloatingCapsuleChecks.swift`. Record the command and result.
- [x] Do not claim an Xcode or UI pass. macOS still needs the manual checks in the pull request.
- [ ] Commit on `cursor/hardware-notch-floating-capsule-e9c2`, push to `Wu228271813/Sapphire`, and open the pull request against that fork only.
- [ ] Write a source patch under `/opt/cursor/artifacts` even if the pull request opens.
