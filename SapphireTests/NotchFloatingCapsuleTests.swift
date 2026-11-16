//
//  NotchFloatingCapsuleTests.swift
//  SapphireTests
//

import XCTest
@testable import Sapphire

final class NotchFloatingCapsuleTests: XCTestCase {
    func testNotchlessFloatingStaysIndependentOfTheHardwareOptIn() {
        XCTAssertTrue(NotchFloatingCapsule.enablesFloatingIsland(
            hasHardwareNotch: false, notchlessFloating: true, hardwareNotchOptIn: false))
        XCTAssertFalse(NotchFloatingCapsule.enablesFloatingIsland(
            hasHardwareNotch: false, notchlessFloating: false, hardwareNotchOptIn: true))
    }

    func testHardwareNotchDoesNotInheritTheNotchlessDefault() {
        XCTAssertFalse(NotchFloatingCapsule.enablesFloatingIsland(
            hasHardwareNotch: true, notchlessFloating: true, hardwareNotchOptIn: false))
        XCTAssertTrue(NotchFloatingCapsule.enablesFloatingIsland(
            hasHardwareNotch: true, notchlessFloating: false, hardwareNotchOptIn: true))
    }

    func testHoverOpensThePanelForTheHardwareCapsuleOnly() {
        XCTAssertFalse(NotchFloatingCapsule.opensPanelOnHover(expandOnHover: false, hardwareNotchCapsule: false))
        XCTAssertTrue(NotchFloatingCapsule.opensPanelOnHover(expandOnHover: true, hardwareNotchCapsule: false))
        XCTAssertTrue(NotchFloatingCapsule.opensPanelOnHover(expandOnHover: false, hardwareNotchCapsule: true))
    }

    func testNotchlessTopInsetIsOnlyTheUserOffset() {
        XCTAssertEqual(NotchFloatingCapsule.topInset(userOffset: 8, safeAreaTop: 40, hasHardwareNotch: false, scale: 2), 8)
        XCTAssertEqual(NotchFloatingCapsule.topInset(userOffset: 0, safeAreaTop: 37, hasHardwareNotch: false, scale: 2), 0)
        XCTAssertEqual(NotchFloatingCapsule.topInset(userOffset: 8.3, safeAreaTop: 0, hasHardwareNotch: false, scale: 2), 8.5)
        XCTAssertEqual(NotchFloatingCapsule.topInset(userOffset: -4, safeAreaTop: 40, hasHardwareNotch: false, scale: 2), 0)
    }

    func testHardwareTopInsetFollowsTheMeasuredSafeArea() {
        XCTAssertEqual(NotchFloatingCapsule.topInset(userOffset: 3, safeAreaTop: 40, hasHardwareNotch: true, scale: 2), 43)
        XCTAssertEqual(NotchFloatingCapsule.topInset(userOffset: 0, safeAreaTop: 32.25, hasHardwareNotch: true, scale: 2), 32.5)
        XCTAssertEqual(NotchFloatingCapsule.topInset(userOffset: 3, safeAreaTop: 37.5, hasHardwareNotch: true, scale: 2), 40.5)
        XCTAssertEqual(NotchFloatingCapsule.topInset(userOffset: 0, safeAreaTop: 59, hasHardwareNotch: true, scale: 2), 59)
    }

    func testClosedCapsuleUsesIslandProportionsInsteadOfAFixedReservedSize() {
        let existing = NotchFloatingCapsule.closedSize(
            menuBarHeight: 29, customWidth: 0, customHeight: 0, scale: 2, minimumHeight: 30)
        XCTAssertEqual(existing.width, 109)
        XCTAssertEqual(existing.height, 31)

        let belowForty = NotchFloatingCapsule.closedSize(
            menuBarHeight: 40, customWidth: 0, customHeight: 0, scale: 2, minimumHeight: 30)
        XCTAssertEqual(belowForty.width, 147)
        XCTAssertEqual(belowForty.height, 42)

        let custom = NotchFloatingCapsule.closedSize(
            menuBarHeight: 40, customWidth: 100, customHeight: 36, scale: 2, minimumHeight: 30)
        XCTAssertEqual(custom.width, 100)
        XCTAssertEqual(custom.height, 36)
    }

    func testExpandedPanelKeepsTheIdleTopInset() {
        let idle = NotchFloatingCapsule.topInset(userOffset: 3, safeAreaTop: 40, hasHardwareNotch: true, scale: 2)
        let expanded = NotchFloatingCapsule.topInset(userOffset: 3, safeAreaTop: 40, hasHardwareNotch: true, scale: 2)
        XCTAssertEqual(idle, expanded)
        XCTAssertEqual(idle, 43)
    }

    func testHoverMarginCannotCrossAboveTheCapsule() {
        let inset = NotchFloatingCapsule.topInset(userOffset: 3, safeAreaTop: 40, hasHardwareNotch: true, scale: 2)
        let stage = NotchFloatingCapsule.Rect(x: 100, y: 0, width: 800, height: 500)
        let capsule = NotchFloatingCapsule.Rect(
            x: stage.midX - 70, y: stage.maxY - inset - 80, width: 140, height: 80)
        let expanded = capsule.insetBy(dx: -60, dy: -60)
        let capped = NotchFloatingCapsule.limitTop(expanded, to: stage.maxY - inset)
        XCTAssertEqual(capped.maxY, stage.maxY - inset)
        XCTAssertEqual(capped.y, expanded.y)
        XCTAssertEqual(capped.x, expanded.x)
        XCTAssertEqual(capped.width, expanded.width)

        let clear = NotchFloatingCapsule.Rect(x: 10, y: 10, width: 20, height: 20)
        XCTAssertEqual(NotchFloatingCapsule.limitTop(clear, to: 40), clear)
    }
}
