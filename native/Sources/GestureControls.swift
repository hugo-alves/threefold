import UIKit

extension SessionActivity {
    var tint: UIColor { self == .working ? .systemGreen : (self == .newReply ? .systemBlue : .clear) }
}

final class ActivityDot: UIView {
    func show(_ activity: SessionActivity, settings: GestureSettings) {
        isHidden = !settings.showActivity || activity == .idle
        backgroundColor = activity.tint
        layer.cornerRadius = bounds.width / 2
        if activity == .working && settings.pulseActivity && !UIAccessibility.isReduceMotionEnabled {
            if layer.animation(forKey: "activity") == nil {
                let pulse = CABasicAnimation(keyPath: "opacity")
                pulse.fromValue = 0.35; pulse.toValue = 1
                pulse.duration = 1.1; pulse.autoreverses = true; pulse.repeatCount = .infinity
                layer.add(pulse, forKey: "activity")
            }
        } else { layer.removeAnimation(forKey: "activity") }
    }
    override func layoutSubviews() { super.layoutSubviews(); layer.cornerRadius = bounds.width / 2 }
}

final class HistoryPositionView: UIControl {
    var onBrowse: (() -> Void)?
    private let backdrop = UIView()
    private let countLabel = UILabel()
    private let stackIcon = UIImageView(image: ChatStyle.symbol("square.stack.3d.up", size: 15))
    private var marks: [UIView] = []
    private var dots: [ActivityDot] = []
    private var entries: [String] = []
    private var cursor = 0
    private var settings = GestureSettings()
    private var emphasized = false

    init() {
        super.init(frame: .zero)
        isAccessibilityElement = true
        accessibilityIdentifier = "sessionStackIndicator"
        accessibilityLabel = "Browse session stack"
        accessibilityHint = "Double tap to see conversation previews"
        addAction(UIAction { [weak self] _ in self?.onBrowse?() }, for: .touchUpInside)
        backdrop.backgroundColor = UIColor(white: 0.13, alpha: 0.80)
        backdrop.layer.cornerRadius = 17
        backdrop.layer.borderWidth = 0.5
        backdrop.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        countLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        countLabel.textColor = .white
        countLabel.textAlignment = .center
        stackIcon.tintColor = .white
        for item in [backdrop, countLabel, stackIcon] { item.isUserInteractionEnabled = false; addSubview(item) }
    }
    required init?(coder: NSCoder) { fatalError() }
    var preferredHeight: CGFloat { settings.indicatorStyle == .count ? 64 : CGFloat(min(entries.count, 9)) * 14 + 36 }

