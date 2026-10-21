import UIKit

final class ConversationView: ConversationSurface, UIScrollViewDelegate {
    private let transcript = UIView()
    private var messages: [TranscriptMessageView] = []
    private var sentMessages: [String]
    private let reactions = UIView()
    private let backGlass = GlassView(radius: 22)
    private let actionsGlass = GlassView(radius: 23)
    private let changesGlass = GlassView(radius: 15)
    private let topBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let topFade = CAGradientLayer()
    private let title: UILabel
    private let subtitle: UILabel
    private let titleArea = UIView()
    private let more: UIButton
    private let changes = UIButton(type: .system)
    lazy var composer = ComposerView(placeholder: "Work on MacBook", voiceMode: false) { [weak self] in self?.onAccessory?($0) }
    private var didPosition = false
    private let initialReadingPosition: Double?
    private var isLayingOut = false

    init(_ session: SampleSession, state: ConversationState) {
        sentMessages = state.sentMessages
        initialReadingPosition = state.readingPosition
        title = ChatStyle.label(session.title, size: 15, weight: .semibold)
        subtitle = ChatStyle.label("\(session.project ?? "Codex") · MacBook", size: 12, color: ChatStyle.secondary)
        more = ChatStyle.button("ellipsis", label: "Conversation options", action: {})
        super.init(session)
        backgroundColor = .black
        scroll.backgroundColor = .black
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.panGestureRecognizer.maximumNumberOfTouches = 1
        scroll.showsVerticalScrollIndicator = false
        scroll.keyboardDismissMode = .interactive
        scroll.accessibilityIdentifier = "conversationScroll"
        scroll.delegate = self
        addSubview(scroll)
        scroll.addSubview(transcript)
        for message in session.messages + state.sentMessages.map({ SampleMessage.user($0) }) {
            let item = TranscriptMessageView(message)
            transcript.addSubview(item)
            messages.append(item)
        }
        for (index, symbol) in ["square.on.square", "hand.thumbsup", "hand.thumbsdown"].enumerated() {
            let button = ChatStyle.button(symbol, label: ["Copy sample response", "Good response", "Bad response"][index]) { [weak self] in
                self?.onAccessory?(["Copy", "Feedback", "Feedback"][index])
            }
            button.setImage(ChatStyle.symbol(symbol, size: 15), for: .normal)
            button.tintColor = ChatStyle.secondary
            button.frame = CGRect(x: CGFloat(index) * 34, y: 0, width: 34, height: 36)
            reactions.addSubview(button)
        }
        transcript.addSubview(reactions)
        topBlur.isUserInteractionEnabled = false
        topBlur.contentView.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        topFade.colors = [UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
        topFade.locations = [0, 0.88, 1]
        topBlur.layer.mask = topFade
        addSubview(topBlur)
        addSubview(titleArea)
        titleArea.addSubview(title)
        titleArea.addSubview(subtitle)
        title.lineBreakMode = .byTruncatingTail
        title.accessibilityIdentifier = "conversationTitle"
        title.accessibilityHint = "Touch and hold for gesture settings"
        titleArea.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(holdTitle(_:))))
        addSubview(backGlass)
        addSubview(actionsGlass)
        let back = ChatStyle.button("chevron.left", label: "Back to sessions") { [weak self] in self?.onBack?() }
        back.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        backGlass.content.addSubview(back)
        let new = ChatStyle.button("square.and.pencil", label: "New conversation") { [weak self] in self?.onNew?() }
        new.frame = CGRect(x: 3, y: 0, width: 50, height: 44)
        actionsGlass.content.addSubview(new)
        more.frame = CGRect(x: 55, y: 0, width: 50, height: 44)
        more.accessibilityIdentifier = "conversationOptions"
        more.showsMenuAsPrimaryAction = true
        actionsGlass.content.addSubview(more)
        addSubview(changesGlass)
        let diff = NSMutableAttributedString(string: "21 files   ", attributes: [.foregroundColor: ChatStyle.secondary, .font: UIFont.systemFont(ofSize: 12)])
        diff.append(NSAttributedString(string: "\(session.additions ?? "+24") ", attributes: [.foregroundColor: ChatStyle.additions, .font: UIFont.systemFont(ofSize: 12)]))
        diff.append(NSAttributedString(string: session.deletions ?? "−2", attributes: [.foregroundColor: ChatStyle.deletions, .font: UIFont.systemFont(ofSize: 12)]))
        changes.setAttributedTitle(diff, for: .normal)
        changes.accessibilityLabel = "View sample changes"
        changes.addAction(UIAction { [weak self] _ in self?.onAccessory?("Changes") }, for: .touchUpInside)
        changesGlass.content.addSubview(changes)
        addSubview(composer)
        composer.field.text = state.draft
        composer.field.addTarget(self, action: #selector(draftChanged), for: .editingChanged)
        composer.onSubmit = { [weak self] in self?.appendMessage($0) }
        accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "Previous session") { [weak self] _ in self?.onHistory?(-1); return true },
            UIAccessibilityCustomAction(name: "Next session") { [weak self] _ in self?.onHistory?(1); return true },
            UIAccessibilityCustomAction(name: "Gesture settings") { [weak self] _ in self?.onSettings?(); return true }
        ]
    }
    required init?(coder: NSCoder) { fatalError() }

    @objc private func holdTitle(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began { onSettings?() }
    }
    @objc private func draftChanged() { onChange?() }

    override func focusComposer() { composer.field.becomeFirstResponder() }
    override func snapshot() -> ConversationState {
        ConversationState(
            draft: composer.field.text ?? "",
            readingPosition: didPosition ? Double(max(0, scroll.contentOffset.y + scroll.contentInset.top)) : initialReadingPosition,
            sentMessages: sentMessages
        )
    }
    override func renderPreview() -> UIImage {
        // Offscreen layer rendering cannot reproduce a live backdrop blur.
        // Give the preview header an opaque surface so text stays behind it.
        let effect = topBlur.effect
        let background = topBlur.backgroundColor
        let mask = topBlur.layer.mask
        topBlur.effect = nil; topBlur.backgroundColor = .black; topBlur.layer.mask = nil
        let format = UIGraphicsImageRendererFormat(); format.scale = 2; format.opaque = true
        let image = UIGraphicsImageRenderer(size: bounds.size, format: format).image { context in
            UIColor.black.setFill(); context.fill(bounds)
            layer.render(in: context.cgContext)
        }
        topBlur.effect = effect; topBlur.backgroundColor = background; topBlur.layer.mask = mask
        return image
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if didPosition && !isLayingOut { onChange?() }
    }
    override func updateHistoryMenu(back: Bool, forward: Bool) {
        more.menu = UIMenu(children: [
            UIAction(title: "Browse session stack", image: ChatStyle.symbol("square.stack.3d.up")) { [weak self] _ in self?.onBrowse?() },
            UIAction(title: "Previous session", image: ChatStyle.symbol("arrow.down"), attributes: back ? [] : .disabled) { [weak self] _ in self?.onHistory?(-1) },
            UIAction(title: "Next session", image: ChatStyle.symbol("arrow.up"), attributes: forward ? [] : .disabled) { [weak self] _ in self?.onHistory?(1) },
            UIAction(title: "All sessions", image: ChatStyle.symbol("list.bullet")) { [weak self] _ in self?.onBack?() },
            UIAction(title: "Gesture settings", image: ChatStyle.symbol("slider.horizontal.3")) { [weak self] _ in self?.onSettings?() },
            UIAction(title: "About this prototype", image: ChatStyle.symbol("info.circle")) { [weak self] _ in self?.onAccessory?("About") }
        ])
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0 else { return }
        isLayingOut = true
        defer { isLayingOut = false }
        let width = bounds.width
        let top = insets.top
        let bottom = keyboardHeight > 0 ? keyboardHeight : insets.bottom
        scroll.frame = bounds
        topBlur.frame = CGRect(x: 0, y: 0, width: width, height: top + 48)
        topFade.frame = topBlur.bounds
        backGlass.frame = CGRect(x: 16, y: top, width: 44, height: 44)
        actionsGlass.frame = CGRect(x: width - 124, y: top, width: 108, height: 44)
        titleArea.frame = CGRect(x: 72, y: top, width: max(0, width - 208), height: 48)
        title.frame = CGRect(x: 0, y: 3, width: titleArea.bounds.width, height: 24)
        subtitle.frame = CGRect(x: 0, y: 24, width: titleArea.bounds.width, height: 19)
        composer.frame = CGRect(x: keyboardHeight > 0 ? 14 : 38, y: bounds.height - bottom - 52, width: width - (keyboardHeight > 0 ? 28 : 76), height: 48)
        changesGlass.frame = CGRect(x: (width - 124) / 2, y: composer.frame.minY - 47, width: 124, height: 30)
        changes.frame = changesGlass.bounds
        changesGlass.isHidden = keyboardHeight > 0
        var y: CGFloat = 0
        for (index, message) in messages.enumerated() {
            let height = message.sizeThatFits(CGSize(width: width - 32, height: .greatestFiniteMagnitude)).height
            message.frame = CGRect(x: 16, y: y, width: width - 32, height: height)
            y += height + (index == messages.count - 1 ? 14 : 28)
        }
        reactions.frame = CGRect(x: 10, y: y, width: 140, height: 36)
        y += 42
        transcript.frame = CGRect(x: 0, y: 0, width: width, height: y)
        scroll.contentSize = transcript.bounds.size
        scroll.contentInset = UIEdgeInsets(top: top + 63, left: 0, bottom: bottom + (keyboardHeight > 0 ? 76 : 155), right: 0)
        if !didPosition {
            didPosition = true
            let maximum = max(-scroll.contentInset.top, y - bounds.height + scroll.contentInset.bottom)
            let proposed = initialReadingPosition.map { CGFloat($0) - scroll.contentInset.top } ?? maximum
            scroll.contentOffset.y = min(maximum, max(-scroll.contentInset.top, proposed))
        }
    }
    override func appendMessage(_ value: String) {
        sentMessages.append(value)
        composer.field.text = ""
        let item = TranscriptMessageView(.user(value))
        transcript.addSubview(item)
        messages.append(item)
        setNeedsLayout()
        layoutIfNeeded()
        scroll.setContentOffset(CGPoint(x: 0, y: max(-scroll.contentInset.top, scroll.contentSize.height - scroll.bounds.height + scroll.contentInset.bottom)), animated: true)
        onChange?()
    }
}

