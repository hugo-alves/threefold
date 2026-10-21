import UIKit

class SessionListSurface: UIView {
    var onOpen: ((String) -> Void)?
    var onSidebar: (() -> Void)?
    var onSearch: (() -> Void)?
    var onAccessory: ((String) -> Void)?
    var onNew: ((String) -> Void)?
    var insets: UIEdgeInsets = .zero { didSet { setNeedsLayout() } }
    func filter(_ value: String) {}
}
