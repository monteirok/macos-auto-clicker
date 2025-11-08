import Foundation
import SwiftUI
import AppKit
import CoreGraphics

struct ClickPoint: Identifiable, Hashable {
    let id: UUID = UUID()
    var name: String
    var location: CGPoint
}

final class ClickerModel: ObservableObject {
    // Config
    @Published var points: [ClickPoint] = []
    @Published var delay: Double = 1.0         // seconds; allow fractional
    @Published var loops: Int = 0              // 0 = infinite
    @Published var warpCursor: Bool = false
    @Published var startingPoint: ClickPoint? = nil // Optional starting point clicked once before first loop

    // State
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var accessibilityGranted: Bool = AccessibilityHelper.isTrusted()
    @Published var statusMessage: String = "Idle"

    private var clickTask: Task<Void, Never>? = nil

    // MARK: - Control

    func start() {
        guard !isRunning else { return }
        guard !points.isEmpty else {
            statusMessage = "Add at least one point."
            NSSound.beep()
            return
        }

        // Only prompt when user presses Start (or via manual tap on status pill elsewhere)
        let trusted = AccessibilityHelper.ensureTrusted(promptIfNeeded: true)
        accessibilityGranted = AccessibilityHelper.isTrusted()

        guard trusted else {
            statusMessage = "Accessibility permission is required."
            return
        }

        isPaused = false
        isRunning = true
        statusMessage = "Running"
        let snapshotPoints = points // capture a snapshot to run exactly
        let snapshotStartingPoint = startingPoint
        let delaySeconds = delay
        let loopsValue = loops
        let warp = warpCursor

        clickTask = Task { [weak self] in
            await self?.runClicks(startingPoint: snapshotStartingPoint, points: snapshotPoints, delay: delaySeconds, loops: loopsValue, warpCursor: warp)
        }
    }

    func pause() {
        guard isRunning else { return }
        isPaused = true
        statusMessage = "Paused"
    }

    func resume() {
        guard isRunning else { return }
        isPaused = false
        statusMessage = "Running"
    }

    func togglePauseResume() {
        if isRunning {
            isPaused ? resume() : pause()
        } else {
            start()
        }
    }

    func stop() {
        clickTask?.cancel()
        clickTask = nil
        isRunning = false
        isPaused = false
        statusMessage = "Stopped"
    }

    func recheckAccessibility(promptIfNeeded: Bool) {
        _ = AccessibilityHelper.ensureTrusted(promptIfNeeded: promptIfNeeded)
        accessibilityGranted = AccessibilityHelper.isTrusted()
    }

    // MARK: - Engine

    private func runClicks(startingPoint: ClickPoint?, points: [ClickPoint], delay: Double, loops: Int, warpCursor: Bool) async {
        let isInfinite = (loops == 0)
        var pass = 0

        // Optional starting point: click once before entering the main loops
        if let sp = startingPoint {
            // Honor pause/cancel cooperatively even before the first click
            while isPaused {
                if Task.isCancelled { return }
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
            if Task.isCancelled { return }
            performLeftClick(at: sp.location, warpCursor: warpCursor)
            if delay > 0 {
                let ns = UInt64((delay * 1_000_000_000.0).rounded())
                try? await Task.sleep(nanoseconds: ns)
            }
        }

        outerLoop: while isInfinite || pass < loops {
            for point in points {
                if Task.isCancelled { break outerLoop }

                // Pause loop (cooperative)
                while isPaused {
                    if Task.isCancelled { break outerLoop }
                    try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
                }
                if Task.isCancelled { break outerLoop }

                performLeftClick(at: point.location, warpCursor: warpCursor)

                // Respect delay
                if delay > 0 {
                    let ns = UInt64((delay * 1_000_000_000.0).rounded())
                    do { try await Task.sleep(nanoseconds: ns) } catch { break outerLoop }
                }
            }
            pass += 1
        }

        await MainActor.run {
            self.isRunning = false
            self.isPaused = false
            if !Task.isCancelled {
                self.statusMessage = "Completed"
            }
        }
    }

    private func performLeftClick(at location: CGPoint, warpCursor: Bool) {
        if warpCursor {
            CGWarpMouseCursorPosition(location)
        }
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }

        let down = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: location, mouseButton: .left)
        let up = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: location, mouseButton: .left)

        down?.post(tap: .cghidEventTap)
        usleep(1000) // tiny delay between down and up to mimic real click
        up?.post(tap: .cghidEventTap)
    }
}
