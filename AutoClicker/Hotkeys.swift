import Foundation
import SwiftUI
import AppKit

// MARK: - Hotkey Settings Model
final class HotkeySettings: ObservableObject {
    @Published var addPointKey: String { didSet { persist() } }
    @Published var startPauseKey: String { didSet { persist() } }
    @Published var stopKey: String { didSet { persist() } }
    @Published var clearPointsKey: String { didSet { persist() } }

    private let defaults = UserDefaults.standard
    private enum K {
        static let addPoint = "hk_addPoint"
        static let startPause = "hk_startPause"
        static let stop = "hk_stop"
        static let clearPoints = "hk_clearPoints"
    }

    init() {
        addPointKey = defaults.string(forKey: K.addPoint) ?? "=" // supports Shift for '+'
        startPauseKey = defaults.string(forKey: K.startPause) ?? "return"
        stopKey = defaults.string(forKey: K.stop) ?? "delete"
        clearPointsKey = defaults.string(forKey: K.clearPoints) ?? "x"
    }

    private func persist() {
        defaults.set(addPointKey, forKey: K.addPoint)
        defaults.set(startPauseKey, forKey: K.startPause)
        defaults.set(stopKey, forKey: K.stop)
        defaults.set(clearPointsKey, forKey: K.clearPoints)
    }

    // MARK: - Mapping helpers
    func keyEquivalent(for key: String) -> KeyEquivalent {
        switch key.lowercased() {
        case "return", "enter": return .return
        case "delete", "backspace": return .delete
        case "escape", "esc": return .escape
        default:
            if let ch = key.lowercased().first { return KeyEquivalent(ch) }
            return .return
        }
    }

    func isStop(event: NSEvent) -> Bool { matches(event: event, to: stopKey) || isForwardDelete(event) }
    func isStartPause(event: NSEvent) -> Bool { matches(event: event, to: startPauseKey) }
    func isAddPoint(event: NSEvent) -> Bool { matches(event: event, to: addPointKey) || isShiftedEqual(event) }
    func isClearPoints(event: NSEvent) -> Bool { matches(event: event, to: clearPointsKey) }

    private func matches(event: NSEvent, to key: String) -> Bool {
        let lower = key.lowercased()
        switch lower {
        case "return", "enter": return event.keyCode == 36
        case "delete", "backspace": return event.keyCode == 51 || event.keyCode == 117
        default:
            guard let chars = event.charactersIgnoringModifiers?.lowercased(), let c = chars.first else { return false }
            // '=' key is keyCode 24 and charactersIgnoringModifiers will be '=' even with Shift (which gives '+')
            if lower == "=" { return c == "=" }
            return String(c) == lower
        }
    }

    private func isShiftedEqual(_ event: NSEvent) -> Bool { // '+', same key as '=' with shift
        return event.keyCode == 24
    }

    private func isForwardDelete(_ event: NSEvent) -> Bool { // Fn+Delete on some keyboards
        return event.keyCode == 117
    }
}

// MARK: - Settings UI
struct HotkeyRow: View {
    let title: String
    @Binding var key: String
    let defaultValue: String

    @State private var recording: Bool = false
    @State private var monitor: Any? = nil

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
            Spacer()
            Text(display(for: key))
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.white.opacity(0.08)))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(.white.opacity(0.18), lineWidth: 1))
            Button(recording ? "Press a key…" : "Record") {
                toggleRecording()
            }
            .buttonStyle(GlassButtonStyle())
            Button("Reset") { key = defaultValue }
                .buttonStyle(GlassButtonStyle())
        }
        .onDisappear { stopRecording() }
    }

    private func display(for key: String) -> String {
        switch key.lowercased() {
        case "return": return "Enter/Return"
        case "delete": return "Delete"
        case "escape": return "Escape"
        case "=": return "+ / ="
        default: return key.uppercased()
        }
    }

    private func toggleRecording() {
        if recording { stopRecording() } else { startRecording() }
    }

    private func startRecording() {
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let k: String
            switch event.keyCode {
            case 36: k = "return"
            case 51, 117: k = "delete"
            default:
                if let ch = event.charactersIgnoringModifiers?.lowercased().first {
                    if ch == "=" { k = "=" } else { k = String(ch) }
                } else { k = self.key }
            }
            self.key = k
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        recording = false
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
    }
}

struct HotkeysSettingsView: View {
    @EnvironmentObject var hotkeys: HotkeySettings

    var body: some View {
        GlassContainer(title: "Hotkeys") {
            VStack(alignment: .leading, spacing: 12) {
                HotkeyRow(
                    title: "Start / Pause",
                    key: Binding(get: { hotkeys.startPauseKey }, set: { hotkeys.startPauseKey = $0 }),
                    defaultValue: "return"
                )
                HotkeyRow(
                    title: "Stop",
                    key: Binding(get: { hotkeys.stopKey }, set: { hotkeys.stopKey = $0 }),
                    defaultValue: "delete"
                )
                HotkeyRow(
                    title: "Add Point",
                    key: Binding(get: { hotkeys.addPointKey }, set: { hotkeys.addPointKey = $0 }),
                    defaultValue: "="
                )
                HotkeyRow(
                    title: "Clear Points",
                    key: Binding(get: { hotkeys.clearPointsKey }, set: { hotkeys.clearPointsKey = $0 }),
                    defaultValue: "x"
                )
                Text("Tip: ‘Add Point’ accepts + or = when the key is set to ‘=’.")
                    .font(.footnote).foregroundStyle(LG.secondary)
            }
        }
    }
}
