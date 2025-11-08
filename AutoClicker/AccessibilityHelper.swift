import Foundation
import ApplicationServices

enum AccessibilityHelper {
    static func isTrusted() -> Bool {
        return AXIsProcessTrusted()
    }

    // Only call with promptIfNeeded = true on explicit user action (e.g., Start button or status pill tap)
    static func ensureTrusted(promptIfNeeded: Bool) -> Bool {
        if AXIsProcessTrusted() { return true }
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: promptIfNeeded]
        let trusted = AXIsProcessTrustedWithOptions(options)
        // Note: This call returns immediately; trust becomes true only after user grants it in System Settings.
        return trusted && AXIsProcessTrusted()
    }
}

