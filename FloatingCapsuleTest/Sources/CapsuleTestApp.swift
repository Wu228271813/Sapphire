//
//  CapsuleTestApp.swift
//  FloatingCapsuleTest
//
//  Notch-only prototype. Not the full Sapphire app. Part of Sapphire, AGPL-3.0.
//

import AppKit

final class CapsuleTestAppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel?
    private var screenObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        showPanel()
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.showPanel()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func showPanel() {
        let screen = Self.preferredScreen()
        let reading = Self.reading(of: screen)
        let placement = CapsuleScreenGeometry.placement(
            safeAreaTop: reading.safeAreaTop,
            menuBarHeight: reading.menuBarHeight,
            hasHardwareNotch: reading.hasHardwareNotch,
            scale: reading.scale
        )
        let frame = placement.windowFrame(screenMidX: reading.midX, screenMaxY: reading.maxY)
        let rect = NSRect(x: frame.x, y: frame.y, width: frame.width, height: frame.height)
        let view = CapsulePrototypeView(placement: placement, reading: reading)
        if let panel {
            panel.setFrame(rect, display: true)
            panel.contentView = view
        } else {
            let window = NSPanel(
                contentRect: rect,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            window.isFloatingPanel = true
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.hidesOnDeactivate = false
            window.isMovable = false
            window.title = "Sapphire Floating Test"
            window.contentView = view
            window.orderFrontRegardless()
            panel = window
        }
    }

    private static func preferredScreen() -> NSScreen? {
        NSScreen.screens.first { screen in
            let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
            let displayID = CGDirectDisplayID(number?.uint32Value ?? 0)
            return CGDisplayIsBuiltin(displayID) != 0
        } ?? NSScreen.main
    }

    struct ScreenReading {
        var safeAreaTop: Double
        var menuBarHeight: Double
        var hasHardwareNotch: Bool
        var scale: Double
        var midX: Double
        var maxY: Double
    }

    private static func reading(of screen: NSScreen?) -> ScreenReading {
        guard let screen else {
            return ScreenReading(
                safeAreaTop: 0, menuBarHeight: 24, hasHardwareNotch: false,
                scale: 2, midX: 400, maxY: 800
            )
        }
        let safeTop = Double(screen.safeAreaInsets.top)
        let left = screen.auxiliaryTopLeftArea?.maxX
        let right = screen.auxiliaryTopRightArea?.minX
        let notch = CapsuleScreenGeometry.hasHardwareNotch(
            safeAreaTop: safeTop,
            leftMaxX: left.map(Double.init),
            rightMinX: right.map(Double.init)
        )
        let gap = screen.frame.maxY - screen.visibleFrame.maxY
        let menuBar = gap > 1 ? Double(gap - 1) : 24
        return ScreenReading(
            safeAreaTop: safeTop,
            menuBarHeight: menuBar,
            hasHardwareNotch: notch,
            scale: Double(screen.backingScaleFactor),
            midX: Double(screen.frame.midX),
            maxY: Double(screen.frame.maxY)
        )
    }
}

final class CapsulePrototypeView: NSView {
    private let placement: CapsulePlacement
    private let reading: CapsuleTestAppDelegate.ScreenReading
    private var interaction = CapsuleInteraction()
    private var tracking: NSTrackingArea?
    private var clock: Timer?
    private let timeLabel = NSTextField(labelWithString: "")
    private let detail = NSTextField(wrappingLabelWithString: "")
    private let pinButton = NSButton(title: "Pin", target: nil, action: nil)
    private let quitButton = NSButton(title: "Quit", target: nil, action: nil)

    init(placement: CapsulePlacement, reading: CapsuleTestAppDelegate.ScreenReading) {
        self.placement = placement
        self.reading = reading
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 18, weight: .semibold)
        timeLabel.textColor = .white
        timeLabel.alignment = .center
        detail.font = .systemFont(ofSize: 12)
        detail.textColor = .white
        detail.alignment = .left
        pinButton.bezelStyle = .rounded
        pinButton.target = self
        pinButton.action = #selector(togglePin)
        quitButton.bezelStyle = .rounded
        quitButton.target = NSApp
        quitButton.action = #selector(NSApplication.terminate(_:))
        addSubview(timeLabel)
        addSubview(detail)
        addSubview(pinButton)
        addSubview(quitButton)
        clock = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.refreshText()
        }
        refreshText()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override var isFlipped: Bool { true }

    override func layout() {
        super.layout()
        let open = interaction.panelOpen
        let hit = placement.hitRect(expanded: open)
        let capsule = NSRect(x: hit.x, y: hit.y, width: hit.width, height: open ? placement.closedHeight : hit.height)
        timeLabel.frame = capsule.insetBy(dx: 12, dy: 6)
        detail.isHidden = !open
        pinButton.isHidden = !open
        quitButton.isHidden = !open
        if open {
            detail.frame = NSRect(x: 16, y: placement.closedHeight + 8, width: bounds.width - 32, height: 78)
            pinButton.frame = NSRect(x: 16, y: bounds.height - 36, width: 72, height: 24)
            quitButton.frame = NSRect(x: bounds.width - 88, y: bounds.height - 36, width: 72, height: 24)
        }
        pinButton.title = interaction.pinned ? "Unpin" : "Pin"
        updateTrackingAreas()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let open = interaction.panelOpen
        let hit = placement.hitRect(expanded: open)
        let rect = NSRect(x: hit.x, y: hit.y, width: hit.width, height: hit.height)
        let radius = open ? 22 : min(rect.width, rect.height) / 2
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        NSColor.black.setFill()
        path.fill()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let hit = placement.hitRect(expanded: interaction.panelOpen)
        let area = NSTrackingArea(
            rect: NSRect(x: hit.x, y: hit.y, width: hit.width, height: hit.height),
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        tracking = area
    }

    override func mouseEntered(with event: NSEvent) {
        interaction.pointerEntered()
        needsLayout = true
    }

    override func mouseExited(with event: NSEvent) {
        interaction.pointerExited()
        needsLayout = true
    }

    @objc private func togglePin() {
        interaction.togglePinned()
        needsLayout = true
    }

    private func refreshText() {
        timeLabel.stringValue = Self.time.string(from: Date())
        let notchLine = reading.hasHardwareNotch
            ? "Hardware notch. Clearance is the live safe area plus \(Int(CapsuleScreenGeometry.extraGap)) pt. The camera housing stays visible."
            : "This display has no hardware notch. The gap is only the extra \(Int(CapsuleScreenGeometry.extraGap)) pt."
        detail.stringValue = """
        Floating capsule test. Not the full Sapphire app.
        Local time only. Weather, music, and continuity are not connected.
        \(notchLine)
        Top gap: \(placement.topInset) pt.
        """
    }

    private static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter
    }()
}

@main
enum CapsuleTestMain {
    private static let delegate = CapsuleTestAppDelegate()

    static func main() {
        let app = NSApplication.shared
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }
}
