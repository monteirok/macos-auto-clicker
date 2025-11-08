//  AutoClicker_LiquidGlass.swift
//  macOS 26 "Liquid Glass" UI Refactor
//  Drop this into your project and set `ContentView()` as the window's root.
//  Requires: macOS 14+ (SwiftUI), App lifecycle. No third‑party deps.

import SwiftUI
import AppKit

// MARK: - Window chrome helpers (transparent, unified titlebar)
@MainActor
func configureWindowAppearance() {
    // Call once on app launch (e.g., in App .onAppear)
    NSApp.windows.forEach { win in
        win.isOpaque = false
        win.backgroundColor = .clear
        win.titlebarAppearsTransparent = true
        win.titleVisibility = .hidden
        win.toolbarStyle = .unifiedCompact
        win.standardWindowButton(.miniaturizeButton)?.isHidden = false
        win.standardWindowButton(.zoomButton)?.isHidden = false
        win.standardWindowButton(.closeButton)?.isHidden = false
    }
}

// MARK: - Liquid Glass Background
struct LiquidGlassBackground: View {
    var cornerRadius: CGFloat = 20
    var body: some View {
        ZStack {
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow, state: .active)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

            // Subtle multistop gradient tint for "liquid" depth
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.blue.opacity(0.06),
                            Color.black.opacity(0.10)
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )

            // Fine noise for realism
            NoiseOverlay()
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .allowsHitTesting(false)
        }
        .overlay(
            // Soft inner/outer stroke
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                .blendMode(.plusLighter)
        )
    }
}

// MARK: - VisualEffectBlur (NSVisualEffectView wrapper)
struct VisualEffectBlur: NSViewRepresentable {
    enum BlendingMode { case behindWindow, withinWindow }
    let material: NSVisualEffectView.Material
    let blendingMode: BlendingMode
    let state: NSVisualEffectView.State

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blendingMode == .behindWindow ? .behindWindow : .withinWindow
        v.state = state
        return v
    }
    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blendingMode == .behindWindow ? .behindWindow : .withinWindow
        view.state = state
    }
}

// MARK: - Noise overlay
struct NoiseOverlay: View {
    var body: some View {
        Canvas { ctx, size in
            let rect = CGRect(origin: .zero, size: size)
            ctx.fill(Path(rect), with: .color(.black.opacity(0.02)))
            // Draw tiny random specks
            for _ in 0..<4000 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let dot = CGRect(x: x, y: y, width: 1, height: 1)
                ctx.fill(Path(dot), with: .color(.white.opacity(0.03)))
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Tokens (macOS 26 visual language)
struct LG {
    static let corner: CGFloat = 22
    static let pad: CGFloat = 14
    static let glass = Color.white.opacity(0.06)
    static let accent = Color.accentColor
    static let label = Color.primary.opacity(0.85)
    static let secondary = Color.primary.opacity(0.6)
    static let success = Color.green
    static let danger = Color.red
}

// MARK: - Reusable Glass Container & Controls
struct GlassContainer<Content: View>: View {
    var title: String? = nil
    var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title { Text(title).font(.headline).foregroundStyle(LG.label) }
            content()
        }
        .padding(LG.pad)
        .background(LiquidGlassBackground(cornerRadius: LG.corner))
        .overlay(
            RoundedRectangle(cornerRadius: LG.corner, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 0.5)
        )
    }
}

struct GlassField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                    )
            )
    }
}
extension View { func glassField() -> some View { modifier(GlassField()) } }

