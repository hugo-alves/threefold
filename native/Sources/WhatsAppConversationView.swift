import UIKit

enum WhatsAppStyle {
    static let green = UIColor(red: 0.15, green: 0.83, blue: 0.40, alpha: 1)
    static let wallpaper = UIColor(red: 0.035, green: 0.055, blue: 0.050, alpha: 1)
    static let incoming = UIColor(red: 0.12, green: 0.15, blue: 0.16, alpha: 1)
    static let outgoing = UIColor(red: 0.02, green: 0.30, blue: 0.23, alpha: 1)
    static func avatar(group: Bool, size: CGFloat) -> UIImageView {
        let image = UIImageView(image: UIImage(systemName: group ? "person.2.circle.fill" : "person.crop.circle.fill"))
        image.tintColor = UIColor(white: 0.51, alpha: 1)
        image.backgroundColor = UIColor(white: 0.19, alpha: 1)
        image.layer.cornerRadius = size / 2; image.clipsToBounds = true
        image.contentMode = .scaleAspectFit
        return image
    }
}

final class WhatsAppConversationView: ConversationSurface, UIScrollViewDelegate {
    private let chat: WhatsAppChat
    private let transcript = UIView()
    private var bubbles: [WhatsAppBubbleView] = []
    private var sentMessages: [String]
    private var didPosition = false
    private var layingOut = false
    private let initialReadingPosition: Double?
    private let topBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
    private let topFade = CAGradientLayer()
    private let backGlass = GlassView(radius: 22)
    private let callsGlass = GlassView(radius: 22)
    private let contactGlass = GlassView(radius: 23)
    private let contact = UIButton(type: .system)
    private let name: UILabel
    private let status: UILabel
    private let avatar: UIImageView
    private let day = ChatStyle.label("Today", size: 11, weight: .medium, color: UIColor(white: 0.76, alpha: 1))
    private let encryption = ChatStyle.label("Messages and calls are end-to-end encrypted.\nThis is a local demo with fictional conversations.", size: 11, color: UIColor(red: 0.77, green: 0.72, blue: 0.48, alpha: 1))
    private lazy var composer = WhatsAppComposerView { [weak self] in self?.onAccessory?($0) }

