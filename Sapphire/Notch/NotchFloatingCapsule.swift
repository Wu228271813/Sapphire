//
//  NotchFloatingCapsule.swift
//  Sapphire
//
//  Opt-in capsule below a hardware notch. The camera housing stays put;
//  these functions only decide where Sapphire's own shape and hover area sit.
//

enum NotchFloatingCapsule {
    struct Rect: Equatable {
        var x: Double
        var y: Double
        var width: Double
        var height: Double

        var maxX: Double { x + width }
        var maxY: Double { y + height }
        var midX: Double { x + width / 2 }

        func insetBy(dx: Double, dy: Double) -> Rect {
            Rect(x: x + dx, y: y + dy, width: width - 2 * dx, height: height - 2 * dy)
        }
    }

    static let heightOverBar: Double = 2
    static let widthPerHeight: Double = 3.5

    static func enablesFloatingIsland(
        hasHardwareNotch: Bool,
        notchlessFloating: Bool,
        hardwareNotchOptIn: Bool
    ) -> Bool {
        hasHardwareNotch ? hardwareNotchOptIn : notchlessFloating
    }

    static func opensPanelOnHover(expandOnHover: Bool, hardwareNotchCapsule: Bool) -> Bool {
        expandOnHover || hardwareNotchCapsule
    }

    static func snapToPixel(_ value: Double, scale: Double) -> Double {
        guard value.isFinite, scale > 0 else { return value }
        return (value * scale).rounded() / scale
    }

    static func snapToEvenPixels(_ value: Double, scale: Double) -> Double {
        guard value.isFinite, scale > 0 else { return value }
        return ((value * scale) / 2).rounded() * 2 / scale
    }

    /// Distance from the screen top to the capsule, the open panel, and the hover area.
    /// A notchless display uses only the extra offset. A hardware notch adds the measured
    /// safe-area height so the camera stays clear. No reserved width or height is assumed.
    static func topInset(
        userOffset: Double,
        safeAreaTop: Double,
        hasHardwareNotch: Bool,
        scale: Double
    ) -> Double {
        let extra = max(0, userOffset)
        let clearance = hasHardwareNotch ? max(0, safeAreaTop) : 0
        return snapToPixel(clearance + extra, scale: scale)
    }

    static func closedSize(
        menuBarHeight: Double,
        customWidth: Double,
        customHeight: Double,
        scale: Double,
        minimumHeight: Double
    ) -> (width: Double, height: Double) {
        let natural = menuBarHeight + heightOverBar
        let height = max(customHeight > 0 ? customHeight : natural, minimumHeight)
        let width = customWidth > 0 ? customWidth : height * widthPerHeight
        return (
            width: snapToEvenPixels(width, scale: scale),
            height: snapToPixel(height, scale: scale)
        )
    }

    /// Unflipped coordinates, where `maxY` is the top. Lowers the top to `maximumTop` and keeps the bottom.
    static func limitTop(_ rect: Rect, to maximumTop: Double) -> Rect {
        guard rect.maxY > maximumTop else { return rect }
        let trimmed = rect.maxY - maximumTop
        return Rect(x: rect.x, y: rect.y, width: rect.width, height: max(0, rect.height - trimmed))
    }
}
