//
//  SapphireLocalIsolationTests.swift
//  SapphireTests
//

import XCTest
@testable import Sapphire

final class SapphireLocalIsolationTests: XCTestCase {
    func testShippingBundleKeepsTheProductionSupportFolderAndHelperRegistration() {
        XCTAssertEqual(
            SapphireLocalIsolation.supportDirectoryName(forBundleIdentifier: "com.cshariq.sapphire"),
            "Sapphire"
        )
        XCTAssertFalse(SapphireLocalIsolation.skipsPrivilegedRegistration(forBundleIdentifier: "com.cshariq.sapphire"))
        XCTAssertEqual(SapphireLocalIsolation.supportDirectoryName(forBundleIdentifier: nil), "Sapphire")
        XCTAssertFalse(SapphireLocalIsolation.skipsPrivilegedRegistration(forBundleIdentifier: nil))
        XCTAssertEqual(
            SapphireLocalIsolation.supportDirectoryName(forBundleIdentifier: "com.shariq.SapphireTests"),
            "Sapphire"
        )
    }

    func testLocalUITestBundleUsesItsOwnFolderAndDoesNotRegisterHelpers() {
        let identifier = SapphireLocalIsolation.localUITestBundleIdentifier
        XCTAssertEqual(identifier, "com.local.sapphire.floatingcapsule.test")
        XCTAssertEqual(
            SapphireLocalIsolation.supportDirectoryName(forBundleIdentifier: identifier),
            "SapphireFloatingCapsuleTest"
        )
        XCTAssertTrue(SapphireLocalIsolation.skipsPrivilegedRegistration(forBundleIdentifier: identifier))
        XCTAssertNotEqual(
            SapphireLocalIsolation.supportDirectoryName(forBundleIdentifier: identifier),
            SapphireLocalIsolation.productionSupportDirectoryName
        )
        XCTAssertEqual(
            SapphireLocalIsolation.faceIDKeychainService(forBundleIdentifier: identifier),
            "com.local.sapphire.floatingcapsule.test.faceid.keychain"
        )
        XCTAssertEqual(
            SapphireLocalIsolation.faceIDKeychainService(forBundleIdentifier: "com.cshariq.sapphire"),
            "com.shariq.Sapphire.faceid.keychain"
        )
    }
}
