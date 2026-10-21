import UIKit

final class SessionListView: SessionListSurface, UITableViewDataSource, UITableViewDelegate {
    private let table = UITableView(frame: .zero, style: .plain)
    private let menuGlass = GlassView(radius: 22)
    private let searchGlass = GlassView(radius: 22)
    private let title = UIButton(type: .system)
    private let filters = UIScrollView()
    private var filterButtons: [UIButton] = []
    private let empty = ChatStyle.label("No sessions found", color: ChatStyle.secondary)
    private lazy var composer = ComposerView(placeholder: "Ask Codex", voiceMode: true) { [weak self] in self?.onAccessory?($0) }
    private var search = ""
    private var rows: [[SampleSession]] {
        let all = SampleData.sessions.filter { search.isEmpty || $0.title.localizedCaseInsensitiveContains(search) || ($0.project?.localizedCaseInsensitiveContains(search) ?? false) }
        return [all.filter { ["approaches", "swipe", "forge"].contains($0.id) }, all.filter { !["approaches", "swipe", "forge"].contains($0.id) }]
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        table.backgroundColor = .black
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.contentInsetAdjustmentBehavior = .never
        table.dataSource = self
        table.delegate = self
        table.sectionHeaderTopPadding = 0
        table.register(SessionCell.self, forCellReuseIdentifier: "session")
        table.accessibilityIdentifier = "sessionList"
        addSubview(table)
        addSubview(menuGlass)
        addSubview(searchGlass)
        let menu = ChatStyle.button("line.3.horizontal.decrease", label: "Open sidebar") { [weak self] in self?.onSidebar?() }
        menu.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        menuGlass.content.addSubview(menu)
        let search = ChatStyle.button("magnifyingglass", label: "Search sessions") { [weak self] in self?.onSearch?() }
        search.frame = menu.frame
        searchGlass.content.addSubview(search)
        var config = UIButton.Configuration.plain()
        config.title = "Codex"
        config.image = ChatStyle.symbol("chevron.down", size: 10, weight: .semibold)
        config.imagePlacement = .trailing
        config.imagePadding = 8
        config.baseForegroundColor = .white
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var result = attributes; result.font = .systemFont(ofSize: 17, weight: .semibold); return result
        }
        title.configuration = config
        title.menu = UIMenu(children: [UIAction(title: "Codex", image: ChatStyle.symbol("terminal"), state: .on) { _ in }, UIAction(title: "About this prototype", image: ChatStyle.symbol("info.circle")) { [weak self] _ in self?.onAccessory?("About") }])
        title.showsMenuAsPrimaryAction = true
        addSubview(title)
        filters.showsHorizontalScrollIndicator = false
        for (index, entry) in [("All", ""), ("Central", "terminal"), ("MacBook", "laptopcomputer"), ("Remote", "terminal")].enumerated() {
            let button = UIButton(type: .system)
            var configuration = UIButton.Configuration.plain()
            configuration.title = entry.0
            configuration.baseForegroundColor = ChatStyle.secondary
            configuration.imagePadding = 7
            configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
            configuration.contentInsets = .init(top: 10, leading: 15, bottom: 10, trailing: 15)
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
                var result = attributes; result.font = .systemFont(ofSize: 17); return result
            }
            if !entry.1.isEmpty { configuration.image = ChatStyle.symbol(entry.1, size: 14) }
            button.configuration = configuration
            button.titleLabel?.numberOfLines = 1
            button.layer.cornerRadius = 23
            button.accessibilityLabel = entry.0
            button.addAction(UIAction { [weak self] _ in self?.selectFilter(index) }, for: .touchUpInside)
            if index > 0 {
                let dot = UIImageView(image: ChatStyle.symbol("circle.fill", size: 5))
                dot.tintColor = ChatStyle.green
                dot.frame = CGRect(x: 3, y: 20, width: 6, height: 6)
                button.addSubview(dot)
            }
            filters.addSubview(button)
            filterButtons.append(button)
        }
        addSubview(filters)
        selectFilter(2)
        composer.onSubmit = { [weak self] in self?.onNew?($0) }
        addSubview(composer)
        empty.textAlignment = .center
        empty.isHidden = true
        addSubview(empty)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        let y = insets.top
        menuGlass.frame = CGRect(x: 16, y: y, width: 44, height: 44)
        searchGlass.frame = CGRect(x: bounds.width - 60, y: y, width: 44, height: 44)
        title.frame = CGRect(x: 100, y: y, width: bounds.width - 200, height: 44)
        filters.frame = CGRect(x: 16, y: y + 65, width: bounds.width - 16, height: 46)
        var x: CGFloat = 0
        for (index, button) in filterButtons.enumerated() {
            let width: CGFloat = [64, 116, 140, 116][index]
            button.frame = CGRect(x: x, y: 0, width: width, height: 44)
            x += width + 4
        }
        filters.contentSize = CGSize(width: x, height: 46)
        table.frame = CGRect(x: 0, y: filters.frame.maxY + 17, width: bounds.width, height: bounds.height - filters.frame.maxY - 17)
        table.contentInset.bottom = insets.bottom + 92
        composer.frame = CGRect(x: 38, y: bounds.height - insets.bottom - 52, width: bounds.width - 76, height: 48)
        empty.frame = CGRect(x: 20, y: table.frame.minY + 60, width: bounds.width - 40, height: 44)
    }
    override func filter(_ value: String) {
        search = value
        table.reloadData()
        empty.isHidden = rows.flatMap { $0 }.count > 0
    }
    private func selectFilter(_ index: Int) {
        for (i, button) in filterButtons.enumerated() {
            button.backgroundColor = i == index ? UIColor(white: 0.23, alpha: 1) : .clear
            button.configuration?.baseForegroundColor = i == index ? .white : ChatStyle.secondary
            button.accessibilityTraits = i == index ? [.button, .selected] : .button
        }
        // Each host is intentionally a local sample of the same seeded sessions.
        filter("")
    }
    func numberOfSections(in tableView: UITableView) -> Int { 2 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows[section].count }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { rows[section].isEmpty ? 0 : 44 }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let container = UIView()
        container.backgroundColor = .black
        let label = ChatStyle.label(section == 0 ? "Priority" : "Today", size: 17, weight: .semibold)
        label.frame = CGRect(x: 20, y: 9, width: 68, height: 26)
        let chevron = UIImageView(image: ChatStyle.symbol("chevron.down", size: 8))
        chevron.tintColor = ChatStyle.secondary
        chevron.frame = CGRect(x: section == 0 ? 86 : 75, y: 20, width: 8, height: 5)
        container.addSubview(label)
        container.addSubview(chevron)
        return container
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { rows[indexPath.section][indexPath.row].project == nil ? 50 : 68 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "session", for: indexPath) as! SessionCell
        cell.configure(rows[indexPath.section][indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onOpen?(rows[indexPath.section][indexPath.row].id)
    }
}

