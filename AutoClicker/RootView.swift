import SwiftUI

struct RootView: View {
    @EnvironmentObject var model: ClickerModel
    @State private var isEditing: Bool = false
    @State private var isEditingDelay: Bool = false
    @State private var isEditingLoops: Bool = false

    private let delayFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 3
        nf.minimum = 0
        return nf
    }()

    private let loopsFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 0
        nf.minimum = 0
        return nf
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            controls
            startingPointSection
            pointsList
            footer
        }
        .padding(16)
        .frame(minWidth: 700, minHeight: 450)
    }

    private var header: some View {
        HStack {
            Text("Auto Clicker")
                .font(.title)
                .bold()
            Spacer()
            accessibilityStatusPill
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                HStack {
                    Text("Delay (s)")
                    TextField("Delay", value: $model.delay, formatter: delayFormatter)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                        .font(.system(.body, design: .monospaced))
                        .onTapGesture { isEditingDelay = true }
                }

                HStack {
                    Text("Loops")
                    TextField("Loops", value: $model.loops, formatter: loopsFormatter)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                        .font(.system(.body, design: .monospaced))
                        .onTapGesture { isEditingLoops = true }
                }

                Toggle("Warp Cursor to Target", isOn: $model.warpCursor)
                    .toggleStyle(.switch)
                    .help("Move cursor to target before clicking")

                Spacer()

                Button {
                    Task { await addPointViaOverlay() }
                } label: {
                    Label("Add Point", systemImage: "plus.circle")
                }

                if !model.isRunning {
                    Button {
                        model.start()
                    } label: {
                        Label("Start", systemImage: "play.fill")
                    }
                    .keyboardShortcut(.space, modifiers: [])
                } else {
                    Button {
                        model.togglePauseResume()
                    } label: {
                        Label(model.isPaused ? "Resume" : "Pause", systemImage: model.isPaused ? "playpause.fill" : "pause.fill")
                    }
                    .keyboardShortcut(.space, modifiers: [])
                }

                Button {
                    model.stop()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .disabled(!model.isRunning)
                .keyboardShortcut(.escape, modifiers: [])
            }

            Text("Tip: 0 loops = infinite • Use Add Point to select targets")
                .foregroundColor(.secondary)
                .font(.footnote)
        }
    }

    private var startingPointSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text("Starting Point")
                    .font(.headline)
                if let sp = model.startingPoint {
                    Text("X: \(sp.location.x, specifier: "%.1f")  Y: \(sp.location.y, specifier: "%.1f")")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                } else {
                    Text("None")
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button {
                    Task { await setStartingPointViaOverlay() }
                } label: {
                    Label(model.startingPoint == nil ? "Set Starting Point" : "Replace Starting Point", systemImage: "scope")
                }
                Button(role: .destructive) {
                    model.startingPoint = nil
                } label: {
                    Label("Clear", systemImage: "xmark.circle")
                }
                .disabled(model.startingPoint == nil)
            }
            Text("Runs once before first loop to select a window")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var pointsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Points")
                    .font(.headline)
                Spacer()
                if !model.points.isEmpty {
                    Button(isEditing ? "Done" : "Edit") {
                        isEditing.toggle()
                    }
                }
            }

            List {
                ForEach($model.points) { $point in
                    HStack {
                        if let idx = model.points.firstIndex(of: point) {
                            Text("#\(idx + 1)")
                                .frame(width: 40, alignment: .leading)
                                .foregroundColor(.secondary)
                        }

                        TextField("Name", text: $point.name)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 180)

                        Spacer()

                        Text("X:")
                        Text("\(point.location.x, specifier: "%.1f")")
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 100, alignment: .trailing)

                        Text("Y:")
                        Text("\(point.location.y, specifier: "%.1f")")
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 100, alignment: .trailing)
                    }
                    .contextMenu {
                        Button(role: .destructive) { removePoint(point) } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
                .onDelete { offsets in
                    model.points.remove(atOffsets: offsets)
                }
                .onMove { from, to in
                    model.points.move(fromOffsets: from, toOffset: to)
                }
                .deleteDisabled(!isEditing)
                .moveDisabled(!isEditing)
            }
        }
    }

    private var footer: some View {
        HStack {
            Text(model.statusMessage)
                .foregroundColor(.secondary)
            Spacer()
            Text(model.isRunning ? (model.isPaused ? "Paused" : "Running") : "Idle")
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(model.isRunning ? (model.isPaused ? Color.yellow.opacity(0.2) : Color.green.opacity(0.2)) : Color.gray.opacity(0.15))
                .clipShape(Capsule())
        }
    }

    private var accessibilityStatusPill: some View {
        Button {
            model.recheckAccessibility(promptIfNeeded: true)
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(model.accessibilityGranted ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(model.accessibilityGranted ? "Accessibility: Allowed" : "Accessibility: Not Allowed")
                    .font(.callout)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color.gray.opacity(0.15))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .help("Click to re-check and prompt if needed")
    }

    // MARK: - Actions

    private func addPointViaOverlay() async {
        if let point = await OverlayPicker.shared.pick() {
            let idx = model.points.count + 1
            let new = ClickPoint(name: "Point \(idx)", location: point)
            model.points.append(new)
        }
    }

    private func setStartingPointViaOverlay() async {
        if let point = await OverlayPicker.shared.pick() {
            model.startingPoint = ClickPoint(name: "Starting Point", location: point)
        }
    }

    private func removePoint(_ point: ClickPoint) {
        if let idx = model.points.firstIndex(of: point) {
            model.points.remove(at: idx)
        }
    }
}

#Preview {
    RootView()
        .environmentObject(ClickerModel())
}
