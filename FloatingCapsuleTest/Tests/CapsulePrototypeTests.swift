//
//  CapsulePrototypeTests.swift
//  FloatingCapsuleTest
//
//  Part of Sapphire, AGPL-3.0.
//

import XCTest

final class CapsulePrototypeTests: XCTestCase {
    func testHardwareNotchCoversTheReservedAreaAtTheScreenTop() {
        let camera: Double = 180
        let placement = CapsuleScreenGeometry.placement(
            safeAreaTop: 40, menuBarHeight: 24, cameraWidth: camera, scale: 2
        )
        XCTAssertEqual(placement.topInset, 0)
        XCTAssertGreaterThanOrEqual(placement.closedHeight, 40)
        XCTAssertGreaterThanOrEqual(placement.closedHeight, 40 + placement.bottomCornerRadius)
        XCTAssertGreaterThanOrEqual(placement.closedWidth, camera)
        XCTAssertGreaterThanOrEqual(placement.closedWidth, camera + CapsuleScreenGeometry.notchWidthPadding)
        XCTAssertEqual(CapsuleScreenGeometry.statusBarWindowLevel, 25)
        XCTAssertNotEqual(CapsuleScreenGeometry.statusBarWindowLevel, 3)

        let screenMidX = 1512.0 / 2
        let screenMaxY = 993.0
        let collapsed = placement.windowFrame(expanded: false, screenMidX: screenMidX, screenMaxY: screenMaxY)
        let expanded = placement.windowFrame(expanded: true, screenMidX: screenMidX, screenMaxY: screenMaxY)
        XCTAssertEqual(collapsed.maxY, screenMaxY)
        XCTAssertEqual(expanded.maxY, collapsed.maxY)
        XCTAssertEqual(collapsed.midX, screenMidX)
        XCTAssertEqual(expanded.midX, screenMidX)
        XCTAssertGreaterThan(expanded.height, collapsed.height)
        XCTAssertLessThan(expanded.y, collapsed.y)
        XCTAssertTrue(collapsed.covers(placement.reservedFrame(screenMidX: screenMidX, screenMaxY: screenMaxY)))
        XCTAssertTrue(expanded.covers(collapsed))
        XCTAssertFalse(collapsed.contains(x: collapsed.midX, y: screenMaxY + 0.1))
        XCTAssertEqual(placement.hitRect(expanded: false).height, placement.closedHeight)
        XCTAssertEqual(placement.hitRect(expanded: true).y, placement.hitRect(expanded: false).y)
        XCTAssertGreaterThan(placement.hitRect(expanded: true).height, placement.hitRect(expanded: false).height)
    }

    func testNotchlessDisplaySitsInTheMenuBarBand() {
        XCTAssertFalse(CapsuleScreenGeometry.hasHardwareNotch(safeAreaTop: 0, leftMaxX: 10, rightMinX: 40))
        XCTAssertFalse(CapsuleScreenGeometry.hasHardwareNotch(safeAreaTop: 32, leftMaxX: nil, rightMinX: 40))
        XCTAssertTrue(CapsuleScreenGeometry.hasHardwareNotch(safeAreaTop: 32, leftMaxX: 700, rightMinX: 900))
        let placement = CapsuleScreenGeometry.placement(
            safeAreaTop: 0, menuBarHeight: 24, cameraWidth: nil, scale: 2
        )
        XCTAssertEqual(placement.topInset, 0)
        XCTAssertFalse(placement.hasHardwareNotch)
        XCTAssertGreaterThanOrEqual(placement.closedHeight, 24)
        let frame = placement.windowFrame(expanded: false, screenMidX: 756, screenMaxY: 993)
        XCTAssertEqual(frame.maxY, 993)
        XCTAssertTrue(frame.covers(placement.reservedFrame(screenMidX: 756, screenMaxY: 993)))
    }

    func testHoverOpensAndLeaveCollapsesUnlessPinned() {
        var interaction = CapsuleInteraction()
        XCTAssertFalse(interaction.panelOpen)
        interaction.pointerEntered()
        XCTAssertTrue(interaction.panelOpen)
        interaction.pointerExited()
        XCTAssertFalse(interaction.panelOpen)
        interaction.pointerEntered()
        interaction.togglePinned()
        interaction.pointerExited()
        XCTAssertTrue(interaction.panelOpen)
        interaction.togglePinned()
        XCTAssertFalse(interaction.panelOpen)
    }

    func testFractionalSafeAreaStaysCoveredWhenSnapped() {
        let placement = CapsuleScreenGeometry.placement(
            safeAreaTop: 37.5, menuBarHeight: 24, cameraWidth: 166.25, scale: 2
        )
        XCTAssertEqual(placement.topInset, 0)
        XCTAssertGreaterThanOrEqual(placement.closedHeight, 37.5)
        XCTAssertGreaterThanOrEqual(placement.closedWidth, 166.25)
        let window = placement.windowFrame(expanded: false, screenMidX: 500, screenMaxY: 1000)
        XCTAssertEqual(window.maxY, 1000)
        XCTAssertTrue(window.covers(placement.reservedFrame(screenMidX: 500, screenMaxY: 1000)))
        let collapsed = placement.hitRect(expanded: false)
        XCTAssertEqual(collapsed.y, 0)
        XCTAssertTrue(collapsed.contains(x: collapsed.midX, y: 0))
    }
}
