//
//  CapsulePrototypeTests.swift
//  FloatingCapsuleTest
//
//  Part of Sapphire, AGPL-3.0.
//

import XCTest

final class CapsulePrototypeTests: XCTestCase {
    func testHardwareNotchClearsTheLiveSafeAreaAndKeepsThatGapWhenOpen() {
        let idle = CapsuleScreenGeometry.placement(
            safeAreaTop: 40, menuBarHeight: 24, hasHardwareNotch: true, scale: 2
        )
        let open = idle
        XCTAssertEqual(idle.topInset, 43)
        XCTAssertEqual(open.topInset, idle.topInset)
        XCTAssertEqual(idle.closedHeight, 42)
        XCTAssertNotEqual(idle.closedWidth, 59)
        let frame = idle.windowFrame(screenMidX: 864, screenMaxY: 1117)
        XCTAssertEqual(frame.maxY, 1117 - idle.topInset)
        XCTAssertEqual(idle.hitRect(expanded: true).y, 0)
        XCTAssertEqual(idle.hitRect(expanded: false).height, idle.closedHeight)
        XCTAssertLessThan(idle.hitRect(expanded: false).height, idle.hitRect(expanded: true).height)
    }

    func testNotchlessDisplayDoesNotAddASafeAreaGap() {
        XCTAssertFalse(CapsuleScreenGeometry.hasHardwareNotch(safeAreaTop: 0, leftMaxX: 10, rightMinX: 40))
        XCTAssertFalse(CapsuleScreenGeometry.hasHardwareNotch(safeAreaTop: 32, leftMaxX: nil, rightMinX: 40))
        XCTAssertTrue(CapsuleScreenGeometry.hasHardwareNotch(safeAreaTop: 32, leftMaxX: 700, rightMinX: 900))
        let placement = CapsuleScreenGeometry.placement(
            safeAreaTop: 0, menuBarHeight: 24, hasHardwareNotch: false, scale: 2
        )
        XCTAssertEqual(placement.topInset, 3)
        XCTAssertFalse(placement.hasHardwareNotch)
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

    func testCollapsedHitAreaDoesNotCoverTheSafeAreaGap() {
        let placement = CapsuleScreenGeometry.placement(
            safeAreaTop: 37.5, menuBarHeight: 24, hasHardwareNotch: true, scale: 2
        )
        XCTAssertEqual(placement.topInset, 40.5)
        let window = placement.windowFrame(screenMidX: 500, screenMaxY: 1000)
        XCTAssertEqual(window.maxY, 1000 - 40.5)
        let collapsed = placement.hitRect(expanded: false)
        XCTAssertEqual(collapsed.y, 0)
        XCTAssertFalse(collapsed.contains(x: collapsed.midX, y: -1))
    }
}