private final class TranscriptMessageView: UIView {
    private let isUser: Bool
    private var blocks: [UIView] = []
    init(_ message: SampleMessage) {
        isUser = message.isUser
        super.init(frame: .zero)
        if isUser {
            backgroundColor = UIColor(white: 0.13, alpha: 1)
            layer.cornerRadius = 22
            layer.cornerCurve = .continuous
        }
        for block in message.blocks {
            let item: UIView
            switch block {
            case .text(let text), .heading(let text):
                let body = UITextView()
                body.backgroundColor = .clear
                body.isEditable = false
                body.isScrollEnabled = false
                body.textContainerInset = .zero
                body.textContainer.lineFragmentPadding = 0
                let heading: Bool
                if case .heading = block { heading = true } else { heading = false }
                let style = NSMutableParagraphStyle()
                style.lineSpacing = 4
                body.attributedText = NSAttributedString(string: text, attributes: [
                    .font: UIFont.systemFont(ofSize: 17, weight: heading ? .semibold : .regular),
                    .foregroundColor: UIColor(white: 0.91, alpha: 1),
                    .paragraphStyle: style
                ])
                item = body
            case .code(let label, let text): item = CodeBlockView(label: label, code: text)
            case .checklist(let items): item = ChecklistView(items)
            }
            addSubview(item)
            blocks.append(item)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    private func arrange(width: CGFloat, apply: Bool) -> CGFloat {
        let available = isUser ? width * 0.88 : width
        let padding: CGFloat = isUser ? 14 : 0
        var y = padding
        for (index, block) in blocks.enumerated() {
            let height = ceil(block.sizeThatFits(CGSize(width: available - 2 * padding, height: .greatestFiniteMagnitude)).height)
            if apply { block.frame = CGRect(x: padding, y: y, width: available - 2 * padding, height: height) }
            y += height + (index < blocks.count - 1 ? 18 : 0)
        }
        return y + padding
    }
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: size.width, height: arrange(width: size.width, apply: false))
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        // The user bubble is inset on the leading side; the transcript keeps one alignment.
        let contentWidth = isUser ? bounds.width * 0.88 : bounds.width
        if isUser {
            backgroundColor = .clear
            if layer.sublayers?.first?.name != "bubble" {
                let bubble = CALayer()
                bubble.name = "bubble"
                bubble.backgroundColor = UIColor(white: 0.13, alpha: 1).cgColor
                bubble.cornerRadius = 22
                bubble.cornerCurve = .continuous
                layer.insertSublayer(bubble, at: 0)
            }
            layer.sublayers?.first?.frame = CGRect(x: bounds.width - contentWidth, y: 0, width: contentWidth, height: bounds.height)
        }
        _ = arrange(width: bounds.width, apply: true)
        if isUser {
            for block in blocks { block.frame.origin.x += bounds.width - contentWidth }
        }
    }
}

