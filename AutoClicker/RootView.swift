import SwiftUI
import AppKit

// Refactored "Liquid Glass" UI wired to ClickerModel.
struct RootView: View {
    @EnvironmentObject var model: ClickerModel
    @State private var localMonitor: Any? = nil
    @State private var globalMonitor: Any? = nil

    var body: some View {
        ZStack {
            // Full‑window glass backdrop
            LiquidGlassBackground(cornerRadius: 28)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                header

                // Controls Row
                GlassContainer {
                    HStack(spacing: 14) {
                        NumberInput(title: "Delay (s)", value: $model.delay, step: 0.1)

                        NumberInput(
                            title: "Loops (0 = ∞)",
                            value: Binding<Double>(
                                get: { Double(model.loops) },
                                set: { model.loops = Int($0) }
                            ),
                            step: 1
                        )

                        Toggle("Warp Cursor to Target", isOn: $model.warpCursor)
                            .toggleStyle(GlassToggleStyle())

                        Spacer()

                        HStack(spacing: 10) {
                            Button("Add Point") {
                                Task { await addPointViaOverlay() }
                            }
                            .buttonStyle(GlassButtonStyle())
                            .keyboardShortcut("n", modifiers: [])

                            Button(model.isRunning ? (model.isPaused ? "Resume" : "Pause") : "Start") {
                                if model.isRunning {
                                    model.togglePauseResume()
                                } else {
                                    model.start()
                                }
                            }
                            .buttonStyle(GlassButtonStyle(prominent: true))

                            Button("Stop") { model.stop() }
                                .buttonStyle(GlassButtonStyle())
                                .disabled(!model.isRunning)
                                .keyboardShortcut(.delete, modifiers: [])
                        }
                    }
                }

                // Starting point section
                GlassContainer(title: "Starting Point") {
                    HStack(spacing: 16) {
                        if let sp = model.startingPoint {
                            XYBadge(x: sp.location.x, y: sp.location.y)
                        } else {
                            XYBadge(x: 0, y: 0)
                                .opacity(0.35)
                        }
                        Text("Runs once before first loop to select a window")
                            .foregroundStyle(LG.secondary)
                            .font(.callout)
                        Spacer()
                        Button(model.startingPoint == nil ? "Set Starting Point" : "Replace Starting Point") {
                            Task { await setStartingPointViaOverlay() }
                        }
                        .buttonStyle(GlassButtonStyle())

                        Button("Clear") { model.startingPoint = nil }
                            .buttonStyle(GlassButtonStyle())
                            .disabled(model.startingPoint == nil)
                            .keyboardShortcut("x", modifiers: [])
                    }
                }

                // Points list
                GlassContainer(title: "Points") {
                    VStack(spacing: 10) {
                        HStack {
                            Spacer()
                            Button("Clear Points") { model.points.removeAll() }
                                .buttonStyle(GlassButtonStyle())
                                .disabled(model.points.isEmpty)
                        }
                        ForEach(Array(model.points.enumerated()), id: \.element.id) { idx, point in
                            HStack(spacing: 12) {
                                Text("#\(idx + 1)")
                                    .foregroundStyle(LG.secondary)

                                // Editable name
                                if let name = nameBinding(for: point) {
                                    TextField("Name", text: name)
                                        .glassField()
                                } else {
                                    Text(point.name).glassField()
                                }

                                Spacer()

                                XYBadge(x: point.location.x, y: point.location.y)

                                // Replace per‑row "Edit" with delete "X"
                                Button("X") { removePoint(point) }
                                    .buttonStyle(GlassButtonStyle())
                            }
                        }
                    }
                }

                // Footer status
                HStack {
                    Text(model.statusMessage.isEmpty ? (model.isRunning ? "Running" : "Idle") : model.statusMessage)
                        .foregroundStyle(LG.secondary)
                    Spacer()
                    StatusPill(
                        text: model.accessibilityGranted ? "Accessibility: Allowed" : "Accessibility: Not Allowed",
                        color: model.accessibilityGranted ? .green : .orange
                    )
                    .onTapGesture { model.recheckAccessibility(promptIfNeeded: true) }
                }
                .padding(.horizontal, 4)
            }
            .padding(24)
            .onAppear {
                configureWindowAppearance()
                // Install key monitors to stop with Delete while running
                if localMonitor == nil {
                    localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                        if model.isRunning && (event.keyCode == 51 || event.keyCode == 117) { // delete / forward delete
                            DispatchQueue.main.async { model.stop() }
                            return nil // consume
                        }
                        return event
                    }
                }
                if globalMonitor == nil {
                    globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
                        if model.isRunning && (event.keyCode == 51 || event.keyCode == 117) {
                            DispatchQueue.main.async { model.stop() }
                        }
                    }
                }
            }
            .onDisappear {
                if let m = localMonitor { NSEvent.removeMonitor(m); localMonitor = nil }
                if let m = globalMonitor { NSEvent.removeMonitor(m); globalMonitor = nil }
            }
        }
        .frame(minWidth: 880, minHeight: 520)
    }

    // MARK: - Header
    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Auto Clicker").font(.system(size: 24, weight: .bold))
                Text("macOS 26 – Liquid Glass").font(.callout).foregroundStyle(LG.secondary)
            }
            Spacer()
            StatusPill(
                text: model.accessibilityGranted ? "Accessibility: Allowed" : "Accessibility: Not Allowed",
                color: model.accessibilityGranted ? .green : .orange
            )
            .onTapGesture { model.recheckAccessibility(promptIfNeeded: true) }
        }
    }

    // MARK: - Helpers
    private func nameBinding(for point: ClickPoint) -> Binding<String>? {
        guard let idx = model.points.firstIndex(of: point) else { return nil }
        return $model.points[idx].name
    }

    // MARK: - Actions
    private func addPointViaOverlay() async {
        if let picked = await OverlayPicker.shared.pick() {
            let idx = model.points.count + 1
            model.points.append(ClickPoint(name: "Point \(idx)", location: picked))
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
