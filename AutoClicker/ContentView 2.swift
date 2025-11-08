import SwiftUI

struct ControlsView: View {
    @EnvironmentObject var model: ClickerModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Auto Clicker")
                .font(.largeTitle).bold()

            Text(model.isRunning ? "Status: Running" : "Status: Stopped")
                .foregroundStyle(model.isRunning ? .green : .secondary)

            HStack {
                Button("Start") { model.start() }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isRunning)
                Button("Stop", role: .destructive) { model.stop() }
                    .buttonStyle(.bordered)
                    .disabled(!model.isRunning)
            }

            Toggle("Warp Cursor to Target", isOn: $model.warpCursor)
                .disabled(model.isRunning)
        }
        .padding()
    }
}

#Preview {
    ControlsView()
        .environmentObject(ClickerModel())
}