    init(_ session: SampleSession, state: ConversationState) {
        chat = WhatsAppData.chat(session.id)
        sentMessages = state.sentMessages
        initialReadingPosition = state.readingPosition
        name = ChatStyle.label(chat.name, size: 16, weight: .semibold)
        status = ChatStyle.label(chat.status, size: 11, color: ChatStyle.secondary)
        avatar = WhatsAppStyle.avatar(group: chat.group, size: 36)
        super.init(session)
        backgroundColor = WhatsAppStyle.wallpaper
        scroll.backgroundColor = .clear
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.panGestureRecognizer.maximumNumberOfTouches = 1
        scroll.showsVerticalScrollIndicator = false
        scroll.keyboardDismissMode = .interactive
        scroll.accessibilityIdentifier = "conversationScroll"
        scroll.delegate = self
        addSubview(scroll); scroll.addSubview(transcript)
        day.textAlignment = .center; day.backgroundColor = UIColor(white: 0.12, alpha: 0.95)
        day.layer.cornerRadius = 7; day.clipsToBounds = true
        encryption.numberOfLines = 0; encryption.textAlignment = .center
        transcript.addSubview(day); transcript.addSubview(encryption)
        for message in chat.messages { addBubble(message) }
        for text in state.sentMessages { addBubble(.init(text: text, time: "18:44", outgoing: true)) }
        topBlur.isUserInteractionEnabled = false
        topBlur.contentView.backgroundColor = UIColor.black.withAlphaComponent(0.28)
        topFade.colors = [UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
        topFade.locations = [0, 0.72, 1]
        topBlur.layer.mask = topFade
        addSubview(topBlur)
        addSubview(backGlass); addSubview(callsGlass); addSubview(contactGlass)
        contactGlass.content.addSubview(contact)
        contact.addSubview(avatar); contact.addSubview(name); contact.addSubview(status)
        name.lineBreakMode = .byTruncatingTail; status.lineBreakMode = .byTruncatingTail
        name.accessibilityIdentifier = "conversationTitle"
        name.accessibilityHint = "Touch and hold for prototype controls"
        contact.accessibilityLabel = chat.name + ", " + chat.status
        contact.accessibilityIdentifier = "conversationOptions"
        contact.showsMenuAsPrimaryAction = true
        name.isUserInteractionEnabled = true
        name.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(holdTitle(_:))))
        let back = ChatStyle.button("chevron.left", label: "Back to chats") { [weak self] in self?.onBack?() }
        back.frame = CGRect(x: 0, y: 0, width: 44, height: 44); backGlass.content.addSubview(back)
        let video = ChatStyle.button("video", label: "Video call") { [weak self] in self?.onAccessory?("Video call") }
        let call = ChatStyle.button("phone", label: "Voice call") { [weak self] in self?.onAccessory?("Voice call") }
        video.frame = CGRect(x: 2, y: 0, width: 44, height: 44)
        call.frame = CGRect(x: 47, y: 0, width: 44, height: 44)
        callsGlass.content.addSubview(video); callsGlass.content.addSubview(call)
        addSubview(composer)
        composer.field.text = state.draft; composer.refresh()
        composer.onSubmit = { [weak self] in self?.appendMessage($0) }
        composer.field.addTarget(self, action: #selector(draftChanged), for: .editingChanged)
        accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "Older chat") { [weak self] _ in self?.onHistory?(-1); return true },
            UIAccessibilityCustomAction(name: "Newer chat") { [weak self] _ in self?.onHistory?(1); return true },
            UIAccessibilityCustomAction(name: "Browse chat stack") { [weak self] _ in self?.onBrowse?(); return true },
            UIAccessibilityCustomAction(name: "Prototype controls") { [weak self] _ in self?.onSettings?(); return true }
        ]
    }
    required init?(coder: NSCoder) { fatalError() }
    @objc private func holdTitle(_ recognizer: UILongPressGestureRecognizer) { if recognizer.state == .began { onSettings?() } }
    @objc private func draftChanged() { onChange?() }
    private func addBubble(_ message: WhatsAppMessage) {
        let bubble = WhatsAppBubbleView(message)
        transcript.addSubview(bubble); bubbles.append(bubble)
    }
    override func focusComposer() { composer.field.becomeFirstResponder() }
    override func snapshot() -> ConversationState {
        .init(draft: composer.field.text ?? "", readingPosition: didPosition ? Double(max(0, scroll.contentOffset.y + scroll.contentInset.top)) : initialReadingPosition, sentMessages: sentMessages)
    }
    override func updateHistoryMenu(back: Bool, forward: Bool) {
        contact.menu = UIMenu(children: [
            UIAction(title: "Browse chat stack", image: ChatStyle.symbol("square.stack.3d.up")) { [weak self] _ in self?.onBrowse?() },
            UIAction(title: "Older chat", image: ChatStyle.symbol("arrow.down"), attributes: back ? [] : .disabled) { [weak self] _ in self?.onHistory?(-1) },
            UIAction(title: "Newer chat", image: ChatStyle.symbol("arrow.up"), attributes: forward ? [] : .disabled) { [weak self] _ in self?.onHistory?(1) },
            UIAction(title: "All chats", image: ChatStyle.symbol("bubble.left.and.bubble.right")) { [weak self] _ in self?.onBack?() },
            UIAction(title: "Prototype controls", image: ChatStyle.symbol("slider.horizontal.3")) { [weak self] _ in self?.onSettings?() },
            UIAction(title: "About this prototype", image: ChatStyle.symbol("info.circle")) { [weak self] _ in self?.onAccessory?("About") }
        ])
    }
    override func renderPreview() -> UIImage {
        let effect = topBlur.effect; let mask = topBlur.layer.mask
        topBlur.effect = nil; topBlur.layer.mask = nil; topBlur.backgroundColor = WhatsAppStyle.wallpaper
        let format = UIGraphicsImageRendererFormat(); format.scale = 2; format.opaque = true
        let image = UIGraphicsImageRenderer(size: bounds.size, format: format).image { context in
            WhatsAppStyle.wallpaper.setFill(); context.fill(bounds); layer.render(in: context.cgContext)
        }
        topBlur.effect = effect; topBlur.layer.mask = mask; topBlur.backgroundColor = .clear
        return image
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) { if didPosition && !layingOut { onChange?() } }
    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0 else { return }
        layingOut = true; defer { layingOut = false }
        let width = bounds.width; let top = insets.top
        let bottom = keyboardHeight > 0 ? keyboardHeight : insets.bottom
        scroll.frame = bounds
        topBlur.frame = CGRect(x: 0, y: 0, width: width, height: top + 65); topFade.frame = topBlur.bounds
        backGlass.frame = CGRect(x: 12, y: top + 1, width: 44, height: 44)
        callsGlass.frame = CGRect(x: width - 106, y: top + 1, width: 94, height: 44)
        let contactWidth = min(width - 174, 44 + max(70, ceil(name.intrinsicContentSize.width) + 20))
        contactGlass.frame = CGRect(x: 64, y: top, width: contactWidth, height: 47)
        contact.frame = contactGlass.bounds
        avatar.frame = CGRect(x: 0, y: 5, width: 36, height: 36)
        name.frame = CGRect(x: 44, y: 5, width: contact.bounds.width - 46, height: 21)
        status.frame = CGRect(x: 44, y: 26, width: contact.bounds.width - 46, height: 16)
        composer.frame = CGRect(x: 8, y: bounds.height - bottom - 54, width: width - 16, height: 48)
        day.frame = CGRect(x: (width - 66) / 2, y: 0, width: 66, height: 22)
        encryption.frame = CGRect(x: 36, y: 34, width: width - 72, height: 42)
        var y: CGFloat = 91
        for (index, bubble) in bubbles.enumerated() {
            let size = bubble.sizeThatFits(CGSize(width: width * 0.79, height: .greatestFiniteMagnitude))
            bubble.frame = CGRect(x: bubble.outgoing ? width - size.width - 12 : 12, y: y, width: size.width, height: size.height)
            let sameSide = index + 1 < bubbles.count && bubbles[index + 1].outgoing == bubble.outgoing
            y += size.height + (sameSide ? 4 : 12)
        }
        transcript.frame = CGRect(x: 0, y: 0, width: width, height: y + 10)
        scroll.contentSize = transcript.bounds.size
        scroll.contentInset = .init(top: top + 62, left: 0, bottom: bottom + 76, right: 0)
        if !didPosition {
            didPosition = true
            let maximum = max(-scroll.contentInset.top, transcript.bounds.height - bounds.height + scroll.contentInset.bottom)
            let proposed = initialReadingPosition.map { CGFloat($0) - scroll.contentInset.top } ?? maximum
            scroll.contentOffset.y = min(maximum, max(-scroll.contentInset.top, proposed))
        }
    }
    override func appendMessage(_ value: String) {
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        sentMessages.append(value); composer.field.text = ""; composer.refresh()
        addBubble(.init(text: value, time: "18:44", outgoing: true))
        setNeedsLayout(); layoutIfNeeded()
        scroll.setContentOffset(CGPoint(x: 0, y: max(-scroll.contentInset.top, scroll.contentSize.height - scroll.bounds.height + scroll.contentInset.bottom)), animated: true)
        onChange?()
    }
}

