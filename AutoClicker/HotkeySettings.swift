import SwiftUI

@MainActor
public final class HotkeySettings: ObservableObject {
    @Published public var startPauseKey: String
    @Published public var stopKey: String
    @Published public var addPointKey: String
    @Published public var clearPointsKey: String

    public init(startPauseKey: String = "s",
                stopKey: String = "x",
                addPointKey: String = "a",
                clearPointsKey: String = "c") {
        self.startPauseKey = startPauseKey
        self.stopKey = stopKey
        self.addPointKey = addPointKey
        self.clearPointsKey = clearPointsKey
    }

    public func keyEquivalent(for key: String) -> KeyEquivalent {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let ch = trimmed.lowercased().first, trimmed.count == 1 else {
            return KeyEquivalent(" ")
        }
        return KeyEquivalent(ch)
    }
}
