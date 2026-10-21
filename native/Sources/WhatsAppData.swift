import Foundation

struct WhatsAppMessage {
    let text: String
    let time: String
    let outgoing: Bool
    var sender: String? = nil
}

struct WhatsAppChat {
    let id: String
    let name: String
    let group: Bool
    let status: String
    let activity: SessionActivity
    let unread: Int
    let messages: [WhatsAppMessage]
    var preview: String { messages.last?.text ?? "" }
}

enum WhatsAppData {
    // Entirely fictional contacts and conversations. No Contacts permission.
    static let chats: [WhatsAppChat] = [
        .init(id: "wa-maya", name: "Maya", group: false, status: "online", activity: .idle, unread: 0, messages: [
            .init(text: "Did you find somewhere for Saturday?", time: "18:32", outgoing: false),
            .init(text: "Yes! That little place by the water", time: "18:33", outgoing: true),
            .init(text: "The one you sent me last week?", time: "18:33", outgoing: false),
            .init(text: "Exactly. They have a table outside at 7", time: "18:34", outgoing: true),
            .init(text: "That sounds perfect", time: "18:35", outgoing: false),
            .init(text: "I’ll book it. Just the four of us?", time: "18:35", outgoing: true),
            .init(text: "I asked Alex and Sam. Both coming!", time: "18:36", outgoing: false),
            .init(text: "Great. We could walk there from the park", time: "18:38", outgoing: true),
            .init(text: "Yes please. I’ve been at my desk all day", time: "18:39", outgoing: false),
            .init(text: "Same here. A long walk is very much needed", time: "18:40", outgoing: true),
            .init(text: "Shall we meet a bit earlier then?", time: "18:41", outgoing: false),
            .init(text: "6:15 at the usual spot?", time: "18:41", outgoing: true),
            .init(text: "Works for me. I’ll bring the camera too", time: "18:42", outgoing: false),
            .init(text: "The light should be lovely by then", time: "18:42", outgoing: true),
            .init(text: "Can you send the location when you get a chance?", time: "18:43", outgoing: false)
        ]),
        .init(id: "wa-design", name: "Design friends", group: true, status: "Alex, Maya, Sam, you", activity: .newReply, unread: 3, messages: [
            .init(text: "Tiny interaction question for everyone", time: "17:12", outgoing: false, sender: "Alex"),
            .init(text: "How do you move between two chats without going back to the list?", time: "17:12", outgoing: false, sender: "Alex"),
            .init(text: "I usually just keep going back and forth", time: "17:14", outgoing: false, sender: "Maya"),
            .init(text: "What if the conversation followed your fingers?", time: "17:16", outgoing: true),
            .init(text: "Like a stack of cards?", time: "17:17", outgoing: false, sender: "Sam"),
            .init(text: "Yes. Three fingers to switch, one finger to read", time: "17:18", outgoing: true),
            .init(text: "I’d want to see the next chat before letting go", time: "17:19", outgoing: false, sender: "Maya"),
            .init(text: "You can. Release slowly and the whole stack stays open", time: "17:20", outgoing: true),
            .init(text: "Okay, I need to try this on a real phone", time: "17:21", outgoing: false, sender: "Alex")
        ]),
        .init(id: "wa-alex", name: "Alex", group: false, status: "typing…", activity: .working, unread: 0, messages: [
            .init(text: "Just tried the first version", time: "16:24", outgoing: false),
            .init(text: "How does the movement feel?", time: "16:25", outgoing: true),
            .init(text: "Surprisingly natural once I’d done it twice", time: "16:26", outgoing: false),
            .init(text: "The small pause before it opens the stack helps", time: "16:27", outgoing: false),
            .init(text: "Try shrinking the cards a little more", time: "16:28", outgoing: false),
            .init(text: "Done. You can change it in the controls now", time: "16:29", outgoing: true),
            .init(text: "And the chat keeps my draft when I come back?", time: "16:30", outgoing: false),
            .init(text: "Exactly. Same draft, same place in the conversation", time: "16:31", outgoing: true)
        ]),
        .init(id: "wa-weekend", name: "Weekend plans", group: true, status: "Maya, Daniel, Alex, you", activity: .newReply, unread: 2, messages: [
            .init(text: "Saturday is looking sunny", time: "15:10", outgoing: false, sender: "Daniel"),
            .init(text: "Finally! Picnic before dinner?", time: "15:11", outgoing: false, sender: "Maya"),
            .init(text: "I can bring something from the bakery", time: "15:13", outgoing: true),
            .init(text: "I’ll bring a blanket", time: "15:14", outgoing: false, sender: "Alex"),
            .init(text: "Let’s decide in the morning. No complicated plans", time: "15:15", outgoing: false, sender: "Daniel"),
            .init(text: "Best kind of plan", time: "15:16", outgoing: true),
            .init(text: "See you at the park entrance at 5?", time: "15:18", outgoing: false, sender: "Maya")
        ]),
        .init(id: "wa-studio", name: "Studio", group: true, status: "Sam, Noor, you", activity: .idle, unread: 0, messages: [
            .init(text: "The new prints arrived", time: "14:06", outgoing: false, sender: "Noor"),
            .init(text: "How do the colours look in daylight?", time: "14:07", outgoing: true),
            .init(text: "Much closer to the original. I put them by the window", time: "14:08", outgoing: false, sender: "Sam"),
            .init(text: "Let’s look at them together tomorrow", time: "14:10", outgoing: true),
            .init(text: "Coffee and colour arguments. My favourite meeting", time: "14:11", outgoing: false, sender: "Noor"),
            .init(text: "10:30 works for me", time: "14:12", outgoing: false, sender: "Sam")
        ]),
        .init(id: "wa-family", name: "Family", group: true, status: "Mum, Dad, Emma, you", activity: .idle, unread: 0, messages: [
            .init(text: "Sunday lunch at ours?", time: "12:20", outgoing: false, sender: "Mum"),
            .init(text: "I’m in. What shall I bring?", time: "12:22", outgoing: true),
            .init(text: "Just yourselves", time: "12:23", outgoing: false, sender: "Dad"),
            .init(text: "I’m making that cake again", time: "12:24", outgoing: false, sender: "Emma"),
            .init(text: "Then I’m definitely coming", time: "12:25", outgoing: true),
            .init(text: "Around one. No rush", time: "12:27", outgoing: false, sender: "Mum")
        ]),
        .init(id: "wa-daniel", name: "Daniel", group: false, status: "tap here for contact info", activity: .idle, unread: 0, messages: [
            .init(text: "Did you finish the book?", time: "11:03", outgoing: false),
            .init(text: "Last night. That ending!", time: "11:05", outgoing: true),
            .init(text: "Right? I had to read the last chapter twice", time: "11:06", outgoing: false),
            .init(text: "I have so many questions", time: "11:07", outgoing: true),
            .init(text: "Save them for Thursday. Coffee at the usual place?", time: "11:08", outgoing: false),
            .init(text: "See you there", time: "11:09", outgoing: true)
        ]),
        .init(id: "wa-book", name: "Book club", group: true, status: "Daniel, Noor, Emma, you", activity: .newReply, unread: 1, messages: [
            .init(text: "Next month’s pick?", time: "09:35", outgoing: false, sender: "Noor"),
            .init(text: "Something short this time, please", time: "09:37", outgoing: false, sender: "Emma"),
            .init(text: "I have two suggestions. I’ll bring them on Thursday", time: "09:40", outgoing: true),
            .init(text: "Perfect. Let’s choose together", time: "09:42", outgoing: false, sender: "Daniel")
        ])
    ]
    static func chat(_ id: String) -> WhatsAppChat { chats.first { $0.id == id }! }
    static var sessions: [SampleSession] {
        chats.map { .init(id: $0.id, title: $0.name, project: $0.group ? "Group" : nil, additions: nil, deletions: nil, running: $0.activity == .working, paragraphs: $0.messages.map(\.text)) }
    }
}
