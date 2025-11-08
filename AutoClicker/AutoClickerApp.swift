import SwiftUI

@main
struct AutoClickerApp: App {
    @StateObject private var model: ClickerModel = ClickerModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
        }
        .commands {
            CommandMenu("Controls") {
                Button("Start") { model.start() }
                    .keyboardShortcut(.return, modifiers: [])

                Button(model.isPaused ? "Resume" : "Pause") { model.togglePauseResume() }
                    .keyboardShortcut(.space, modifiers: [])
                    .disabled(!model.isRunning)

                Button("Stop") { model.stop() }
                    .keyboardShortcut("s", modifiers: [])
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
                .keyboardShortcut("n", modifiers: [])

                Button("Clear Starting Point") { model.startingPoint = nil }
                    .keyboardShortcut("x", modifiers: [])
                    .disabled(model.startingPoint == nil)
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
