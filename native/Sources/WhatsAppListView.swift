import UIKit

final class WhatsAppListView: SessionListSurface, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    private let title = ChatStyle.label("Chats", size: 32, weight: .bold)
    private let table = UITableView(frame: .zero, style: .plain)
    private let header = UIView()
    private let search = UISearchBar()
    private let filters = UIScrollView()
    private var chips: [UIButton] = []
    private let moreGlass = GlassView(radius: 22)
    private let newChat = UIButton(type: .system)
    private let tabGlass = GlassView(radius: 30)
    private var tabs: [UIButton] = []
    private let empty = ChatStyle.label("No chats found", size: 16, color: ChatStyle.secondary)
    private var query = ""
    private var selectedFilter = 0
    private var rows: [WhatsAppChat] {
        WhatsAppData.chats.filter { chat in
            (query.isEmpty || chat.name.localizedCaseInsensitiveContains(query) || chat.preview.localizedCaseInsensitiveContains(query))
            && (selectedFilter != 1 || chat.unread > 0)
            && (selectedFilter != 2 || ["wa-maya", "wa-family"].contains(chat.id))
            && (selectedFilter != 3 || chat.group)
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        addSubview(title); addSubview(table); addSubview(moreGlass); addSubview(newChat); addSubview(tabGlass)
        let more = ChatStyle.button("ellipsis", label: "Chat options") {}
        more.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        more.showsMenuAsPrimaryAction = true
        more.menu = UIMenu(children: [
            UIAction(title: "Prototype controls", image: ChatStyle.symbol("slider.horizontal.3")) { [weak self] _ in self?.onAccessory?("Settings") },
            UIAction(title: "About this prototype", image: ChatStyle.symbol("info.circle")) { [weak self] _ in self?.onAccessory?("About") }
        ])
        moreGlass.content.addSubview(more)
        newChat.setImage(ChatStyle.symbol("plus", size: 23), for: .normal)
        newChat.tintColor = .black; newChat.backgroundColor = WhatsAppStyle.green; newChat.layer.cornerRadius = 22
        newChat.accessibilityLabel = "Choose a sample chat"
        newChat.showsMenuAsPrimaryAction = true
        newChat.menu = UIMenu(children: WhatsAppData.chats.map { chat in
            UIAction(title: chat.name, image: ChatStyle.symbol(chat.group ? "person.2" : "person")) { [weak self] _ in self?.onOpen?(chat.id) }
        })
        table.backgroundColor = .black; table.separatorColor = UIColor(white: 0.17, alpha: 1)
        table.separatorInset = UIEdgeInsets(top: 0, left: 88, bottom: 0, right: 0)
        table.showsVerticalScrollIndicator = false; table.contentInsetAdjustmentBehavior = .never
        table.dataSource = self; table.delegate = self
        table.register(WhatsAppChatCell.self, forCellReuseIdentifier: "chat")
        table.accessibilityIdentifier = "sessionList"
        table.keyboardDismissMode = .onDrag
        search.searchBarStyle = .minimal; search.placeholder = "Ask Meta AI or Search"
        search.delegate = self; search.searchTextField.font = .systemFont(ofSize: 16)
        search.searchTextField.accessibilityIdentifier = "chatSearch"
        header.addSubview(search); header.addSubview(filters)
        filters.showsHorizontalScrollIndicator = false
        for (index, name) in ["All", "Unread", "Favourites", "Groups"].enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(name, for: .normal); button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            button.layer.cornerRadius = 18
            button.addAction(UIAction { [weak self] _ in self?.selectFilter(index) }, for: .touchUpInside)
            filters.addSubview(button); chips.append(button)
        }
        table.tableHeaderView = header
        for (index, entry) in [("Updates", "circle.dashed"), ("Calls", "phone"), ("Communities", "person.2"), ("Chats", "bubble.left.and.bubble.right.fill"), ("Settings", "gearshape")].enumerated() {
            let button = UIButton(type: .system)
            var config = UIButton.Configuration.plain()
            config.title = entry.0; config.image = ChatStyle.symbol(entry.1, size: 23)
            config.imagePlacement = .top; config.imagePadding = 4
            config.baseForegroundColor = index == 3 ? WhatsAppStyle.green : ChatStyle.secondary
            config.contentInsets = .zero
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
                var result = attributes; result.font = .systemFont(ofSize: 10, weight: .medium); return result
            }
            button.configuration = config
            button.accessibilityTraits = index == 3 ? [.button, .selected] : .button
            button.addAction(UIAction { [weak self] _ in
                if index == 3 { self?.selectFilter(0) } else { self?.onAccessory?(index == 4 ? "Settings" : entry.0) }
            }, for: .touchUpInside)
            tabGlass.content.addSubview(button); tabs.append(button)
        }
        empty.textAlignment = .center; addSubview(empty)
        selectFilter(0)
    }
    required init?(coder: NSCoder) { fatalError() }
    private func selectFilter(_ index: Int) {
        selectedFilter = index
        for (i, button) in chips.enumerated() {
            button.backgroundColor = i == index ? UIColor(red: 0.08, green: 0.24, blue: 0.16, alpha: 1) : UIColor(white: 0.12, alpha: 1)
            button.tintColor = i == index ? WhatsAppStyle.green : ChatStyle.secondary
            button.accessibilityTraits = i == index ? [.button, .selected] : .button
        }
        table.reloadData(); empty.isHidden = !rows.isEmpty
    }
    override func filter(_ value: String) { query = value; search.text = value; table.reloadData(); empty.isHidden = !rows.isEmpty }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) { filter(searchText) }
    override func layoutSubviews() {
        super.layoutSubviews()
        title.frame = CGRect(x: 20, y: insets.top + 8, width: bounds.width - 150, height: 44)
        moreGlass.frame = CGRect(x: bounds.width - 112, y: insets.top + 7, width: 44, height: 44)
        newChat.frame = CGRect(x: bounds.width - 60, y: insets.top + 7, width: 44, height: 44)
        table.frame = CGRect(x: 0, y: insets.top + 62, width: bounds.width, height: bounds.height - insets.top - 62)
        table.contentInset.bottom = insets.bottom + 82
        header.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 116)
        search.frame = CGRect(x: 8, y: 0, width: bounds.width - 16, height: 54)
        filters.frame = CGRect(x: 16, y: 64, width: bounds.width - 16, height: 40)
        var x: CGFloat = 0
        for (i, chip) in chips.enumerated() {
            let width: CGFloat = [48, 78, 105, 80][i]
            chip.frame = CGRect(x: x, y: 0, width: width, height: 36); x += width + 8
        }
        filters.contentSize = CGSize(width: x, height: 40)
        if table.tableHeaderView?.bounds.height != 116 { table.tableHeaderView = header }
        tabGlass.frame = CGRect(x: 12, y: bounds.height - insets.bottom - 66, width: bounds.width - 24, height: 62)
        for (index, tab) in tabs.enumerated() { tab.frame = CGRect(x: CGFloat(index) * tabGlass.bounds.width / 5, y: 6, width: tabGlass.bounds.width / 5, height: 50) }
        empty.frame = CGRect(x: 20, y: table.frame.minY + 160, width: bounds.width - 40, height: 44)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 84 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chat", for: indexPath) as! WhatsAppChatCell
        cell.configure(rows[indexPath.row]); return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let id = rows[indexPath.row].id
        tableView.deselectRow(at: indexPath, animated: true); endEditing(true); onOpen?(id)
    }
}