private final class WhatsAppBubbleView: UIView, UIContextMenuInteractionDelegate {
    let outgoing: Bool
    private let message: WhatsAppMessage
    private let body: UILabel
    private let sender: UILabel?
    private let time: UILabel
    private let ticks = UIImageView(image: ChatStyle.symbol("checkmark", size: 10))
    init(_ message: WhatsAppMessage) {
        self.message = message; outgoing = message.outgoing
        body = ChatStyle.label(message.text, size: 16, color: UIColor(white: 0.94, alpha: 1)); body.numberOfLines = 0
        sender = message.sender.map { ChatStyle.label($0, size: 12, weight: .semibold, color: UIColor(red: 0.48, green: 0.78, blue: 0.87, alpha: 1)) }
        time = ChatStyle.label(message.time, size: 10, color: UIColor(white: 0.65, alpha: 1))
        super.init(frame: .zero)
        backgroundColor = outgoing ? WhatsAppStyle.outgoing : WhatsAppStyle.incoming
        layer.cornerRadius = 18; layer.cornerCurve = .continuous
        addSubview(body); addSubview(time)
        if let sender { addSubview(sender) }
        ticks.tintColor = UIColor(red: 0.38, green: 0.76, blue: 0.94, alpha: 1)
        if outgoing { addSubview(ticks) }
        addInteraction(UIContextMenuInteraction(delegate: self))
        isAccessibilityElement = true
        accessibilityLabel = (outgoing ? "You" : (message.sender ?? "Contact")) + ": " + message.text + ", " + message.time
    }
    required init?(coder: NSCoder) { fatalError() }
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let textSize = body.sizeThatFits(CGSize(width: size.width - 24, height: .greatestFiniteMagnitude))
        let singleLine = textSize.height < 25 && sender == nil && textSize.width + 82 <= size.width
        let width = min(size.width, max(sender == nil ? 82 : 125, textSize.width + (singleLine ? 82 : 24)))
        return CGSize(width: ceil(width), height: ceil(textSize.height) + (sender == nil ? 0 : 19) + (singleLine ? 17 : 31))
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        let senderHeight: CGFloat = sender == nil ? 0 : 19
        sender?.frame = CGRect(x: 12, y: 7, width: bounds.width - 24, height: 17)
        let singleLine = bounds.height < 45 && sender == nil
        body.frame = CGRect(x: 12, y: 7 + senderHeight, width: bounds.width - (singleLine ? 76 : 24), height: bounds.height - (singleLine ? 14 : 28) - senderHeight)
        time.frame = CGRect(x: bounds.width - (outgoing ? 51 : 42), y: bounds.height - 18, width: 33, height: 14)
        ticks.frame = CGRect(x: bounds.width - 18, y: bounds.height - 14, width: 10, height: 10)
    }
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            UIMenu(children: [UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { _ in UIPasteboard.general.string = self?.message.text }])
        }
    }
}