private final class SessionCell: UITableViewCell {
    private let title = ChatStyle.label("", size: 17)
    private let folder = UIImageView(image: ChatStyle.symbol("folder", size: 13))
    private let project = ChatStyle.label("", size: 13, color: ChatStyle.secondary)
    private let additions = ChatStyle.label("", size: 13, color: ChatStyle.additions)
    private let deletions = ChatStyle.label("", size: 13, color: ChatStyle.deletions)
    private let unread = UIImageView(image: ChatStyle.symbol("circle.fill", size: 10))
    private let spinner = UIActivityIndicatorView(style: .medium)
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .black
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = UIColor(white: 0.12, alpha: 1)
        folder.tintColor = ChatStyle.secondary
        unread.tintColor = .white
        spinner.color = UIColor(white: 0.4, alpha: 1)
        for item in [title, folder, project, additions, deletions, unread, spinner] { contentView.addSubview(item) }
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(_ session: SampleSession) {
        title.text = session.title
        project.text = session.project
        folder.isHidden = session.project == nil
        additions.text = session.additions
        deletions.text = session.deletions
        unread.isHidden = session.id != "approaches"
        session.running ? spinner.startAnimating() : spinner.stopAnimating()
        accessibilityIdentifier = "session-\(session.id)"
        accessibilityLabel = [session.title, session.project].compactMap { $0 }.joined(separator: ", ")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        let w = contentView.bounds.width
        title.frame = CGRect(x: 20, y: 12, width: w - 57, height: 24)
        folder.frame = CGRect(x: 20, y: 39, width: 14, height: 13)
        project.frame = CGRect(x: 41, y: 35, width: w - 180, height: 22)
        deletions.sizeToFit()
        deletions.frame = CGRect(x: w - 20 - deletions.bounds.width, y: 35, width: deletions.bounds.width, height: 22)
        additions.sizeToFit()
        additions.frame = CGRect(x: deletions.frame.minX - 6 - additions.bounds.width, y: 35, width: additions.bounds.width, height: 22)
        unread.frame = CGRect(x: w - 40, y: 17, width: 10, height: 10)
        spinner.frame = CGRect(x: w - 44, y: 13, width: 20, height: 20)
    }
}
