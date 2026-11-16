//
//  CapsuleScreenGeometry.swift
//  FloatingCapsuleTest
//
//  Places the prototype with the same safe-area math as Sapphire's floating capsule.
//  Part of Sapphire, AGPL-3.0.
//

import Foundation

struct CapsulePlacement: Equatable {
    var topInset: Double
    var closedWidth: Double
    var closedHeight: Double
    var expandedWidth: Double
    var expandedHeight: Double
    var hasHardwareNotch: Bool

    func windowFrame(screenMidX: Double, screenMaxY: Double) -> CapsuleWindowFrame {
        let height = expandedHeight
        let width = expandedWidth
        return CapsuleWindowFrame(
            x: screenMidX - width / 2,
            y: screenMaxY - topInset - height,
            width: width,
            height: height
        )
    }

    /// Flipped window coordinates, origin at the top. The collapsed hit area is only the idle capsule.
    func hitRect(expanded: Bool) -> CapsuleWindowFrame {
        CapsuleWindowFrame(
            x: (expandedWidth - (expanded ? expandedWidth : closedWidth)) / 2,
            y: 0,
            width: expanded ? expandedWidth : closedWidth,
            height: expanded ? expandedHeight : closedHeight
        )
    }
}

struct CapsuleWindowFrame: Equatable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    var maxY: Double { y + height }
    var midX: Double { x + width / 2 }

    func contains(x pointX: Double, y pointY: Double) -> Bool {
        pointX >= x && pointX < x + width && pointY >= y && pointY < y + height
    }
}

enum CapsuleScreenGeometry {
    static let extraGap: Double = 3
    static let minimumCapsuleHeight: Double = 30
    static let expandedPanelHeight: Double = 168

    static func hasHardwareNotch(safeAreaTop: Double, leftMaxX: Double?, rightMinX: Double?) -> Bool {
        guard safeAreaTop > 0, let leftMaxX, let rightMinX else { return false }
        let cutout = rightMinX - leftMaxX
        return cutout.isFinite && cutout > 0
    }

    static func placement(
        safeAreaTop: Double,
        menuBarHeight: Double,
        hasHardwareNotch: Bool,
        scale: Double
    ) -> CapsulePlacement {
        let bar = hasHardwareNotch ? safeAreaTop : menuBarHeight
        let closed = NotchFloatingCapsule.closedSize(
            menuBarHeight: bar,
            customWidth: 0,
            customHeight: 0,
            scale: scale,
            minimumHeight: minimumCapsuleHeight
        )
        let inset = NotchFloatingCapsule.topInset(
            userOffset: extraGap,
            safeAreaTop: safeAreaTop,
            hasHardwareNotch: hasHardwareNotch,
            scale: scale
        )
        let expandedHeight = NotchFloatingCapsule.snapToPixel(expandedPanelHeight, scale: scale)
        let expandedWidth = NotchFloatingCapsule.snapToEvenPixels(max(closed.width * 2.4, 320), scale: scale)
        return CapsulePlacement(
            topInset: inset,
            closedWidth: closed.width,
            closedHeight: closed.height,
            expandedWidth: expandedWidth,
            expandedHeight: expandedHeight,
            hasHardwareNotch: hasHardwareNotch
        )
    }
}
