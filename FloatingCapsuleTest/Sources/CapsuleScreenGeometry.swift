//
//  CapsuleScreenGeometry.swift
//  FloatingCapsuleTest
//
//  Places the prototype where Sapphire's own notch sits: top center, covering the
//  live camera cutout. The physical camera is not moved. Bottom rounding is only
//  below that reserved area. Part of Sapphire, AGPL-3.0.
//

import Foundation

struct CapsulePlacement: Equatable {
    var topInset: Double
    var closedWidth: Double
    var closedHeight: Double
    var expandedWidth: Double
    var expandedHeight: Double
    var reservedWidth: Double
    var reservedHeight: Double
    var bottomCornerRadius: Double
    var hasHardwareNotch: Bool

    func windowFrame(expanded: Bool, screenMidX: Double, screenMaxY: Double) -> CapsuleWindowFrame {
        let width = expanded ? expandedWidth : closedWidth
        let height = expanded ? expandedHeight : closedHeight
        return CapsuleWindowFrame(
            x: screenMidX - width / 2,
            y: screenMaxY - topInset - height,
            width: width,
            height: height
        )
    }

    /// Flipped window coordinates, origin at the top. The window is the visible shape.
    func hitRect(expanded: Bool) -> CapsuleWindowFrame {
        CapsuleWindowFrame(
            x: 0,
            y: 0,
            width: expanded ? expandedWidth : closedWidth,
            height: expanded ? expandedHeight : closedHeight
        )
    }

    /// AppKit coordinates, origin at the bottom. The reserved notch is centered on the screen top.
    func reservedFrame(screenMidX: Double, screenMaxY: Double) -> CapsuleWindowFrame {
        CapsuleWindowFrame(
            x: screenMidX - reservedWidth / 2,
            y: screenMaxY - topInset - reservedHeight,
            width: reservedWidth,
            height: reservedHeight
        )
    }
}

struct CapsuleWindowFrame: Equatable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    var maxX: Double { x + width }
    var maxY: Double { y + height }
    var midX: Double { x + width / 2 }

    func contains(x pointX: Double, y pointY: Double) -> Bool {
        pointX >= x && pointX < x + width && pointY >= y && pointY < y + height
    }

    func covers(_ other: CapsuleWindowFrame) -> Bool {
        other.width >= 0 && other.height >= 0
            && other.x >= x - 0.001 && other.maxX <= maxX + 0.001
            && other.y >= y - 0.001 && other.maxY <= maxY + 0.001
    }
}

enum CapsuleScreenGeometry {
    /// Sapphire's closed notch is the camera width plus this padding.
    static let notchWidthPadding: Double = 4
    /// Sapphire's attached corner radius. Drawn below the reserved band so the cutout stays covered.
    static let bottomCornerRadius: Double = 10
    static let expandedPanelHeight: Double = 168
    static let notchlessWidthPerBarHeight: Double = 6.25
    /// `NSWindow.Level.statusBar`. Sapphire's notch window was measured at this level.
    static let statusBarWindowLevel: Int = 25

    static func cameraWidth(leftMaxX: Double?, rightMinX: Double?) -> Double? {
        guard let leftMaxX, let rightMinX else { return nil }
        let width = rightMinX - leftMaxX
        return width.isFinite && width > 0 ? width : nil
    }

    static func hasHardwareNotch(safeAreaTop: Double, leftMaxX: Double?, rightMinX: Double?) -> Bool {
        safeAreaTop > 0 && cameraWidth(leftMaxX: leftMaxX, rightMinX: rightMinX) != nil
    }

    static func placement(
        safeAreaTop: Double,
        menuBarHeight: Double,
        cameraWidth: Double?,
        scale: Double
    ) -> CapsulePlacement {
        let notch = safeAreaTop > 0 && cameraWidth != nil
        let reservedHeight = notch ? max(0, safeAreaTop) : max(0, menuBarHeight)
        let reservedWidth = notch ? max(0, cameraWidth ?? 0) : 0
        let radius = notch ? bottomCornerRadius : bottomCornerRadius
        let closedHeight = ceilToPixel(reservedHeight + radius, scale: scale)
        let rawWidth = notch
            ? reservedWidth + notchWidthPadding
            : max(reservedHeight, 1) * notchlessWidthPerBarHeight
        let closedWidth = ceilToEvenPixels(max(rawWidth, reservedWidth), scale: scale)
        let expandedHeight = ceilToPixel(max(expandedPanelHeight, closedHeight), scale: scale)
        let expandedWidth = ceilToEvenPixels(max(closedWidth * 2.4, 320), scale: scale)
        return CapsulePlacement(
            topInset: 0,
            closedWidth: closedWidth,
            closedHeight: closedHeight,
            expandedWidth: expandedWidth,
            expandedHeight: expandedHeight,
            reservedWidth: notch ? reservedWidth : closedWidth,
            reservedHeight: reservedHeight,
            bottomCornerRadius: radius,
            hasHardwareNotch: notch
        )
    }

    static func ceilToPixel(_ value: Double, scale: Double) -> Double {
        guard value.isFinite, scale > 0 else { return value }
        return (value * scale).rounded(.up) / scale
    }

    static func ceilToEvenPixels(_ value: Double, scale: Double) -> Double {
        guard value.isFinite, scale > 0 else { return value }
        return (value * scale / 2).rounded(.up) * 2 / scale
    }
}