private final class CodeBlockView: UIView {
    private let header: UILabel
    private let codeView = UITextView()
    private let copyButton: UIButton
    init(label: String, code: String) {
        header = ChatStyle.label(label, size: 12, color: ChatStyle.secondary)
        copyButton = ChatStyle.button("doc.on.doc", label: "Copy code") { UIPasteboard.general.string = code }
        super.init(frame: .zero)
        backgroundColor = UIColor(white: 0.09, alpha: 1)
        layer.cornerRadius = 14
        layer.borderWidth = 0.5
        layer.borderColor = UIColor(white: 0.22, alpha: 1).cgColor
        codeView.backgroundColor = .clear
        codeView.isEditable = false
        codeView.isScrollEnabled = false
        codeView.font = .monospacedSystemFont(ofSize: 13.5, weight: .regular)
        codeView.textColor = UIColor(white: 0.88, alpha: 1)
        codeView.textContainerInset = .zero
        codeView.textContainer.lineFragmentPadding = 0
        codeView.text = code
        addSubview(header)
        addSubview(codeView)
        addSubview(copyButton)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: size.width, height: 52 + ceil(codeView.sizeThatFits(CGSize(width: size.width - 28, height: .greatestFiniteMagnitude)).height))
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        header.frame = CGRect(x: 14, y: 9, width: bounds.width - 60, height: 24)
        copyButton.frame = CGRect(x: bounds.width - 44, y: 0, width: 44, height: 40)
        codeView.frame = CGRect(x: 14, y: 40, width: bounds.width - 28, height: bounds.height - 52)
    }
}

