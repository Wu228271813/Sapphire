// Linux-runnable checks for NotchFloatingCapsule. The same assertions live in
// SapphireTests/NotchFloatingCapsuleTests.swift for Xcode.

import Foundation

enum Check {
    static var failures = 0

    static func equal<T: Equatable>(_ actual: T, _ expected: T, _ name: String) {
        guard actual != expected else { return }
        failures += 1
        FileHandle.standardError.write(Data("FAIL \(name)\n  actual: \(actual)\n  expected: \(expected)\n".utf8))
    }

    static func close(_ actual: Double, _ expected: Double, _ name: String) {
        guard abs(actual - expected) > 0.000_001 else { return }
        failures += 1
        FileHandle.standardError.write(Data("FAIL \(name)\n  actual: \(actual)\n  expected: \(expected)\n".utf8))
    }
}

@main
struct NotchFloatingCapsuleCheckRunner {
    static func main() {
        run()
        if Check.failures > 0 {
            fputs("\(Check.failures) failed\n", stderr)
            exit(1)
        }
        print("NotchFloatingCapsule checks passed")
    }
}

private func run() {
let notchlessOn = NotchFloatingCapsule.enablesFloatingIsland(
    hasHardwareNotch: false, notchlessFloating: true, hardwareNotchOptIn: false)
Check.equal(notchlessOn, true, "notchless default still floats")

let notchlessOff = NotchFloatingCapsule.enablesFloatingIsland(
    hasHardwareNotch: false, notchlessFloating: false, hardwareNotchOptIn: true)
Check.equal(notchlessOff, false, "hardware opt-in does not float a notchless display")

let hardwareDefault = NotchFloatingCapsule.enablesFloatingIsland(
    hasHardwareNotch: true, notchlessFloating: true, hardwareNotchOptIn: false)
Check.equal(hardwareDefault, false, "hardware notch stays attached when the notchless default is on")

let hardwareOptIn = NotchFloatingCapsule.enablesFloatingIsland(
    hasHardwareNotch: true, notchlessFloating: false, hardwareNotchOptIn: true)
Check.equal(hardwareOptIn, true, "hardware opt-in floats even if notchless floating is off")

Check.equal(
    NotchFloatingCapsule.opensPanelOnHover(expandOnHover: false, hardwareNotchCapsule: false),
    false,
    "attached notch keeps expand-on-hover off")
Check.equal(
    NotchFloatingCapsule.opensPanelOnHover(expandOnHover: true, hardwareNotchCapsule: false),
    true,
    "global expand-on-hover still opens the panel")
Check.equal(
    NotchFloatingCapsule.opensPanelOnHover(expandOnHover: false, hardwareNotchCapsule: true),
    true,
    "hardware capsule opens the panel on hover")

Check.close(NotchFloatingCapsule.topInset(userOffset: 8, safeAreaTop: 40, hasHardwareNotch: false, scale: 2), 8, "notchless offset 8")
Check.close(NotchFloatingCapsule.topInset(userOffset: 0, safeAreaTop: 37, hasHardwareNotch: false, scale: 2), 0, "notchless ignores a taller bar")
Check.close(NotchFloatingCapsule.topInset(userOffset: 8.3, safeAreaTop: 0, hasHardwareNotch: false, scale: 2), 8.5, "notchless offset snaps")
Check.close(NotchFloatingCapsule.topInset(userOffset: -4, safeAreaTop: 40, hasHardwareNotch: false, scale: 2), 0, "negative offset stays zero")

Check.close(NotchFloatingCapsule.topInset(userOffset: 3, safeAreaTop: 40, hasHardwareNotch: true, scale: 2), 43, "40pt safe area plus default offset")
Check.close(NotchFloatingCapsule.topInset(userOffset: 0, safeAreaTop: 32.25, hasHardwareNotch: true, scale: 2), 32.5, "fractional safe area snaps")
Check.close(NotchFloatingCapsule.topInset(userOffset: 3, safeAreaTop: 37.5, hasHardwareNotch: true, scale: 2), 40.5, "37.5pt safe area is not rewritten to 40")
Check.close(NotchFloatingCapsule.topInset(userOffset: 0, safeAreaTop: 59, hasHardwareNotch: true, scale: 2), 59, "59 is a measured input, not a reserved width")

let compact = NotchFloatingCapsule.closedSize(menuBarHeight: 29, customWidth: 0, customHeight: 0, scale: 2, minimumHeight: 30)
Check.close(compact.width, 109, "existing island width")
Check.close(compact.height, 31, "existing island height")

let belowCamera = NotchFloatingCapsule.closedSize(menuBarHeight: 40, customWidth: 0, customHeight: 0, scale: 2, minimumHeight: 30)
Check.close(belowCamera.width, 147, "safe area 40 does not become width 59")
Check.close(belowCamera.height, 42, "safe area 40 becomes height 42, not 40")

let custom = NotchFloatingCapsule.closedSize(menuBarHeight: 40, customWidth: 100, customHeight: 36, scale: 2, minimumHeight: 30)
Check.close(custom.width, 100, "custom width is not raised to the camera width")
Check.close(custom.height, 36, "custom height is kept")

let idleInset = NotchFloatingCapsule.topInset(userOffset: 3, safeAreaTop: 40, hasHardwareNotch: true, scale: 2)
let openInset = NotchFloatingCapsule.topInset(userOffset: 3, safeAreaTop: 40, hasHardwareNotch: true, scale: 2)
Check.close(idleInset, openInset, "expanded panel uses the idle top inset")

let stage = NotchFloatingCapsule.Rect(x: 100, y: 0, width: 800, height: 500)
let hovered = NotchFloatingCapsule.Rect(x: stage.midX - 70, y: stage.maxY - idleInset - 80, width: 140, height: 80)
    .insetBy(dx: -60, dy: -60)
let capped = NotchFloatingCapsule.limitTop(hovered, to: stage.maxY - idleInset)
Check.close(capped.maxY, stage.maxY - idleInset, "collapse margin cannot enter the safe area")
Check.close(capped.y, hovered.y, "downward edge stays")
Check.close(capped.x, hovered.x, "sideways margin stays")
Check.close(capped.width, hovered.width, "width stays")

let alreadyClear = NotchFloatingCapsule.Rect(x: 10, y: 10, width: 20, height: 20)
let unchanged = NotchFloatingCapsule.limitTop(alreadyClear, to: 40)
Check.equal(unchanged, alreadyClear, "rect under the ceiling is unchanged")

Check.equal(
    SapphireLocalIsolation.supportDirectoryName(forBundleIdentifier: "com.cshariq.sapphire"),
    "Sapphire",
    "shipping bundle keeps Application Support/Sapphire")
Check.equal(
    SapphireLocalIsolation.skipsPrivilegedRegistration(forBundleIdentifier: "com.cshariq.sapphire"),
    false,
    "shipping bundle can still register its helper")
Check.equal(
    SapphireLocalIsolation.supportDirectoryName(forBundleIdentifier: nil),
    "Sapphire",
    "missing bundle id keeps the production folder")
Check.equal(
    SapphireLocalIsolation.supportDirectoryName(forBundleIdentifier: SapphireLocalIsolation.localUITestBundleIdentifier),
    "SapphireFloatingCapsuleTest",
    "local UI test bundle uses its own support folder")
Check.equal(
    SapphireLocalIsolation.skipsPrivilegedRegistration(forBundleIdentifier: SapphireLocalIsolation.localUITestBundleIdentifier),
    true,
    "local UI test bundle does not register the helper or a login item")
Check.equal(
    SapphireLocalIsolation.faceIDKeychainService(forBundleIdentifier: "com.cshariq.sapphire"),
    "com.shariq.Sapphire.faceid.keychain",
    "shipping bundle keeps the Face ID keychain service")
Check.equal(
    SapphireLocalIsolation.faceIDKeychainService(forBundleIdentifier: SapphireLocalIsolation.localUITestBundleIdentifier),
    "com.local.sapphire.floatingcapsule.test.faceid.keychain",
    "local UI test bundle uses its own Face ID keychain service")

let hardware = CapsuleScreenGeometry.placement(
    safeAreaTop: 40, menuBarHeight: 24, hasHardwareNotch: true, scale: 2)
Check.close(hardware.topInset, 43, "prototype gap is safe area plus 3 pt")
Check.close(hardware.closedHeight, 42, "prototype idle height follows the safe area")
Check.equal(hardware.closedWidth == 59, false, "prototype width is not a fixed 59 pt")
let window = hardware.windowFrame(screenMidX: 864, screenMaxY: 1117)
Check.close(window.maxY, 1117 - hardware.topInset, "open panel keeps the same top gap")
Check.close(hardware.hitRect(expanded: false).height, hardware.closedHeight, "collapsed hit area is the idle capsule")
Check.equal(hardware.hitRect(expanded: false).contains(x: hardware.hitRect(expanded: false).midX, y: -1), false, "collapsed hit area does not cover the gap above the capsule")

let plain = CapsuleScreenGeometry.placement(
    safeAreaTop: 0, menuBarHeight: 24, hasHardwareNotch: false, scale: 2)
Check.close(plain.topInset, 3, "notchless prototype uses only the extra gap")
Check.equal(CapsuleScreenGeometry.hasHardwareNotch(safeAreaTop: 32, leftMaxX: 700, rightMinX: 900), true, "a cutout between the menu areas is a hardware notch")
Check.equal(CapsuleScreenGeometry.hasHardwareNotch(safeAreaTop: 32, leftMaxX: nil, rightMinX: 900), false, "a safe area without a cutout is not a hardware notch")

var interaction = CapsuleInteraction()
Check.equal(interaction.panelOpen, false, "prototype starts collapsed")
interaction.pointerEntered()
Check.equal(interaction.panelOpen, true, "hover opens the panel")
interaction.pointerExited()
Check.equal(interaction.panelOpen, false, "leave collapses the panel")
interaction.pointerEntered()
interaction.togglePinned()
interaction.pointerExited()
Check.equal(interaction.panelOpen, true, "pin keeps the panel open")
interaction.togglePinned()
Check.equal(interaction.panelOpen, false, "unpin allows collapse")
}
