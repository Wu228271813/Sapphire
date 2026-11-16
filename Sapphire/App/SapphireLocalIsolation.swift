//
//  SapphireLocalIsolation.swift
//  Sapphire
//
//  The local UI test app uses a different bundle id. UserDefaults.standard follows
//  that id. Files under Application Support do not, so this chooses the folder.
//  Any other bundle, including the shipping app, keeps the folder name Sapphire.
//

import Foundation

enum SapphireLocalIsolation {
    static let productionBundleIdentifier = "com.cshariq.sapphire"
    static let localUITestBundleIdentifier = "com.local.sapphire.floatingcapsule.test"
    static let productionSupportDirectoryName = "Sapphire"
    static let localUITestSupportDirectoryName = "SapphireFloatingCapsuleTest"
    static let productionFaceIDKeychainService = "com.shariq.Sapphire.faceid.keychain"
    static let localUITestFaceIDKeychainService = "com.local.sapphire.floatingcapsule.test.faceid.keychain"

    static func supportDirectoryName(forBundleIdentifier bundleIdentifier: String?) -> String {
        bundleIdentifier == localUITestBundleIdentifier
            ? localUITestSupportDirectoryName
            : productionSupportDirectoryName
    }

    static func skipsPrivilegedRegistration(forBundleIdentifier bundleIdentifier: String?) -> Bool {
        bundleIdentifier == localUITestBundleIdentifier
    }

    static func faceIDKeychainService(forBundleIdentifier bundleIdentifier: String?) -> String {
        skipsPrivilegedRegistration(forBundleIdentifier: bundleIdentifier)
            ? localUITestFaceIDKeychainService
            : productionFaceIDKeychainService
    }

    static var supportDirectoryName: String {
        supportDirectoryName(forBundleIdentifier: Bundle.main.bundleIdentifier)
    }

    static var skipsPrivilegedRegistration: Bool {
        skipsPrivilegedRegistration(forBundleIdentifier: Bundle.main.bundleIdentifier)
    }

    static func applicationSupportDirectory(
        base: URL? = nil,
        bundleIdentifier: String? = Bundle.main.bundleIdentifier,
        create: Bool = true
    ) -> URL {
        let root = base ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let url = root.appendingPathComponent(
            supportDirectoryName(forBundleIdentifier: bundleIdentifier),
            isDirectory: true
        )
        if create {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }
}