    func show(entries: [String], cursor: Int, settings: GestureSettings, emphasized: Bool) {
        let changed = self.cursor != cursor || self.entries != entries || self.settings != settings
        self.entries = entries; self.cursor = cursor; self.settings = settings; self.emphasized = emphasized
        countLabel.text = "\(cursor + 1)/\(entries.count)"
        accessibilityValue = "\(cursor + 1) of \(entries.count). " + (entries.indices.contains(cursor) ? SampleData.session(entries[cursor]).activity.label : "")
        if marks.count != min(entries.count, 9) {
            marks.forEach { $0.removeFromSuperview() }; dots.forEach { $0.removeFromSuperview() }
            marks = (0..<min(entries.count, 9)).map { _ in let mark = UIView(); mark.isUserInteractionEnabled = false; addSubview(mark); return mark }
            dots = marks.map { _ in let dot = ActivityDot(); dot.isUserInteractionEnabled = false; addSubview(dot); return dot }
        }
        setNeedsLayout()
        if changed && window != nil && !UIAccessibility.isReduceMotionEnabled {
            UIView.animate(withDuration: 0.24, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) { self.layoutIfNeeded() }
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        let numbersOnly = settings.indicatorStyle == .count
        backdrop.frame = CGRect(x: 8, y: 1, width: bounds.width - 12, height: bounds.height - 2)
        backdrop.alpha = emphasized ? 1 : 0.62
        stackIcon.isHidden = !numbersOnly
        stackIcon.frame = CGRect(x: bounds.midX - 6, y: 10, width: 15, height: 15)
        let selected = entries.count > 1 ? Int((Double(cursor) * Double(max(0, marks.count - 1)) / Double(entries.count - 1)).rounded()) : 0
        for (index, mark) in marks.enumerated() {
            let active = index == selected
            let dotsStyle = settings.indicatorStyle == .dots
            let width: CGFloat = dotsStyle ? (active ? 7 : 4) : (active ? 13 : 6)
            let height: CGFloat = dotsStyle ? width : 4
            mark.isHidden = numbersOnly
            mark.frame = CGRect(x: 34 - width / 2, y: 15 + CGFloat(index) * 14 - height / 2, width: width, height: height)
            mark.layer.cornerRadius = height / 2
            mark.backgroundColor = UIColor.white.withAlphaComponent(active ? 1 : 0.26)
            dots[index].frame = CGRect(x: 17, y: 12.5 + CGFloat(index) * 14, width: 5, height: 5)
            let entry = marks.count > 1 ? Int((Double(index) * Double(max(0, entries.count - 1)) / Double(marks.count - 1)).rounded()) : 0
            if entries.indices.contains(entry) { dots[index].show(SampleData.session(entries[entry]).activity, settings: settings) }
            if numbersOnly { dots[index].isHidden = true }
        }
        countLabel.isHidden = !settings.showPositionCount && !numbersOnly
        countLabel.alpha = emphasized ? 1 : 0.72
        countLabel.frame = CGRect(x: 9, y: numbersOnly ? 32 : CGFloat(marks.count) * 14 + 7, width: bounds.width - 14, height: 17)
    }
}

final class FirstSwipeHintView: GlassView {
    var onDismiss: (() -> Void)?
    private let icon = UIImageView(image: ChatStyle.symbol("arrow.up.arrow.down", size: 23))
    private let title = ChatStyle.label("Three fingers to switch chats", size: 14, weight: .semibold)
    private let detail = ChatStyle.label("Release slowly to browse · or tap the edge", size: 12, color: ChatStyle.secondary)
    private lazy var close = ChatStyle.button("xmark", label: "Dismiss gesture hint") { [weak self] in self?.onDismiss?() }
    init() {
        super.init(radius: 20)
        accessibilityIdentifier = "firstSwipeHint"
        icon.tintColor = .white
        for item in [icon, title, detail, close] { content.addSubview(item) }
        close.setImage(ChatStyle.symbol("xmark", size: 11), for: .normal)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        icon.frame = CGRect(x: 14, y: 23, width: 23, height: 23)
        title.frame = CGRect(x: 48, y: 14, width: bounds.width - 88, height: 20)
        detail.frame = CGRect(x: 48, y: 38, width: bounds.width - 66, height: 18)
        close.frame = CGRect(x: bounds.width - 38, y: 0, width: 38, height: 40)
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.85
    }
}

final class GestureSettingsController: UITableViewController {
    var onChange: ((GestureSettings) -> Void)?
    var onShowHint: (() -> Void)?
    var onBrowse: (() -> Void)?
    var onClose: (() -> Void)?
    private var settings: GestureSettings
    private enum Format {
        case points, multiple, percent, speed, damping
        func text(_ value: Double) -> String {
            switch self {
            case .points: return "\(Int(value)) pt"
            case .multiple: return String(format: "%.1f×", value)
            case .percent: return "\(Int(value * 100))%"
            case .speed: return "\(Int(value)) pt/s"
            case .damping: return String(format: "%.2f", value)
            }
        }
    }
    private enum Row {
        case slider(String, String, WritableKeyPath<GestureSettings, Double>, ClosedRange<Double>, String, String, Format)
        case toggle(String, String, WritableKeyPath<GestureSettings, Bool>)
        case choice(String)
        case action(String)
    }
    private var sections: [[Row]] { [
        [.action("Open session stack"), .toggle("Slow release opens overview", "overviewEnabled", \.overviewEnabled),
         .slider("Overview distance", "overviewDistance", \.overviewDistance, 80...260, "Easy to open", "Longer drag", .points),
         .slider("Overview release speed", "overviewReleaseSpeed", \.overviewReleaseSpeed, 150...800, "Very gentle", "More forgiving", .speed)],
        [.slider("Card size", "cardScale", \.cardScale, 0.60...0.92, "Smaller", "Larger", .percent),
         .slider("Card spacing", "cardSpacing", \.cardSpacing, 12...64, "Close", "Airy", .points),
         .slider("Corner radius", "cornerRadius", \.cornerRadius, 12...44, "Subtle", "Round", .points),
         .slider("Animation speed", "animationSpeed", \.animationSpeed, 0.6...1.6, "Calm", "Quick", .multiple),
         .slider("Spring damping", "springDamping", \.springDamping, 0.72...1, "Bouncy", "Settled", .damping),
         .slider("Switch distance", "swipeDistance", \.swipeDistance, 56...200, "Short", "Long", .points),
         .slider("Flick sensitivity", "flickSensitivity", \.flickSensitivity, 0.6...1.6, "Deliberate", "Easy", .multiple)],
        [.choice("Indicator style"), .slider("Indicator size", "indicatorSize", \.indicatorSize, 0.8...1.4, "Small", "Large", .multiple),
         .toggle("Show position count", "showPositionCount", \.showPositionCount),
         .toggle("Show sample activity", "showActivity", \.showActivity),
         .toggle(DemoBrand.isWhatsApp ? "Pulse typing chats" : "Pulse working sessions", "pulseActivity", \.pulseActivity)],
        [.choice("Haptics"), .toggle("Show fingertip dots", "showTouchIndicators", \.showTouchIndicators),
         .action("Show gesture hint"), .action("Restore defaults")]
    ] }
    init(settings: GestureSettings) { self.settings = settings; super.init(style: .insetGrouped); title = "Prototype controls" }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.overrideUserInterfaceStyle = .dark
        tableView.accessibilityIdentifier = "gestureSettings"
        tableView.separatorStyle = .none
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(done))
    }
    @objc private func done() { dismiss(animated: true) { [weak self] in self?.onClose?() } }
    override func numberOfSections(in tableView: UITableView) -> Int { sections.count }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { sections[section].count }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        ["Open & browse", "Motion", "Position & activity", "Feedback"][section]
    }
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0: return "With three fingers, drag about a finger-length and release gently to leave the stack open. A quick flick switches directly. You can also tap the right-edge indicator. In the stack, scroll with one finger and tap a card."
        case 1: return "Changes stay saved. Card size controls how far the conversation shrinks during a swipe and in the overview."
        case 2: return DemoBrand.isWhatsApp ? "In the stack, green means typing and blue means unread. The chat list uses WhatsApp’s green unread badges. All activity is fictional." : "Green means working. Blue means a new reply. These are sample activity states for testing the prototype."
        default: return "Hold a conversation title to return here. The stack also has a controls button."
        }
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch sections[indexPath.section][indexPath.row] { case .slider: return 106; case .choice: return 94; default: return 54 }
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section][indexPath.row]
        switch row {
        case let .slider(title, id, key, range, low, high, format):
            let cell = SliderSettingCell()
            cell.configure(title: title, id: id, value: settings[keyPath: key], range: range, low: low, high: high, formatted: format.text) { [weak self] value in
                self?.settings[keyPath: key] = value; self?.changed()
            }
            return cell
        case let .toggle(title, id, key):
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = title; cell.textLabel?.font = .systemFont(ofSize: 15)
            let control = UISwitch(); control.isOn = settings[keyPath: key]; control.accessibilityIdentifier = id
            control.addAction(UIAction { [weak self, weak control] _ in
                guard let self, let control else { return }; self.settings[keyPath: key] = control.isOn; self.changed()
            }, for: .valueChanged)
            cell.accessoryView = control; cell.selectionStyle = .none
            return cell
        case .choice(let title):
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.selectionStyle = .none
            let label = ChatStyle.label(title, size: 15, weight: .medium)
            let haptics = title == "Haptics"
            let control = UISegmentedControl(items: haptics ? ["Off", "Soft", "Firm"] : ["Rail", "Dots", "Count"])
            control.selectedSegmentIndex = haptics ? GestureSettings.Haptics.allCases.firstIndex(of: settings.haptics)! : GestureSettings.IndicatorStyle.allCases.firstIndex(of: settings.indicatorStyle)!
            control.accessibilityIdentifier = haptics ? "haptics" : "indicatorStyle"
            control.addAction(UIAction { [weak self, weak control] _ in
                guard let self, let control else { return }
                if haptics {
                    self.settings.haptics = GestureSettings.Haptics.allCases[control.selectedSegmentIndex]
                    if self.settings.haptics != .off { UIImpactFeedbackGenerator(style: self.settings.haptics == .soft ? .soft : .medium).impactOccurred() }
                } else { self.settings.indicatorStyle = GestureSettings.IndicatorStyle.allCases[control.selectedSegmentIndex] }
                self.changed()
            }, for: .valueChanged)
            for item in [label, control] { item.translatesAutoresizingMaskIntoConstraints = false; cell.contentView.addSubview(item) }
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16), label.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
                control.leadingAnchor.constraint(equalTo: label.leadingAnchor), control.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                control.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 10)
            ])
            return cell
        case .action(let title):
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = title; cell.textLabel?.textColor = .white; cell.textLabel?.font = .systemFont(ofSize: 15)
            if title == "Open session stack" { cell.accessibilityIdentifier = "openSessionStack"; cell.accessoryType = .disclosureIndicator }
            return cell
        }
    }
    private func changed() { onChange?(settings) }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard case .action(let title) = sections[indexPath.section][indexPath.row] else { return }
        if title == "Restore defaults" { settings = GestureSettings(); changed(); tableView.reloadData(); return }
        let action = title == "Open session stack" ? onBrowse : onShowHint
        let close = onClose
        dismiss(animated: true) { close?(); action?() }
    }
}