private final class ChecklistView: UIView {
    private var rows: [(UIImageView, UILabel)] = []
    init(_ items: [ChecklistItem]) {
        super.init(frame: .zero)
        for item in items {
            let icon = UIImageView(image: ChatStyle.symbol(item.checked ? "checkmark.circle.fill" : "circle", size: 19))
            icon.tintColor = item.checked ? ChatStyle.green : UIColor(white: 0.4, alpha: 1)
            let label = ChatStyle.label(item.text, size: 16, color: item.checked ? ChatStyle.secondary : .white)
            label.numberOfLines = 0
            label.accessibilityLabel = (item.checked ? "Completed: " : "To do: ") + item.text
            addSubview(icon)
            addSubview(label)
            rows.append((icon, label))
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    private func arrange(width: CGFloat, apply: Bool) -> CGFloat {
        var y: CGFloat = 0
        for (icon, label) in rows {
            let height = max(24, ceil(label.sizeThatFits(CGSize(width: width - 31, height: .greatestFiniteMagnitude)).height))
            if apply {
                icon.frame = CGRect(x: 0, y: y + 2, width: 19, height: 19)
                label.frame = CGRect(x: 31, y: y, width: width - 31, height: height)
            }
            y += height + 14
        }
        return max(0, y - 14)
    }
    override func sizeThatFits(_ size: CGSize) -> CGSize { CGSize(width: size.width, height: arrange(width: size.width, apply: false)) }
    override func layoutSubviews() { super.layoutSubviews(); _ = arrange(width: bounds.width, apply: true) }
}
