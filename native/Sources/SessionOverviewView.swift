import UIKit

final class SessionOverviewView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var onSelect: ((Int) -> Void)?
    var onClose: (() -> Void)?
    var onSettings: (() -> Void)?
    let cards: UICollectionView
    private let flow = UICollectionViewFlowLayout()
    private let entries: [String]
    let images: [UIImage]
    private let openedIndex: Int
    private var settings: GestureSettings
    private(set) var focusedIndex: Int
    private let position = HistoryPositionView()
    private let help = ChatStyle.label("One finger to browse · tap a card", size: 11, color: ChatStyle.secondary)
    private let statusCover = UIView()
    private lazy var close = ChatStyle.button("xmark", label: "Return to conversation") { [weak self] in self?.onClose?() }
    private lazy var controls = ChatStyle.button("slider.horizontal.3", label: "Prototype controls") { [weak self] in self?.onSettings?() }
    private var positioned = false
    private var lastSize = CGSize.zero
    private var dragStartIndex = 0

    init(entries: [String], images: [UIImage], current: Int, settings: GestureSettings) {
        self.entries = entries; self.images = images; self.openedIndex = current
        self.focusedIndex = current; self.settings = settings
        cards = UICollectionView(frame: .zero, collectionViewLayout: flow)
        super.init(frame: .zero)
        accessibilityIdentifier = "sessionStack"
        accessibilityViewIsModal = true
        backgroundColor = UIColor(white: 0.065, alpha: 1)
        flow.scrollDirection = .vertical
        cards.backgroundColor = .clear
        cards.contentInsetAdjustmentBehavior = .never
        cards.showsVerticalScrollIndicator = false
        cards.decelerationRate = .fast
        cards.accessibilityIdentifier = "sessionStackCards"
        cards.register(SessionPreviewCell.self, forCellWithReuseIdentifier: "card")
        cards.dataSource = self; cards.delegate = self
        addSubview(cards)
        statusCover.backgroundColor = UIColor(white: 0.065, alpha: 1)
        statusCover.isUserInteractionEnabled = false
        addSubview(statusCover)
        for item in [position, help, close, controls] { addSubview(item) }
        help.textAlignment = .center; help.isUserInteractionEnabled = false
        position.onBrowse = { [weak self] in guard let self else { return }; self.onSelect?(self.focusedIndex) }
        position.accessibilityLabel = "Open focused conversation"
        position.accessibilityIdentifier = "overviewPosition"
        close.accessibilityIdentifier = "closeSessionStack"
        controls.accessibilityIdentifier = "stackControls"
    }
    required init?(coder: NSCoder) { fatalError() }
    func apply(_ settings: GestureSettings) {
        self.settings = settings
        positioned = false
        cards.reloadData()
        setNeedsLayout(); layoutIfNeeded()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        if lastSize != bounds.size { lastSize = bounds.size; positioned = false }
        cards.frame = bounds
        statusCover.frame = CGRect(x: 0, y: 0, width: bounds.width, height: safeAreaInsets.top)
        let scale = CGFloat(settings.cardScale)
        flow.itemSize = CGSize(width: bounds.width * scale, height: bounds.height * scale + 44)
        flow.minimumLineSpacing = CGFloat(settings.cardSpacing)
        let inset = max(20, (bounds.height - flow.itemSize.height) / 2)
        let nextInsets = UIEdgeInsets(top: inset, left: 0, bottom: inset, right: 0)
        if cards.contentInset != nextInsets { cards.contentInset = nextInsets }
        if !positioned && bounds.height > 0 {
            let target = focusedIndex
            flow.invalidateLayout(); cards.layoutIfNeeded()
            positioned = true
            cards.setContentOffset(CGPoint(x: 0, y: CGFloat(target) * stride - inset), animated: false)
            focusedIndex = target
        }
        controls.frame = CGRect(x: 16, y: safeAreaInsets.top + 2, width: 44, height: 44)
        close.frame = CGRect(x: bounds.width - 60, y: safeAreaInsets.top + 2, width: 44, height: 44)
        help.frame = CGRect(x: 20, y: bounds.height - safeAreaInsets.bottom - 21, width: bounds.width - 40, height: 17)
        updatePosition()
    }
    private var stride: CGFloat { flow.itemSize.height + flow.minimumLineSpacing }
    private func updatePosition() {
        position.show(entries: entries, cursor: focusedIndex, settings: settings, emphasized: true)
        let scale = CGFloat(settings.indicatorSize)
        position.bounds = CGRect(x: 0, y: 0, width: 52, height: position.preferredHeight)
        position.center = CGPoint(x: bounds.width - 27 * scale, y: bounds.height * 0.48)
        position.transform = CGAffineTransform(scaleX: scale, y: scale)
        for cell in cards.visibleCells {
            let distance = min(1, abs(cell.center.y - (cards.contentOffset.y + cards.bounds.midY)) / cards.bounds.height)
            cell.alpha = 1 - distance * 0.28
        }
    }
    func imageFrame(at index: Int) -> CGRect? {
        guard let attributes = cards.layoutAttributesForItem(at: IndexPath(item: index, section: 0)) else { return nil }
        let rect = CGRect(x: attributes.frame.minX, y: attributes.frame.minY + 44, width: attributes.frame.width, height: attributes.frame.height - 44)
        return cards.convert(rect, to: self)
    }
    func focus(_ index: Int, animated: Bool) {
        guard entries.indices.contains(index) else { return }
        cards.setContentOffset(CGPoint(x: 0, y: CGFloat(index) * stride - cards.contentInset.top), animated: animated)
        if !animated { focusedIndex = index; updatePosition() }
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { entries.count }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "card", for: indexPath) as! SessionPreviewCell
        cell.configure(session: SampleData.session(entries[indexPath.item]), image: images[indexPath.item], current: indexPath.item == openedIndex, settings: settings)
        cell.accessibilityIdentifier = "stack-card-\(indexPath.item)"
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) { onSelect?(indexPath.item) }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard positioned, stride > 0, !entries.isEmpty else { return }
        focusedIndex = max(0, min(entries.count - 1, Int(((scrollView.contentOffset.y + scrollView.contentInset.top) / stride).rounded())))
        updatePosition()
    }
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        var target = Int(((targetContentOffset.pointee.y + scrollView.contentInset.top) / stride).rounded())
        if abs(velocity.y) > 0.25 && target == dragStartIndex { target += velocity.y > 0 ? 1 : -1 }
        targetContentOffset.pointee.y = CGFloat(max(0, min(entries.count - 1, target))) * stride - scrollView.contentInset.top
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { dragStartIndex = focusedIndex }
}

