import UIKit

// The gesture engine moves this surface; each demo owns its conversation UI.
class ConversationSurface: UIView {
    let session: SampleSession
    let scroll = UIScrollView()
    var insets: UIEdgeInsets = .zero { didSet { if oldValue != insets { setNeedsLayout() } } }
    var keyboardHeight: CGFloat = 0 { didSet { if oldValue != keyboardHeight { setNeedsLayout() } } }
    var onBack: (() -> Void)?
    var onNew: (() -> Void)?
    var onHistory: ((Int) -> Void)?
    var onAccessory: ((String) -> Void)?
    var onSettings: (() -> Void)?
    var onBrowse: (() -> Void)?
    var onChange: (() -> Void)?

    init(_ session: SampleSession) { self.session = session; super.init(frame: .zero) }
    required init?(coder: NSCoder) { fatalError() }
    func snapshot() -> ConversationState { fatalError("Implement in conversation surface") }
    func renderPreview() -> UIImage { fatalError("Implement in conversation surface") }
    func updateHistoryMenu(back: Bool, forward: Bool) {}
    func appendMessage(_ value: String) {}
    func focusComposer() {}
}