private final class WhatsAppComposerView: UIView, UITextFieldDelegate {
    let field = UITextField()
    var onSubmit: ((String) -> Void)?
    private let entry = GlassView(radius: 23)
    private let plus = GlassView(radius: 22)
    private let camera = GlassView(radius: 22)
    private let action = UIButton(type: .system)
    private let sticker: UIButton
    private let accessory: (String) -> Void
    init(accessory: @escaping (String) -> Void) {
        self.accessory = accessory
        sticker = ChatStyle.button("square.on.circle", label: "Stickers") { accessory("Stickers") }
        super.init(frame: .zero)
        addSubview(entry); addSubview(plus); addSubview(camera); addSubview(action)
        let attach = ChatStyle.button("plus", label: "Add attachment") { accessory("Attachments") }
        attach.frame = CGRect(x: 0, y: 0, width: 44, height: 44); plus.content.addSubview(attach)
        let photo = ChatStyle.button("camera", label: "Camera") { accessory("Camera") }
        photo.frame = CGRect(x: 0, y: 0, width: 44, height: 44); camera.content.addSubview(photo)
        field.font = .systemFont(ofSize: 16); field.textColor = .white
        field.accessibilityLabel = "Message"; field.accessibilityIdentifier = "composer"
        field.returnKeyType = .send; field.delegate = self
        field.addTarget(self, action: #selector(changed), for: .editingChanged)
        entry.content.addSubview(field); entry.content.addSubview(sticker)
        action.backgroundColor = WhatsAppStyle.green; action.tintColor = .black; action.layer.cornerRadius = 22
        action.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            if self.hasText { self.submit() } else { self.accessory("Voice message") }
        }, for: .touchUpInside)
        refresh()
    }
    required init?(coder: NSCoder) { fatalError() }
    private var hasText: Bool { !(field.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) }
    @objc private func changed() { refresh() }
    func refresh() {
        action.setImage(ChatStyle.symbol(hasText ? "arrow.up" : "mic.fill", size: 20, weight: .medium), for: .normal)
        action.accessibilityLabel = hasText ? "Send message locally" : "Voice message"
        camera.isHidden = hasText; setNeedsLayout()
    }
    private func submit() {
        guard let text = field.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        onSubmit?(text); field.text = ""; refresh()
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool { submit(); return false }
    override func layoutSubviews() {
        super.layoutSubviews()
        plus.frame = CGRect(x: 0, y: 2, width: 44, height: 44)
        action.frame = CGRect(x: bounds.width - 44, y: 2, width: 44, height: 44)
        camera.frame = CGRect(x: bounds.width - 94, y: 2, width: 44, height: 44)
        entry.frame = CGRect(x: 50, y: 2, width: bounds.width - (hasText ? 100 : 150), height: 44)
        sticker.frame = CGRect(x: entry.bounds.width - 38, y: 0, width: 34, height: 44)
        field.frame = CGRect(x: 14, y: 0, width: max(0, entry.bounds.width - 56), height: 44)
    }
}
