//
//  CapsuleInteraction.swift
//  FloatingCapsuleTest
//
//  Hover and pin for the notch-only prototype. Part of Sapphire, AGPL-3.0.
//

import Foundation

struct CapsuleInteraction: Equatable {
    var pointerInside = false
    var pinned = false

    var panelOpen: Bool { pointerInside || pinned }

    mutating func pointerEntered() {
        pointerInside = true
    }

    mutating func pointerExited() {
        pointerInside = false
    }

    mutating func togglePinned() {
        pinned.toggle()
    }
}
