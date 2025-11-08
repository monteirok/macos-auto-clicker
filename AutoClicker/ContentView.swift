import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model: ClickerModel

    var body: some View {
        VStack {
            Text("Click Points: \(model.points.count)")
            Button(action: {
                model.start()
            }) {
                Text("Start")
            }
            Button(action: {
                model.stop()
            }) {
                Text("Stop")
            }
            Button(action: {
                model.togglePauseResume()
            }) {
                Text(model.isPaused ? "Resume" : "Pause")
            }
            Text(model.statusMessage)
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environmentObject(ClickerModel())
}
