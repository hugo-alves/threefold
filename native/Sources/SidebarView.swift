import UIKit

final class SidebarView: UIView {
    var onClose: (() -> Void)?
    var onOpen: ((String) -> Void)?
    var onAccessory: ((String) -> Void)?
    var onSearch: (() -> Void)?
    var insets: UIEdgeInsets = .zero { didSet { setNeedsLayout() } }
    private let title = ChatStyle.label("ChatGPT", size: 21, weight: .semibold)
    private let searchGlass = GlassView(radius: 22)
    private let settingsGlass = GlassView(radius: 22)
    private let newChat = UIButton(type: .system)
    private let divider = UIView()
    private var links: [UIButton] = []
    private var recents: [UIButton] = []
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        addSubview(title)
        addSubview(searchGlass)
        let search = ChatStyle.button("magnifyingglass", label: "Search conversations") { [weak self] in self?.onSearch?() }
        search.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        searchGlass.content.addSubview(search)
        let destinations = [("Space", "square.stack"), ("Projects", "folder"), ("Plugins", "puzzlepiece.extension"), ("Scheduled", "clock"), ("Codex", "bubble.left.and.text.bubble.right"), ("Explore", "square.grid.2x2")]
        for (index, item) in destinations.enumerated() {
            let button = UIButton(type: .system)
            button.layer.cornerRadius = 13
            button.backgroundColor = index == 4 ? UIColor(white: 0.13, alpha: 1) : .clear
            var configuration = UIButton.Configuration.plain()
            configuration.title = item.0
            configuration.image = ChatStyle.symbol(item.1, size: 21)
            if let asset = [0: "SpaceMark", 2: "PluginsMark", 4: "CodexMark", 5: "ExploreMark"][index] {
                configuration.image = UIImage(named: asset)?.withRenderingMode(.alwaysOriginal)
            }
            configuration.imagePadding = 15
            configuration.baseForegroundColor = .white
            configuration.contentInsets = .init(top: 0, leading: 22, bottom: 0, trailing: 0)
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
                var result = attributes; result.font = .systemFont(ofSize: 17, weight: .medium); return result
            }
            button.configuration = configuration
            button.contentHorizontalAlignment = .leading
            button.addAction(UIAction { [weak self] _ in
                if index == 4 { self?.onClose?() } else { self?.onAccessory?(item.0) }
            }, for: .touchUpInside)
            addSubview(button)
            links.append(button)
        }
        divider.backgroundColor = UIColor(white: 0.23, alpha: 1)
        addSubview(divider)
        let recentLabels = ["Draft the announcement", "Check tools and connections", "Plan the weekend", "Review prototype feedback", "Explore alternatives", "See all..."]
        let ids = ["linkedin", "forge", "swipe", "forge", "rock", "approaches"]
        for (index, name) in recentLabels.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(name, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16)
            button.tintColor = index == 5 ? ChatStyle.secondary : .white
            button.contentHorizontalAlignment = .leading
            button.addAction(UIAction { [weak self] _ in
                if index == 5 { self?.onClose?() } else { self?.onOpen?(ids[index]) }
            }, for: .touchUpInside)
            if index == 2 {
                let dot = UIImageView(image: ChatStyle.symbol("circle.fill", size: 10))
                dot.tintColor = .systemBlue
                dot.frame = CGRect(x: 234, y: 18, width: 10, height: 10)
                button.addSubview(dot)
            }
            addSubview(button)
            recents.append(button)
        }
        var configuration = UIButton.Configuration.plain()
        configuration.title = "Chat"
        configuration.image = ChatStyle.symbol("square.and.pencil", size: 20)
        configuration.imagePadding = 10
        configuration.baseForegroundColor = .black
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var result = attributes; result.font = .systemFont(ofSize: 16, weight: .semibold); return result
        }
        newChat.configuration = configuration
        newChat.backgroundColor = .white
        newChat.layer.cornerRadius = 25
        newChat.addAction(UIAction { [weak self] _ in self?.onOpen?("swipe") }, for: .touchUpInside)
        addSubview(newChat)
        addSubview(settingsGlass)
        let settings = ChatStyle.button("gearshape", label: "Prototype settings") { [weak self] in self?.onAccessory?("Settings") }
        settings.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        settingsGlass.content.addSubview(settings)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        let top = insets.top
        title.frame = CGRect(x: 32, y: top + 8, width: 170, height: 28)
        searchGlass.frame = CGRect(x: bounds.width - 68, y: top, width: 44, height: 44)
        for (index, button) in links.enumerated() { button.frame = CGRect(x: 10, y: top + 54 + CGFloat(index) * 48, width: bounds.width - 20, height: 44) }
        divider.frame = CGRect(x: 32, y: top + 364, width: bounds.width - 64, height: 0.5)
        for (index, button) in recents.enumerated() { button.frame = CGRect(x: 32, y: divider.frame.maxY + 27 + CGFloat(index) * 48, width: bounds.width - 60, height: 44) }
        newChat.frame = CGRect(x: 38, y: bounds.height - insets.bottom - 52, width: 112, height: 48)
        settingsGlass.frame = CGRect(x: bounds.width - 72, y: bounds.height - insets.bottom - 52, width: 44, height: 48)
    }
}
