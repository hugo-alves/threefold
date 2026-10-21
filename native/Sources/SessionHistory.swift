import Foundation

// Navigation moves a cursor. It never reorders the trail while you traverse it.
struct SessionHistory: Codable, Equatable {
    private(set) var entries: [String]
    private(set) var cursor: Int
    var current: String { entries[cursor] }
    var canGoBack: Bool { cursor > 0 }
    var canGoForward: Bool { cursor < entries.count - 1 }

    init(_ entries: [String]) {
        precondition(!entries.isEmpty)
        self.entries = entries
        cursor = entries.count - 1
    }

    func restored(allowing ids: Set<String>, fallback: [String]) -> SessionHistory {
        let valid = entries.enumerated().filter { ids.contains($0.element) }
        guard !valid.isEmpty else { return SessionHistory(fallback) }
        var result = SessionHistory(valid.map(\.element))
        result.cursor = max(0, min(valid.count - 1, valid.filter { $0.offset <= cursor }.count - 1))
        return result
    }

    func destination(_ direction: Int) -> String? {
        let next = cursor + direction
        return entries.indices.contains(next) ? entries[next] : nil
    }

    mutating func move(_ direction: Int) {
        if destination(direction) != nil { cursor += direction }
    }

    mutating func select(_ index: Int) {
        if entries.indices.contains(index) { cursor = index }
    }

    mutating func includeEarlierSessions(_ ids: [String]) {
        let missing = ids.filter { !entries.contains($0) }
        entries = missing + entries
        cursor += missing.count
    }

    mutating func visit(_ id: String) {
        guard id != current else { return }
        entries = Array(entries.prefix(cursor + 1)) + [id]
        cursor = entries.count - 1
    }
}

enum SwipeDecision {
    static func historyStep(forTranslation distance: Double) -> Int {
        distance < 0 ? 1 : (distance > 0 ? -1 : 0)
    }

    static func shouldOpenOverview(distance: Double, velocity: Double, height: Double, settings: GestureSettings) -> Bool {
        guard settings.overviewEnabled, abs(distance) >= min(settings.overviewDistance, height * 0.45) * 0.75,
              abs(distance) < height * 0.72, abs(velocity) <= settings.overviewReleaseSpeed else { return false }
        return !(distance * velocity < 0 && abs(velocity) > 160)
    }

    static func threshold(height: Double, settings: GestureSettings = .init()) -> Double {
        min(settings.swipeDistance, height * 0.22)
    }

    static func shouldCommit(distance: Double, velocity: Double, height: Double, settings: GestureSettings = .init()) -> Bool {
        // Reversing toward the origin should cancel, even after crossing the threshold.
        if distance * velocity < 0 && abs(velocity) > 160 { return false }
        return abs(distance) >= threshold(height: height, settings: settings)
            || (abs(distance) > 24 && abs(velocity) > 650 / settings.flickSensitivity && distance * velocity > 0)
    }

    static func settleDuration(remaining: Double, height: Double, velocity: Double, settings: GestureSettings) -> Double {
        let fraction = min(1, abs(remaining) / max(1, height))
        let natural = 0.25 + 0.13 * fraction - min(abs(velocity), 1800) / 8000
        return max(0.12, min(0.5, natural / settings.animationSpeed))
    }
}
