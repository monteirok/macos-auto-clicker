import Foundation
import AppKit

@MainActor
final class OverlayPicker: NSObject {
    static let shared = OverlayPicker()

    private var windows: [OverlayWindow] = []
    private var continuation: CheckedContinuation<CGPoint?, Never>?

    func pick() async -> CGPoint? {
        guard continuation == nil else { return nil } // avoid concurrent picks
        return await withCheckedContinuation { (cont: CheckedContinuation<CGPoint?, Never>) in
            self.continuation = cont
            self.presentOverlays()
        }
    }

    private func presentOverlays() {
        closeOverlays()

        for screen in NSScreen.screens {
            let win = OverlayWindow(screen: screen, picker: self)
            windows.append(win)
            win.orderFrontRegardless()
        }

        // Make one key for ESC handling
        windows.first?.makeKeyAndOrderFront(nil)
    }

    fileprivate func finish(with point: CGPoint?) {
        continuation?.resume(returning: point)
        continuation = nil
        closeOverlays()
    }

    private func closeOverlays() {
        for w in windows {
            w.orderOut(nil)
        }
        windows.removeAll()
    }
}

final class OverlayWindow: NSPanel {
    weak var picker: OverlayPicker?

    init(screen: NSScreen, picker: OverlayPicker) {
        self.picker = picker
        // Use a designated initializer of NSPanel (no screen parameter)
        super.init(contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)

        // Ensure the window is positioned on the correct screen
        self.setFrame(screen.frame, display: false)

        level = .screenSaver
        isOpaque = false
        backgroundColor = NSColor.black.withAlphaComponent(0.2)
        ignoresMouseEvents = false
        hasShadow = false
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]

        // Content
        let v = OverlayContentView(frame: self.contentView?.bounds ?? self.frame)
        v.autoresizingMask = [.width, .height]
        self.contentView = v
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func mouseDown(with event: NSEvent) {
        // Convert to global screen coordinates using window API (as specified)
        let locInWindow = event.locationInWindow
        let globalPoint = convertPoint(toScreen: locInWindow)
        picker?.finish(with: globalPoint)
    }

    override func keyDown(with event: NSEvent) {
        // Esc cancels (keyCode 53)
        if event.keyCode == 53 {
            picker?.finish(with: nil)
        } else {
            super.keyDown(with: event)
        }
    }
}

final class OverlayContentView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Dim layer is handled by window.backgroundColor; here we draw brief instruction
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white.withAlphaComponent(0.9),
            .font: NSFont.monospacedSystemFont(ofSize: 16, weight: .medium),
            .paragraphStyle: paragraph
        ]
        let text = "Click to pick a point • ESC to cancel"
        let size = text.size(withAttributes: attrs)
        let rect = NSRect(x: bounds.midX - (size.width / 2.0), y: bounds.midY - (size.height / 2.0), width: size.width, height: size.height)
        text.draw(in: rect, withAttributes: attrs)
    }
}