private final class SessionPreviewCell: UICollectionViewCell {
    private let image = UIImageView()
    private let title = ChatStyle.label("", size: 13, weight: .semibold)
    private let status = ChatStyle.label("", size: 10, color: ChatStyle.secondary)
    private let dot = ActivityDot()
    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = true
        accessibilityTraits = .button
        image.contentMode = .scaleToFill
        image.clipsToBounds = true; image.backgroundColor = .black
        image.layer.cornerCurve = .continuous
        for item in [image, title, status, dot] { contentView.addSubview(item) }
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(session: SampleSession, image: UIImage, current: Bool, settings: GestureSettings) {
        self.image.image = image
        self.image.layer.cornerRadius = CGFloat(settings.cornerRadius)
        self.image.layer.borderWidth = current ? 1 : 0.5
        self.image.layer.borderColor = UIColor.white.withAlphaComponent(current ? 0.40 : 0.15).cgColor
        title.text = session.title
        let activity = settings.showActivity ? session.activity : .idle
        status.text = [current ? "Current" : nil, activity == .idle ? session.project : activity.label].compactMap { $0 }.joined(separator: " · ")
        status.textColor = activity == .idle ? ChatStyle.secondary : activity.tint
        dot.show(activity, settings: settings)
        accessibilityLabel = session.title + ". " + (status.text ?? "")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        image.frame = CGRect(x: 0, y: 44, width: bounds.width, height: bounds.height - 44)
        title.frame = CGRect(x: 7, y: 0, width: bounds.width - 14, height: 20)
        dot.frame = CGRect(x: 8, y: 26, width: 5, height: 5)
        status.frame = CGRect(x: dot.isHidden ? 7 : 19, y: 20, width: bounds.width - 26, height: 18)
    }
}
