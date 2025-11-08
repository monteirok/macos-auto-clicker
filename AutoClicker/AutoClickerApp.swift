import SwiftUI

@main
struct AutoClickerApp: App {
    @StateObject private var model: ClickerModel = ClickerModel()
    @StateObject private var hotkeys: HotkeySettings = HotkeySettings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .environmentObject(hotkeys)
        }
        .commands {
            CommandMenu("Controls") {
                Button(model.isRunning ? (model.isPaused ? "Resume" : "Pause") : "Start") {
                    if model.isRunning { model.togglePauseResume() } else { model.start() }
                }
                .keyboardShortcut(hotkeys.keyEquivalent(for: hotkeys.startPauseKey), modifiers: [])

                Button("Stop") { model.stop() }
                    .keyboardShortcut(hotkeys.keyEquivalent(for: hotkeys.stopKey), modifiers: [])
                    .disabled(!model.isRunning)

                Divider()

                Button("Add Point") {
                    Task {
                        if let p = await OverlayPicker.shared.pick() {
                            let idx = model.points.count + 1
                            model.points.append(ClickPoint(name: "Point \(idx)", location: p))
                        }
                    }
                }
                .keyboardShortcut(hotkeys.keyEquivalent(for: hotkeys.addPointKey), modifiers: [])

                Button("Clear Starting Point") { model.startingPoint = nil }
                    .disabled(model.startingPoint == nil)

                Button("Clear Points") { model.points.removeAll() }
                    .keyboardShortcut(hotkeys.keyEquivalent(for: hotkeys.clearPointsKey), modifiers: [])
                    .disabled(model.points.isEmpty)
            }
        }

        #if os(macOS)
        if #available(macOS 13.0, *) {
            MenuBarExtra(
                content: {
                    Button("Stop", role: .destructive) {
                        model.stop()
                    }
                    .disabled(!model.isRunning)
                    Divider()
                    Toggle("Warp Cursor to Target", isOn: $model.warpCursor)
                    Divider()
                    Button("Quit") {
                        NSApp.terminate(nil)
                    }
                },
                label: {
                    Label("Auto Clicker", systemImage: "cursorarrow.click")
                }
            )
        }
        #endif
    }
}