private final class SliderSettingCell: UITableViewCell {
    private let name = ChatStyle.label("", size: 16, weight: .medium)
    private let value = ChatStyle.label("", size: 13, color: ChatStyle.secondary)
    private let low = ChatStyle.label("", size: 11, color: ChatStyle.secondary)
    private let high = ChatStyle.label("", size: 11, color: ChatStyle.secondary)
    private let slider = UISlider()
    private var onChange: ((Double) -> Void)?
    private var format: ((Double) -> String)?
    init() {
        super.init(style: .default, reuseIdentifier: nil)
        selectionStyle = .none
        slider.tintColor = .white
        value.textAlignment = .right
        high.textAlignment = .right
        for item in [name, value, low, high, slider] { contentView.addSubview(item) }
        slider.addTarget(self, action: #selector(adjusted), for: .valueChanged)
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(title: String, id: String, value: Double, range: ClosedRange<Double>, low: String, high: String, formatted: @escaping (Double) -> String, onChange: @escaping (Double) -> Void) {
        name.text = title
        self.low.text = low
        self.high.text = high
        self.onChange = onChange
        format = formatted
        slider.minimumValue = Float(range.lowerBound)
        slider.maximumValue = Float(range.upperBound)
        slider.value = Float(value)
        slider.accessibilityIdentifier = id
        slider.accessibilityLabel = title
        self.value.text = formatted(value)
    }
    @objc private func adjusted() {
        value.text = format?(Double(slider.value))
        onChange?(Double(slider.value))
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        let width = contentView.bounds.width
        name.frame = CGRect(x: 16, y: 13, width: width - 96, height: 22)
        value.frame = CGRect(x: width - 80, y: 13, width: 64, height: 22)
        slider.frame = CGRect(x: 16, y: 41, width: width - 32, height: 30)
        low.frame = CGRect(x: 16, y: 76, width: width / 2 - 16, height: 17)
        high.frame = CGRect(x: width / 2, y: 76, width: width / 2 - 16, height: 17)
    }
}
