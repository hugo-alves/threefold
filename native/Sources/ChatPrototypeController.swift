import UIKit

final class ChatPrototypeController: UIViewController, UIGestureRecognizerDelegate, UIAdaptivePresentationControllerDelegate {
    private let surface = UIView()
    private let sidebar = SidebarView()
    private let list: SessionListSurface = DemoBrand.isWhatsApp ? WhatsAppListView() : SessionListView()
    private let dim = UIButton(type: .custom)
    private let statusBarShield = UIView()
    private let firstHint = FirstSwipeHintView()
    private let historyPosition = HistoryPositionView()
    private let store: PrototypeStore
    private var state: PrototypeState
    private var history: SessionHistory {
        get { state.history }
        set { state.history = newValue }
    }
    private var conversations: [String: ConversationSurface] = [:]
    private var active: ConversationSurface?
    private var preview: ConversationSurface?
    private var overview: SessionOverviewView?
    private var pendingCursor: Int?
    private var touchDots: [UIView] = []
    private var sidebarOpen = false
    private var busy = false
    private var direction = 0
    private var keyboardHeight: CGFloat = 0
    private var pan: UIPanGestureRecognizer!
    private var haptic: UIImpactFeedbackGenerator?
    private var saveWork: DispatchWorkItem?
    private var interactionWasGesture = false
    private var appliedPreview = false
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { [] }

