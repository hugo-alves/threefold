import UIKit

enum ChatStyle {
    static let secondary = UIColor(white: 0.64, alpha: 1)
    static let green = UIColor(red: 0.16, green: 0.72, blue: 0.48, alpha: 1)
    static let additions = UIColor(red: 0.23, green: 0.60, blue: 0.24, alpha: 1)
    static let deletions = UIColor(red: 0.81, green: 0.22, blue: 0.29, alpha: 1)

    static func label(_ value: String, size: CGFloat = 17, weight: UIFont.Weight = .regular, color: UIColor = .white) -> UILabel {
        let label = UILabel()
        label.text = value
        label.font = .systemFont(ofSize: size, weight: weight)
        label.textColor = color
        return label
    }
    static func symbol(_ name: String, size: CGFloat = 21, weight: UIImage.SymbolWeight = .regular) -> UIImage? {
        guard let symbol = UIImage(systemName: name, withConfiguration: UIImage.SymbolConfiguration(pointSize: size, weight: weight)) else { return nil }
        // Keep button configurations from replacing a symbol's intended size.
        let scale = size / max(symbol.size.width, symbol.size.height)
        let dimensions = CGSize(width: symbol.size.width * scale, height: symbol.size.height * scale)
        let rect = CGRect(x: (size - dimensions.width) / 2, y: (size - dimensions.height) / 2, width: dimensions.width, height: dimensions.height)
        return UIGraphicsImageRenderer(size: CGSize(width: size, height: size)).image { _ in
            symbol.withTintColor(.white, renderingMode: .alwaysOriginal).draw(in: rect)
        }.withRenderingMode(.alwaysTemplate)
    }
    static func button(_ symbol: String, label: String, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.setImage(self.symbol(symbol), for: .normal)
        button.accessibilityLabel = label
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }
}

class GlassView: UIView {
    let material: UIVisualEffectView
    var content: UIView { material.contentView }
    init(radius: CGFloat = 24) {
        let effect: UIVisualEffect
        if #available(iOS 26.0, *) {
            let glass = UIGlassEffect(style: .regular)
            glass.tintColor = UIColor(white: 0.15, alpha: 0.35)
            effect = glass
        } else {
            effect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        }
        material = UIVisualEffectView(effect: effect)
        super.init(frame: .zero)
        addSubview(material)
        backgroundColor = UIColor(white: 0.16, alpha: 0.40)
        layer.cornerRadius = radius
        layer.cornerCurve = .continuous
        layer.borderColor = UIColor(white: 1, alpha: 0.10).cgColor
        layer.borderWidth = 0.7
        clipsToBounds = true
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() { super.layoutSubviews(); material.frame = bounds }
}

final class ComposerView: GlassView, UITextFieldDelegate {
    let field = UITextField()
    private let plus: UIButton
    private let microphone: UIButton
    private let voice: UIButton?
    var onSubmit: ((String) -> Void)?
    init(placeholder: String, voiceMode: Bool, onAccessory: @escaping (String) -> Void) {
        plus = ChatStyle.button("plus", label: "Add attachment") { onAccessory("Attachments") }
        microphone = ChatStyle.button("mic", label: "Dictate") { onAccessory("Dictation") }
        voice = voiceMode ? ChatStyle.button("waveform", label: "Voice mode", action: { onAccessory("Voice mode") }) : nil
        super.init(radius: 27)
        field.font = .systemFont(ofSize: 17)
        field.textColor = .white
        field.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [.foregroundColor: UIColor(white: 0.5, alpha: 1)])
        field.accessibilityLabel = placeholder
        field.accessibilityIdentifier = "composer"
        field.returnKeyType = .send
        field.delegate = self
        content.addSubview(plus)
        content.addSubview(field)
        content.addSubview(microphone)
        if let voice {
            voice.backgroundColor = .white
            voice.tintColor = .black
            voice.layer.cornerRadius = 16
            content.addSubview(voice)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        plus.frame = CGRect(x: 3, y: 2, width: 44, height: bounds.height - 4)
        if let voice {
            voice.frame = CGRect(x: bounds.width - 39, y: (bounds.height - 32) / 2, width: 32, height: 32)
            microphone.frame = CGRect(x: bounds.width - 84, y: 2, width: 44, height: bounds.height - 4)
        } else {
            microphone.frame = CGRect(x: bounds.width - 48, y: 2, width: 44, height: bounds.height - 4)
        }
        field.frame = CGRect(x: 52, y: 3, width: max(0, bounds.width - (voice == nil ? 102 : 137)), height: bounds.height - 6)
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return false }
        onSubmit?(text)
        textField.text = ""
        return false
    }
}