private final class WhatsAppChatCell: UITableViewCell {
    private let avatar = WhatsAppStyle.avatar(group: false, size: 56)
    private let name = ChatStyle.label("", size: 17, weight: .semibold)
    private let preview = ChatStyle.label("", size: 15, color: ChatStyle.secondary)
    private let time = ChatStyle.label("", size: 12, color: ChatStyle.secondary)
    private let unread = ChatStyle.label("", size: 12, weight: .semibold, color: .black)
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .black; selectedBackgroundView = UIView(); selectedBackgroundView?.backgroundColor = UIColor(white: 0.12, alpha: 1)
        for item in [avatar, name, preview, time, unread] { contentView.addSubview(item) }
        preview.numberOfLines = 2; time.textAlignment = .right
        unread.backgroundColor = WhatsAppStyle.green; unread.layer.cornerRadius = 10; unread.clipsToBounds = true; unread.textAlignment = .center
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(_ chat: WhatsAppChat) {
        avatar.image = UIImage(systemName: chat.group ? "person.2.circle.fill" : "person.crop.circle.fill")
        name.text = chat.name
        preview.text = chat.activity == .working ? "typing…" : chat.preview
        preview.textColor = chat.activity == .working ? WhatsAppStyle.green : ChatStyle.secondary
        time.text = chat.messages.last?.time; time.textColor = chat.unread > 0 ? WhatsAppStyle.green : ChatStyle.secondary
        unread.text = "\(chat.unread)"; unread.isHidden = chat.unread == 0
        accessibilityIdentifier = "chat-\(chat.id)"
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        let width = contentView.bounds.width
        avatar.frame = CGRect(x: 18, y: 14, width: 56, height: 56)
        name.frame = CGRect(x: 88, y: 13, width: width - 160, height: 23)
        time.frame = CGRect(x: width - 67, y: 16, width: 49, height: 19)
        preview.frame = CGRect(x: 88, y: 39, width: width - (unread.isHidden ? 106 : 133), height: 37)
        unread.frame = CGRect(x: width - 39, y: 46, width: 21, height: 21)
    }
}
