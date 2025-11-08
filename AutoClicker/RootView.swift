import SwiftUI

struct RootView: View {
    @EnvironmentObject var model: ClickerModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Auto Clicker")
                .font(.largeTitle)
                .bold()

            HStack(spacing: 12) {
                Button(model.isRunning ? "Stop" : "Start") {
                    if model.isRunning {
                        model.stop()
                    } else {
                        model.start()
                    }
                }
                .buttonStyle(.borderedProminent)

                Toggle("Warp Cursor to Target", isOn: $model.warpCursor)
                    .toggleStyle(.switch)
                    .disabled(model.isRunning)
            }

            if model.isRunning {
                Text("Running…")
                    .foregroundStyle(.green)
            } else {
                Text("Idle")
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding()
    }
}

#Preview {
    // Provide a preview with a temporary model instance
    RootView()
        .environmentObject(ClickerModel())
}
