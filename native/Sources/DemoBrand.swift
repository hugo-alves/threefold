import Foundation

// Two standalone apps share the interaction engine, but never share saved state.
enum DemoBrand {
    #if WHATSAPP_DEMO
    static let isWhatsApp = true
    #else
    static let isWhatsApp = false
    #endif
    static var name: String { isWhatsApp ? "Threefold Chats" : "Threefold Codex" }
    static var starterID: String { isWhatsApp ? "wa-maya" : "swipe" }
    static var previewID: String { isWhatsApp ? "wa-maya" : "approaches" }
    static var seedHistory: [String] {
        isWhatsApp ? ["wa-book", "wa-daniel", "wa-family", "wa-studio", "wa-weekend", "wa-alex", "wa-design", "wa-maya"]
            : ["tv", "rock", "ideas", "pronounce", "forge", "linkedin", "swipe", "approaches"]
    }
}
