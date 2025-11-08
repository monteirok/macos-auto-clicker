import SwiftUI

@main
struct AutoClickerApp: App {
    @StateObject private var model: ClickerModel = ClickerModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
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