struct GlassButtonStyle: ButtonStyle {
    var prominent: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        prominent ? LG.accent.opacity(configuration.isPressed ? 0.75 : 0.9)
                                  : .white.opacity(configuration.isPressed ? 0.10 : 0.14)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(.white.opacity(0.22), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: configuration.isPressed ? 4 : 10, x: 0, y: 6)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct GlassToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 10) {
            Text(configuration.label.inspectText())
                .foregroundStyle(LG.label)
            Spacer()
            Button {
                configuration.isOn.toggle()
            } label: {
                Capsule()
                    .fill(
                        LinearGradient(colors: [
                            configuration.isOn ? LG.accent.opacity(0.9) : .white.opacity(0.12),
                            configuration.isOn ? LG.accent.opacity(0.7) : .white.opacity(0.08)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 54, height: 28)
                    .overlay(
                        Circle()
                            .fill(.white)
                            .frame(width: 22, height: 22)
                            .shadow(radius: 2)
                            .offset(x: configuration.isOn ? 12 : -12)
                            .animation(.spring(response: 0.28, dampingFraction: 0.9), value: configuration.isOn)
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

private extension View {
    // Helper to extract label text inside ToggleStyle without extra layout
    func inspectText() -> String {
        if let text = Mirror(reflecting: self).descendant("storage", "anyTextStorage", "storage", "verbatim") as? String {
            return text
        }
        return ""
    }
}

// MARK: - Status Pill
struct StatusPill: View {
    var text: String
    var color: Color
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text).font(.caption).foregroundStyle(LG.secondary)
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(
            Capsule().fill(.white.opacity(0.08))
        )
        .overlay(Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 1))
    }
}

// MARK: - Model (placeholder)
struct ACClickPoint: Identifiable, Hashable { let id = UUID(); var name: String; var x: Double; var y: Double }

// MARK: - ContentView (Refactored)
struct AutoClickerView: View {
    @State private var delaySeconds: Double = 1
    @State private var loopCount: Int = 0 // 0 = infinite
    @State private var warpCursor = false
    @State private var startingPoint = ACClickPoint(name: "Starting Point", x: 2642.8, y: 487.4)
    @State private var points: [ACClickPoint] = [ACClickPoint(name: "Point 1", x: 2642.8, y: 487.4)]
    @State private var isRunning = false
    @State private var accessibilityAllowed = true

    var body: some View {
        ZStack {
            // Glass backdrop spanning the window
            LiquidGlassBackground(cornerRadius: 28)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                header

                // Controls Row
                GlassContainer {
                    HStack(spacing: 14) {
                        NumberInput(title: "Delay (s)", value: $delaySeconds, step: 0.1)
                        NumberInput(title: "Loops (0 = ∞)", value: Binding(get: { Double(loopCount) }, set: { loopCount = Int($0) }), step: 1)
                        Toggle("Warp Cursor to Target", isOn: $warpCursor)
                            .toggleStyle(GlassToggleStyle())
                        Spacer()
                        HStack(spacing: 10) {
                            Button("Add Point", action: addPoint).buttonStyle(GlassButtonStyle())
                            Button(isRunning ? "Pause" : "Start", action: toggleRun)
                                .buttonStyle(GlassButtonStyle(prominent: true))
                            Button("Stop", action: stop).buttonStyle(GlassButtonStyle())
                                .disabled(!isRunning)
                        }
                    }
                }

                // Starting point section
                GlassContainer(title: "Starting Point") {
                    HStack(spacing: 16) {
                        XYBadge(x: startingPoint.x, y: startingPoint.y)
                        Text("Runs once before first loop to select a window").foregroundStyle(LG.secondary).font(.callout)
                        Spacer()
                        Button("Replace Starting Point", action: replaceStart).buttonStyle(GlassButtonStyle())
                        Button("Clear", action: clearStart).buttonStyle(GlassButtonStyle())
                    }
                }

                // Points list
                GlassContainer(title: "Points") {
                    VStack(spacing: 10) {
                        ForEach(Array(points.enumerated()), id: \.element.id) { idx, p in
                            HStack(spacing: 12) {
                                Text("#\(idx + 1)").foregroundStyle(LG.secondary)
                                TextField("Name", text: .constant(p.name))
                                    .glassField()
                                Spacer()
                                XYBadge(x: p.x, y: p.y)
                                Button("X") {
                                    if let id = points.firstIndex(where: { $0.id == p.id }) {
                                        points.remove(at: id)
                                    }
                                }
                                .buttonStyle(GlassButtonStyle())
                            }
                        }
                    }
                }

                // Footer status
                HStack {
                    Text(isRunning ? "Running" : "Idle").foregroundStyle(LG.secondary)
                    Spacer()
                    StatusPill(text: accessibilityAllowed ? "Accessibility: Allowed" : "Accessibility: Missing", color: accessibilityAllowed ? .green : .orange)
                }
                .padding(.horizontal, 4)
            }
            .padding(24)
            .onAppear { configureWindowAppearance() }
        }
        .frame(minWidth: 880, minHeight: 520)
    }

    // MARK: - Header
    var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Auto Clicker").font(.system(size: 24, weight: .bold))
                Text("macOS 26 – Liquid Glass").font(.callout).foregroundStyle(LG.secondary)
            }
            Spacer()
            StatusPill(text: accessibilityAllowed ? "Accessibility: Allowed" : "Accessibility: Missing", color: accessibilityAllowed ? .green : .orange)
        }
    }

    // MARK: - Actions (stubs)
    func addPoint() { points.append(ACClickPoint(name: "Point \(points.count + 1)", x: 100, y: 100)) }
    func toggleRun() { isRunning.toggle() }
    func stop() { isRunning = false }
    func replaceStart() { /* open picker */ }
    func clearStart() { /* clear */ }
}

// MARK: - Pieces
struct NumberInput: View {
    var title: String
    @Binding var value: Double
    var step: Double = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(LG.secondary)
            HStack(spacing: 8) {
                TextField("0", value: $value, format: .number)
                    .glassField()
                    .frame(width: 120)
                Stepper("", value: $value, in: 0...10_000, step: step)
                    .labelsHidden()
            }
        }
    }
}

struct XYBadge: View {
    var x: Double
    var y: Double
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Text("X:").foregroundStyle(LG.secondary)
                Text(String(format: "%.1f", x)).foregroundStyle(LG.label)
            }
            HStack(spacing: 6) {
                Text("Y:").foregroundStyle(LG.secondary)
                Text(String(format: "%.1f", y)).foregroundStyle(LG.label)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(.white.opacity(0.16), lineWidth: 1))
    }
}

// MARK: - Preview
#Preview {
    AutoClickerView()
        .frame(width: 980, height: 600)
}