    init() {
        var filename = "state.json"
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--ui-testing") { filename = "ui-test-state.json" }
        if args.contains("--preview-screen") { filename = "preview-state.json" }
        #endif
        let store = PrototypeStore(filename: filename)
        self.store = store
        #if DEBUG
        if args.contains("--reset-test-state") && filename == "ui-test-state.json" {
            try? FileManager.default.removeItem(at: store.url)
        }
        state = args.contains("--preview-screen") ? PrototypeState() : (store.load() ?? PrototypeState())
        #else
        state = store.load() ?? PrototypeState()
        #endif
        state.history = state.history.restored(allowing: Set(SampleData.sessions.map(\.id)), fallback: PrototypeState.seedHistory)
        state.history.includeEarlierSessions(PrototypeState.seedHistory)
        if !state.hasLearnedOverview { state.hasLearnedGesture = false }
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        surface.backgroundColor = .black
        surface.layer.cornerCurve = .continuous
        view.addSubview(sidebar)
        sidebar.accessibilityElementsHidden = true
        view.addSubview(surface)
        surface.addSubview(list)
        dim.backgroundColor = UIColor(white: 0.10, alpha: 0.72)
        dim.alpha = 0
        dim.isHidden = true
        dim.accessibilityLabel = "Close sidebar"
        dim.addAction(UIAction { [weak self] _ in self?.toggleSidebar(false) }, for: .touchUpInside)
        surface.addSubview(dim)
        statusBarShield.backgroundColor = .black
        statusBarShield.isUserInteractionEnabled = false
        statusBarShield.isHidden = true
        view.addSubview(statusBarShield)
        list.onOpen = { [weak self] in self?.open($0) }
        list.onSidebar = { [weak self] in self?.toggleSidebar(true) }
        list.onSearch = { [weak self] in self?.search() }
        list.onAccessory = { [weak self] in self?.showAccessory($0) }
        list.onNew = { [weak self] value in self?.open(DemoBrand.starterID); self?.active?.appendMessage(value) }
        sidebar.onClose = { [weak self] in self?.toggleSidebar(false) }
        sidebar.onOpen = { [weak self] id in self?.toggleSidebar(false); self?.open(id) }
        sidebar.onAccessory = { [weak self] in self?.showAccessory($0) }
        sidebar.onSearch = { [weak self] in self?.search() }
        firstHint.onDismiss = { [weak self] in
            self?.state.hasLearnedGesture = true
            self?.state.hasLearnedOverview = true
            self?.refreshFirstHint()
            self?.saveState()
        }
        view.addSubview(firstHint)
        view.addSubview(historyPosition)
        historyPosition.onBrowse = { [weak self] in self?.openOverview() }
        pan = UIPanGestureRecognizer(target: self, action: #selector(drag(_:)))
        pan.minimumNumberOfTouches = 3
        pan.maximumNumberOfTouches = 3
        pan.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.direct.rawValue)]
        pan.delegate = self
        surface.addGestureRecognizer(pan)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChanged(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(accessibilityChanged), name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(saveState), name: UIApplication.willResignActiveNotification, object: nil)
        accessibilityChanged()
        open(history.current)
    }
    deinit { NotificationCenter.default.removeObserver(self); saveWork?.cancel() }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshFirstHint()
        #if DEBUG
        guard !appliedPreview else { return }
        appliedPreview = true
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "--preview-screen"), arguments.indices.contains(index + 1) {
            state.hasLearnedGesture = true; state.hasLearnedOverview = true; refreshFirstHint()
            switch arguments[index + 1] {
            case "list": showList()
            case "conversation":
                if let option = arguments.firstIndex(of: "--preview-session"), arguments.indices.contains(option + 1),
                   let index = history.entries.firstIndex(of: arguments[option + 1]) {
                    history.select(index); open(history.current)
                } else { open(DemoBrand.previewID) }
            case "code": open(DemoBrand.starterID)
            case "sidebar": showList(); toggleSidebar(true)
            case "settings": showSettings()
            case "overview": openOverview()
            case "smoke-overview": runOverviewSmoke()
            case "overview-gesture":
                beginSwitch(isGesture: true)
                update(CGFloat(state.settings.overviewDistance))
                openOverview(fromGesture: true)
            case "history":
                beginSwitch(isGesture: true)
                update(CGFloat(state.settings.swipeDistance) * 1.1)
            default: break
            }
        }
        #endif
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let insets = view.safeAreaInsets
        sidebar.frame = CGRect(x: 0, y: 0, width: view.bounds.width * 0.77, height: view.bounds.height)
        sidebar.insets = insets
        surface.bounds = view.bounds
        surface.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        surface.transform = sidebarOpen ? CGAffineTransform(translationX: sidebar.bounds.width, y: 0) : .identity
        list.frame = surface.bounds
        list.insets = insets
        for conversation in [active, preview].compactMap({ $0 }) {
            conversation.bounds = surface.bounds
            conversation.center = CGPoint(x: surface.bounds.midX, y: surface.bounds.midY)
            conversation.insets = insets
            conversation.keyboardHeight = keyboardHeight
        }
        dim.frame = surface.bounds
        statusBarShield.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: insets.top)
        firstHint.frame = CGRect(x: 16, y: view.bounds.height - insets.bottom - 187, width: view.bounds.width - 32, height: 72)
        let indicatorScale = CGFloat(state.settings.indicatorSize)
        historyPosition.bounds = CGRect(x: 0, y: 0, width: 52, height: historyPosition.preferredHeight)
        historyPosition.center = CGPoint(x: view.bounds.width - 27 * indicatorScale, y: view.bounds.height * 0.48)
        historyPosition.transform = CGAffineTransform(scaleX: indicatorScale, y: indicatorScale)
        overview?.frame = view.bounds
    }

    private func conversation(_ id: String) -> ConversationSurface {
        if let saved = conversations[id] { return saved }
        let sample = SampleData.session(id)
        let saved = state.conversations[id] ?? ConversationState()
        let result: ConversationSurface = DemoBrand.isWhatsApp ? WhatsAppConversationView(sample, state: saved) : ConversationView(sample, state: saved)
        result.onBack = { [weak self] in self?.showList() }
        result.onNew = { [weak self] in self?.newConversation() }
        result.onHistory = { [weak self] in self?.navigate($0) }
        result.onAccessory = { [weak self] in self?.showAccessory($0) }
        result.onSettings = { [weak self] in self?.showSettings() }
        result.onBrowse = { [weak self] in self?.openOverview() }
        result.onChange = { [weak self] in self?.queueSave() }
        conversations[id] = result
        return result
    }
    private func mount(_ conversation: ConversationSurface) {
        conversation.transform = .identity
        presentAsCard(conversation, progress: 0)
        conversation.alpha = 1
        conversation.frame = surface.bounds
        conversation.insets = view.safeAreaInsets
        conversation.keyboardHeight = keyboardHeight
        conversation.isUserInteractionEnabled = true
        conversation.accessibilityElementsHidden = false
        surface.insertSubview(conversation, belowSubview: dim)
        conversation.layoutIfNeeded()
    }
    private func open(_ id: String) {
        guard !busy else { return }
        view.endEditing(true)
        history.visit(id)
        active?.removeFromSuperview()
        let next = conversation(id)
        active = next
        mount(next)
        list.isHidden = true
        next.updateHistoryMenu(back: history.canGoBack, forward: history.canGoForward)
        refreshFirstHint()
        saveState()
    }
    private func showList() {
        guard !busy else { return }
        view.endEditing(true)
        saveState()
        active?.removeFromSuperview()
        active = nil
        list.isHidden = false
        refreshFirstHint()
    }
    private func toggleSidebar(_ show: Bool) {
        guard !busy else { return }
        view.endEditing(true)
        sidebarOpen = show
        dim.isHidden = false
        surface.clipsToBounds = show
        UIView.animate(withDuration: UIAccessibility.isReduceMotionEnabled ? 0 : 0.32, delay: 0, usingSpringWithDamping: 0.92, initialSpringVelocity: 0) {
            self.surface.transform = show ? CGAffineTransform(translationX: self.sidebar.bounds.width, y: 0) : .identity
            self.surface.layer.cornerRadius = show ? 56 : 0
            self.dim.alpha = show ? 1 : 0
        } completion: { _ in self.dim.isHidden = !show }
        surface.accessibilityElementsHidden = show
        sidebar.accessibilityElementsHidden = !show
        refreshFirstHint()
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard active != nil, !busy, overview == nil, !sidebarOpen, presentedViewController == nil, let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        let velocity = pan.velocity(in: surface)
        return abs(velocity.y) > abs(velocity.x) * 1.35
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        otherGestureRecognizer is UIPanGestureRecognizer
    }
    private func beginSwitch(isGesture: Bool) {
        busy = true
        direction = 0
        pendingCursor = nil
        interactionWasGesture = isGesture
        if state.settings.haptics != .off {
            haptic = UIImpactFeedbackGenerator(style: state.settings.haptics == .soft ? .soft : .medium)
            haptic?.prepare()
        } else { haptic = nil }
        active?.scroll.isScrollEnabled = false
        statusBarShield.isHidden = false
        refreshFirstHint()
    }
    private var switchTravel: CGFloat { surface.bounds.height + CGFloat(state.settings.cardSpacing) }

    private func presentAsCard(_ conversation: ConversationSurface, progress: CGFloat) {
        conversation.layer.cornerCurve = .continuous
        conversation.layer.cornerRadius = CGFloat(state.settings.cornerRadius) * progress
        conversation.layer.borderWidth = progress / max(1, view.window?.screen.scale ?? 3)
        conversation.layer.borderColor = UIColor.white.withAlphaComponent(0.16).cgColor
        conversation.clipsToBounds = progress > 0
    }

    private func cardTransform(y: CGFloat, progress: CGFloat) -> CGAffineTransform {
        let scale = 1 - (1 - CGFloat(state.settings.cardScale)) * progress
        return CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: 0, ty: y)
    }

    @objc private func drag(_ pan: UIPanGestureRecognizer) {
        updateTouchDots(pan)
        let dy = pan.translation(in: surface).y
        switch pan.state {
        case .began: beginSwitch(isGesture: true); update(dy)
        case .changed: update(dy)
        case .ended:
            let velocity = pan.velocity(in: surface).y
            releaseSwitch(distance: dy, velocity: velocity)
        case .cancelled, .failed: finish(false, velocity: 0)
        default: break
        }
    }
    private func releaseSwitch(distance: CGFloat, velocity: CGFloat) {
        if SwipeDecision.shouldOpenOverview(distance: Double(distance), velocity: Double(velocity), height: Double(surface.bounds.height), settings: state.settings) {
            openOverview(fromGesture: true)
            return
        }
        let commit = SwipeDecision.shouldCommit(distance: Double(distance), velocity: Double(velocity), height: Double(surface.bounds.height), settings: state.settings)
        finish(commit, velocity: velocity)
    }
    private func update(_ dy: CGFloat) {
        guard let active else { return }
        guard dy != 0 || direction != 0 else { return }
        let nextDirection = dy == 0 ? direction : SwipeDecision.historyStep(forTranslation: Double(dy))
        if nextDirection != direction {
            preview?.isUserInteractionEnabled = true
            preview?.accessibilityElementsHidden = false
            preview?.removeFromSuperview()
            preview = nil
            direction = nextDirection
            if let id = history.destination(direction) {
                let next = conversation(id)
                mount(next)
                next.isUserInteractionEnabled = false
                next.accessibilityElementsHidden = true
                surface.insertSubview(next, belowSubview: active)
                preview = next
            }
        }
        let height = switchTravel
        let displacement = preview == nil ? dy * 0.17 : max(-height, min(height, dy))
        if !UIAccessibility.isReduceMotionEnabled {
            let peak = min(CGFloat(state.settings.overviewDistance), height * 0.45)
            let distance = abs(displacement)
            let cardProgress: CGFloat = distance <= peak ? distance / peak : max(0, (height - distance) / (height - peak))
            // A quiet gutter and two bounded surfaces distinguish chat history
            // from scrolling through one continuous transcript.
            surface.backgroundColor = UIColor(white: 0.085 * cardProgress, alpha: 1)
            presentAsCard(active, progress: cardProgress)
            if let preview { presentAsCard(preview, progress: cardProgress) }
            active.transform = cardTransform(y: displacement, progress: cardProgress)
            let scale = 1 - (1 - CGFloat(state.settings.cardScale)) * cardProgress
            let previewTravel = surface.bounds.height * scale + CGFloat(state.settings.cardSpacing)
            preview?.transform = cardTransform(y: displacement + CGFloat(direction) * previewTravel, progress: cardProgress)
        } else {
            preview?.alpha = 0
        }
    }
    private func finish(_ requested: Bool, velocity: CGFloat) {
        guard busy, let outgoing = active else { return }
        let commit = requested && preview != nil
        let incoming = preview
        let height = switchTravel
        let movementDirection = direction
        let targetY = commit ? -CGFloat(movementDirection) * height : 0
        let remaining = targetY - outgoing.transform.ty
        let duration = SwipeDecision.settleDuration(remaining: Double(remaining), height: Double(height), velocity: Double(velocity), settings: state.settings)
        if commit {
            pendingCursor = history.cursor + movementDirection
            view.endEditing(true)
            // One tactile event at the decision, never a second tap at animation completion.
            haptic?.impactOccurred()
            if interactionWasGesture { state.hasLearnedGesture = true }
            refreshFirstHint()
        }
        let animations = {
            outgoing.transform = commit ? self.cardTransform(y: targetY, progress: 1) : .identity
            incoming?.transform = commit ? .identity : self.cardTransform(y: CGFloat(movementDirection) * height, progress: 1)
            if commit, let incoming { self.presentAsCard(incoming, progress: 0) }
            if !commit { self.presentAsCard(outgoing, progress: 0) }
            incoming?.alpha = 1
        }
        let complete = {
            if commit {
                self.history.move(movementDirection)
                outgoing.removeFromSuperview()
                self.active = incoming
            } else { incoming?.removeFromSuperview() }
            outgoing.transform = .identity
            self.presentAsCard(outgoing, progress: 0)
            outgoing.scroll.isScrollEnabled = true
            incoming?.alpha = 1
            incoming?.transform = .identity
            incoming?.isUserInteractionEnabled = true
            incoming?.accessibilityElementsHidden = false
            if let incoming { self.presentAsCard(incoming, progress: 0) }
            self.surface.backgroundColor = .black
            self.active?.updateHistoryMenu(back: self.history.canGoBack, forward: self.history.canGoForward)
            self.preview = nil
            self.direction = 0
            self.pendingCursor = nil
            self.busy = false
            self.haptic = nil
            self.statusBarShield.isHidden = true
            self.refreshFirstHint()
            self.saveState()
            if commit { UIAccessibility.post(notification: .announcement, argument: SampleData.session(self.history.current).title) }
        }
        if UIAccessibility.isReduceMotionEnabled {
            complete()
        } else {
            let normalizedVelocity = abs(remaining) > 1 ? max(-3, min(10, velocity / remaining)) : 0
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: CGFloat(state.settings.springDamping),
                           initialSpringVelocity: normalizedVelocity, options: .beginFromCurrentState,
                           animations: animations) { _ in complete() }
        }
    }
    private func navigate(_ direction: Int) {
        guard !busy, active != nil, history.destination(direction) != nil else { return }
        beginSwitch(isGesture: false)
        update(-CGFloat(direction) * 48)
        finish(true, velocity: 0)
    }

    private func previewImage(_ conversation: ConversationSurface) -> UIImage {
        let transform = conversation.transform
        let radius = conversation.layer.cornerRadius
        let border = conversation.layer.borderWidth
        let clipping = conversation.clipsToBounds
        conversation.transform = .identity
        conversation.bounds = surface.bounds
        conversation.insets = view.safeAreaInsets
        conversation.keyboardHeight = 0
        conversation.layer.cornerRadius = 0; conversation.layer.borderWidth = 0; conversation.clipsToBounds = true
        conversation.layoutIfNeeded()
        let image = conversation.renderPreview()
        conversation.transform = transform
        conversation.layer.cornerRadius = radius; conversation.layer.borderWidth = border; conversation.clipsToBounds = clipping
        return image
    }

    private func openOverview(fromGesture: Bool = false) {
        guard overview == nil, active != nil, !sidebarOpen, presentedViewController == nil, (!busy || fromGesture) else { return }
        if state.settings.haptics != .off {
            UIImpactFeedbackGenerator(style: state.settings.haptics == .soft ? .soft : .medium).impactOccurred()
        }
        view.endEditing(true)
        guard let current = active else { return }
        let origin = current.convert(current.bounds, to: view)
        let image = previewImage(current)
        busy = true
        let images = history.entries.map { previewImage(conversation($0)) }
        let stack = SessionOverviewView(entries: history.entries, images: images, current: history.cursor, settings: state.settings)
        stack.frame = view.bounds
        stack.onSelect = { [weak self] in self?.closeOverview(selecting: $0) }
        stack.onClose = { [weak self] in guard let self else { return }; self.closeOverview(selecting: self.history.cursor) }
        stack.onSettings = { [weak self] in self?.showSettings() }
        overview = stack
        view.addSubview(stack); stack.layoutIfNeeded()
        let target = stack.imageFrame(at: history.cursor) ?? view.bounds.insetBy(dx: 40, dy: 100)
        let flying = UIImageView(image: image)
        flying.frame = origin; flying.contentMode = .scaleToFill; flying.clipsToBounds = true
        flying.layer.cornerCurve = .continuous; flying.layer.cornerRadius = current.layer.cornerRadius
        view.addSubview(flying)
        statusBarShield.isHidden = false
        view.bringSubviewToFront(statusBarShield)
        stack.cards.alpha = 0; stack.alpha = 0
        current.alpha = 0
        state.hasLearnedGesture = true; state.hasLearnedOverview = true
        refreshFirstHint()
        let duration = UIAccessibility.isReduceMotionEnabled ? 0 : 0.44 / state.settings.animationSpeed
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: CGFloat(state.settings.springDamping), initialSpringVelocity: 0, options: .beginFromCurrentState) {
            stack.alpha = 1
            flying.frame = target
            flying.layer.cornerRadius = CGFloat(self.state.settings.cornerRadius)
        } completion: { _ in
            stack.cards.alpha = 1; flying.removeFromSuperview()
            self.preview?.removeFromSuperview(); self.preview = nil
            current.transform = .identity; current.alpha = 1; current.scroll.isScrollEnabled = true
            self.presentAsCard(current, progress: 0)
            self.surface.backgroundColor = .black; self.statusBarShield.isHidden = true
            self.direction = 0; self.pendingCursor = nil; self.busy = false; self.haptic = nil
            self.refreshFirstHint(); self.saveState()
            UIAccessibility.post(notification: .screenChanged, argument: stack)
        }
    }

    private func closeOverview(selecting index: Int) {
        guard !busy, let stack = overview, history.entries.indices.contains(index) else { return }
        if index != history.cursor && state.settings.haptics != .off {
            UIImpactFeedbackGenerator(style: state.settings.haptics == .soft ? .soft : .medium).impactOccurred()
        }
        busy = true
        let origin = stack.imageFrame(at: index)
        let image = stack.images[index]
        history.select(index)
        active?.removeFromSuperview()
        let next = conversation(history.current)
        active = next; mount(next)
        next.updateHistoryMenu(back: history.canGoBack, forward: history.canGoForward)
        let flying = UIImageView(image: image)
        flying.frame = origin ?? view.bounds.insetBy(dx: 40, dy: 100)
        flying.contentMode = .scaleToFill; flying.clipsToBounds = true
        flying.layer.cornerCurve = .continuous; flying.layer.cornerRadius = CGFloat(state.settings.cornerRadius)
        view.addSubview(flying)
        statusBarShield.isHidden = false
        view.bringSubviewToFront(statusBarShield)
        let visible = origin?.intersects(view.bounds) ?? false
        flying.alpha = visible ? 1 : 0
        next.alpha = visible ? 0 : 1
        stack.cards.alpha = 0
        let duration = UIAccessibility.isReduceMotionEnabled ? 0 : 0.38 / state.settings.animationSpeed
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: CGFloat(state.settings.springDamping), initialSpringVelocity: 0, options: .beginFromCurrentState) {
            flying.frame = self.view.bounds
            flying.layer.cornerRadius = 0
            stack.alpha = 0
        } completion: { _ in
            flying.removeFromSuperview(); stack.removeFromSuperview(); self.overview = nil
            next.alpha = 1; self.busy = false
            self.statusBarShield.isHidden = true
            self.refreshFirstHint(); self.saveState()
            UIAccessibility.post(notification: .screenChanged, argument: next)
        }
    }

    private func updateTouchDots(_ recognizer: UIPanGestureRecognizer) {
        if state.settings.showTouchIndicators && (recognizer.state == .began || recognizer.state == .changed) {
            while touchDots.count < 3 {
                let dot = UIView(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
                dot.layer.cornerRadius = 16; dot.backgroundColor = UIColor.white.withAlphaComponent(0.25)
                dot.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor; dot.layer.borderWidth = 1
                dot.isUserInteractionEnabled = false; view.addSubview(dot); touchDots.append(dot)
            }
            for (index, dot) in touchDots.enumerated() {
                dot.isHidden = index >= recognizer.numberOfTouches
                if !dot.isHidden { dot.center = recognizer.location(ofTouch: index, in: view); dot.alpha = 1 }
            }
        } else {
            UIView.animate(withDuration: 0.12) { self.touchDots.forEach { $0.alpha = 0 } }
        }
    }

    #if DEBUG
    private func runOverviewSmoke() {
        var checks: [[String: Any]] = []
        let middleID = PrototypeState.seedHistory[4]
        func check(_ name: String, _ passed: Bool) {
            checks.append(["name": name, "passed": passed])
            NSLog("STACK_SMOKE %@ %@", passed ? "PASS" : "FAIL", name)
        }
        historyPosition.sendActions(for: .touchUpInside)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            check("indicator touch action opens overview", self.overview != nil)
            check("overview starts on current chat", self.overview?.focusedIndex == self.history.cursor)
            check("eight seeded cards available", self.overview?.images.count == 8)
            self.overview?.focus(4, animated: true)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            check("native scrolling focuses another card", self.overview?.focusedIndex == 4)
            if let stack = self.overview {
                stack.cards.delegate?.collectionView?(stack.cards, didSelectItemAt: IndexPath(item: 4, section: 0))
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            check("card selection opens correct conversation", self.overview == nil && self.active?.session.id == middleID && self.history.cursor == 4)
            check("selection leaves surface full screen", self.active?.transform == .identity && self.active?.layer.cornerRadius == 0)
            self.beginSwitch(isGesture: true)
            self.update(-CGFloat(self.state.settings.overviewDistance))
            self.releaseSwitch(distance: -CGFloat(self.state.settings.overviewDistance), velocity: -50)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.8) {
            check("gentle midpoint release opens overview", self.overview != nil)
            var tuned = self.state.settings
            tuned.cardScale = 0.64; tuned.indicatorStyle = .dots; tuned.showActivity = false
            self.overview?.apply(tuned)
            check("live card-size change applies", abs((self.overview?.imageFrame(at: 4)?.width ?? 0) - self.view.bounds.width * 0.64) < 2)
            self.overview?.onClose?()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.2) {
            check("close returns to current conversation", self.overview == nil && self.active?.session.id == middleID)
            self.active?.appendMessage("A local smoke-check message")
            self.saveState()
            check("local message persists in selected chat", self.store.load()?.conversations[middleID]?.sentMessages.last == "A local smoke-check message")
            self.showSettings()
            check("prototype controls present", self.presentedViewController is UINavigationController)
            let result: [String: Any] = ["checks": checks, "passed": checks.allSatisfy { $0["passed"] as? Bool == true }, "input": "scripted native control events, scrolling and release path; no physical multitouch"]
            let path = self.store.url.deletingLastPathComponent().appendingPathComponent("overview-smoke.json")
            if let data = try? JSONSerialization.data(withJSONObject: result, options: .prettyPrinted) { try? data.write(to: path) }
            NSLog("STACK_SMOKE_COMPLETE %@", path.path)
        }
    }
    #endif

    private func refreshFirstHint() {
        firstHint.isHidden = state.hasLearnedGesture || active == nil || sidebarOpen || busy || keyboardHeight > 0
            || overview != nil || presentedViewController != nil || UIAccessibility.isVoiceOverRunning
        historyPosition.isHidden = active == nil || sidebarOpen || overview != nil || keyboardHeight > 0 || presentedViewController != nil
        historyPosition.show(entries: history.entries, cursor: pendingCursor ?? history.cursor, settings: state.settings, emphasized: busy)
        view.setNeedsLayout()
    }
    @objc private func accessibilityChanged() {
        pan?.isEnabled = !UIAccessibility.isVoiceOverRunning
        refreshFirstHint()
    }
    @objc private func keyboardChanged(_ notification: Notification) {
        guard let rect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        keyboardHeight = max(0, view.bounds.maxY - view.convert(rect, from: nil).minY)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        refreshFirstHint()
    }
    private func queueSave() {
        saveWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.saveState() }
        saveWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
    }
    @objc private func saveState() {
        saveWork?.cancel()
        for (id, conversation) in conversations { state.conversations[id] = conversation.snapshot() }
        do { try store.save(state) }
        catch { NSLog("Session Swipe could not save its local state.") }
    }
    private func showSettings() {
        guard !busy, presentedViewController == nil else { return }
        view.endEditing(true)
        let settings = GestureSettingsController(settings: state.settings)
        settings.onChange = { [weak self] value in
            self?.state.settings = value; self?.overview?.apply(value); self?.refreshFirstHint(); self?.saveState()
        }
        settings.onBrowse = { [weak self] in self?.openOverview() }
        settings.onShowHint = { [weak self] in self?.state.hasLearnedGesture = false; self?.saveState() }
        settings.onClose = { [weak self] in self?.refreshFirstHint() }
        let navigation = UINavigationController(rootViewController: settings)
        navigation.overrideUserInterfaceStyle = .dark
        navigation.modalPresentationStyle = .pageSheet
        navigation.sheetPresentationController?.detents = [.large()]
        navigation.sheetPresentationController?.prefersGrabberVisible = true
        navigation.presentationController?.delegate = self
        firstHint.isHidden = true
        historyPosition.isHidden = true
        present(navigation, animated: true)
    }
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) { refreshFirstHint() }
    private func search() {
        let alert = UIAlertController(title: DemoBrand.isWhatsApp ? "Search chats" : "Search sessions", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Search" }
        alert.addAction(UIAlertAction(title: "Search", style: .default) { [weak self, weak alert] _ in
            self?.toggleSidebar(false)
            self?.showList()
            self?.list.filter(alert?.textFields?.first?.text ?? "")
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    private func newConversation() {
        open(DemoBrand.starterID)
        active?.focusComposer()
    }
    private func showAccessory(_ name: String) {
        if name == "Settings" { showSettings(); return }
        let text: String
        switch name {
        case "About":
            let activity = DemoBrand.isWhatsApp ? "Green means typing; blue means unread." : "Green means working; blue means a new reply."
            text = "Independent native interaction prototype with fictional chats.\n\nThree fingers down: older chat. Three fingers up: newer chat. Drag about a finger-length and release gently to browse the stack. You can also tap the right-edge indicator.\n\nIn the stack, scroll with one finger and tap a card. \(activity) Activity is sample data.\n\nHold the conversation title or use the stack’s controls button to adjust the prototype. Drafts and settings stay on this iPhone. No messages are delivered."
        case "Changes": text = "21 sample files\n\nThese counts are dummy data for the prototype."
        case "Feedback": text = "Feedback selected for this sample response."
        case "Copy":
            UIPasteboard.general.string = active?.session.messages.filter { !$0.isUser }.flatMap(\.blocks).map(\.plainText).joined(separator: "\n\n")
            text = "Sample response copied."
        default: text = "This control is shown for visual fidelity. The working flow is sessions, conversations, drafts, and three-finger history."
        }
        let alert = UIAlertController(title: name == "About" ? DemoBrand.name : name, message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Done", style: .default))
        present(alert, animated: true)
    }
}
