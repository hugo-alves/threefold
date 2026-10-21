import Foundation

struct GestureSettings: Codable, Equatable {
    enum Haptics: String, Codable, CaseIterable { case off, soft, firm }
    enum IndicatorStyle: String, Codable, CaseIterable { case rail, dots, count }
    var swipeDistance: Double = 96
    var flickSensitivity: Double = 1
    var animationSpeed: Double = 1
    var haptics: Haptics = .soft
    var cardScale: Double = 0.72
    var cardSpacing: Double = 28
    var cornerRadius: Double = 30
    var springDamping: Double = 0.90
    var overviewEnabled = true
    var overviewDistance: Double = 145
    var overviewReleaseSpeed: Double = 420
    var indicatorStyle: IndicatorStyle = .rail
    var indicatorSize: Double = 1
    var showPositionCount = true
    var showActivity = true
    var pulseActivity = true
    var showTouchIndicators = false

    init() {}
    enum CodingKeys: String, CodingKey {
        case swipeDistance, flickSensitivity, animationSpeed, haptics, cardScale, cardSpacing, cornerRadius, springDamping
        case overviewEnabled, overviewDistance, overviewReleaseSpeed, indicatorStyle, indicatorSize
        case showPositionCount, showActivity, pulseActivity, showTouchIndicators
    }
    // New tuning controls must not discard drafts or the previous saved settings.
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        swipeDistance = try c.decodeIfPresent(Double.self, forKey: .swipeDistance) ?? swipeDistance
        flickSensitivity = try c.decodeIfPresent(Double.self, forKey: .flickSensitivity) ?? flickSensitivity
        animationSpeed = try c.decodeIfPresent(Double.self, forKey: .animationSpeed) ?? animationSpeed
        haptics = try c.decodeIfPresent(Haptics.self, forKey: .haptics) ?? haptics
        cardScale = try c.decodeIfPresent(Double.self, forKey: .cardScale) ?? cardScale
        cardSpacing = try c.decodeIfPresent(Double.self, forKey: .cardSpacing) ?? cardSpacing
        cornerRadius = try c.decodeIfPresent(Double.self, forKey: .cornerRadius) ?? cornerRadius
        springDamping = try c.decodeIfPresent(Double.self, forKey: .springDamping) ?? springDamping
        overviewEnabled = try c.decodeIfPresent(Bool.self, forKey: .overviewEnabled) ?? overviewEnabled
        overviewDistance = try c.decodeIfPresent(Double.self, forKey: .overviewDistance) ?? overviewDistance
        overviewReleaseSpeed = try c.decodeIfPresent(Double.self, forKey: .overviewReleaseSpeed) ?? overviewReleaseSpeed
        indicatorStyle = try c.decodeIfPresent(IndicatorStyle.self, forKey: .indicatorStyle) ?? indicatorStyle
        indicatorSize = try c.decodeIfPresent(Double.self, forKey: .indicatorSize) ?? indicatorSize
        showPositionCount = try c.decodeIfPresent(Bool.self, forKey: .showPositionCount) ?? showPositionCount
        showActivity = try c.decodeIfPresent(Bool.self, forKey: .showActivity) ?? showActivity
        pulseActivity = try c.decodeIfPresent(Bool.self, forKey: .pulseActivity) ?? pulseActivity
        showTouchIndicators = try c.decodeIfPresent(Bool.self, forKey: .showTouchIndicators) ?? showTouchIndicators
    }
}

struct ConversationState: Codable, Equatable {
    var draft: String = ""
    // Distance from the top of the transcript, independent of the safe area.
    var readingPosition: Double? = nil
    var sentMessages: [String] = []
}

struct PrototypeState: Codable, Equatable {
    static var seedHistory: [String] { DemoBrand.seedHistory }
    var history = SessionHistory(seedHistory)
    var conversations: [String: ConversationState] = DemoBrand.isWhatsApp ? [
        "wa-maya": .init(draft: "Let’s meet at ")
    ] : [
        "approaches": .init(draft: "Let’s try the second direction. I’d start with "),
        "linkedin": .init(draft: "Make the opening a little more personal")
    ]
    var settings = GestureSettings()
    var hasLearnedGesture = false
    var hasLearnedOverview = false

    init() {}
    enum CodingKeys: String, CodingKey { case history, conversations, settings, hasLearnedGesture, hasLearnedOverview }
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        history = try c.decodeIfPresent(SessionHistory.self, forKey: .history) ?? history
        conversations = try c.decodeIfPresent([String: ConversationState].self, forKey: .conversations) ?? conversations
        settings = try c.decodeIfPresent(GestureSettings.self, forKey: .settings) ?? settings
        hasLearnedGesture = try c.decodeIfPresent(Bool.self, forKey: .hasLearnedGesture) ?? hasLearnedGesture
        hasLearnedOverview = try c.decodeIfPresent(Bool.self, forKey: .hasLearnedOverview) ?? hasLearnedOverview
    }
}

final class PrototypeStore {
    let url: URL

    init(url: URL) { self.url = url }

    convenience init(filename: String = "state.json") {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SessionSwipe", isDirectory: true)
        self.init(url: directory.appendingPathComponent(filename))
    }

    func load() -> PrototypeState? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(PrototypeState.self, from: data)
    }

    func save(_ state: PrototypeState) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(state).write(to: url, options: .atomic)
    }
}
