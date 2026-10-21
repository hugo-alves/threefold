import Foundation

struct SampleSession {
    let id: String
    let title: String
    let project: String?
    let additions: String?
    let deletions: String?
    let running: Bool
    let paragraphs: [String]
    var messages: [SampleMessage] { SampleData.messages(for: self) }
    var activity: SessionActivity {
        if id.hasPrefix("wa-") { return WhatsAppData.chat(id).activity }
        if running { return .working }
        return ["linkedin", "tv", "ideas"].contains(id) ? .newReply : .idle
    }
}

enum SessionActivity { case idle, working, newReply
    var label: String {
        switch self { case .idle: return "Up to date"; case .working: return DemoBrand.isWhatsApp ? "Typing" : "Working"; case .newReply: return DemoBrand.isWhatsApp ? "Unread" : "New reply" }
    }
}

struct ChecklistItem {
    let text: String
    var checked = false
}

enum MessageBlock {
    case text(String)
    case heading(String)
    case code(String, String)
    case checklist([ChecklistItem])

    var plainText: String {
        switch self {
        case .text(let text), .heading(let text): return text
        case .code(_, let text): return text
        case .checklist(let items): return items.map { ($0.checked ? "[x] " : "[ ] ") + $0.text }.joined(separator: "\n")
        }
    }
}

struct SampleMessage {
    let isUser: Bool
    let blocks: [MessageBlock]
    static func user(_ text: String) -> SampleMessage { .init(isUser: true, blocks: [.text(text)]) }
    static func assistant(_ blocks: [MessageBlock]) -> SampleMessage { .init(isUser: false, blocks: blocks) }
}

enum SampleData {
    static var sessions: [SampleSession] { DemoBrand.isWhatsApp ? WhatsAppData.sessions : codexSessions }
    static let codexSessions: [SampleSession] = [
        .init(id: "approaches", title: "Explore alternative approaches", project: "Studio notes", additions: "+159", deletions: "−2", running: false, paragraphs: [
            "For this direction, I’d take Hear Me Out and A Second Look further first. One centres voice; the other centres discovery. Small, useful tools already fit within Say It Plain and Walk In Ready, so those alone would give a new idea less of its own identity.",
            "The obstacle can be fragmented information, limited time or an unanswered question. The most useful starting point is a specific moment when someone has something to say but needs help finding the words.",
            "For the discovery angle, I’d build the first version around a few concrete stories. Let someone bring a question, explore the information they already have and leave with a clearer next step. The page could show one example in full, from the original concern to the questions worth asking. That gives the idea a shape people can understand without a long explanation. We can then compare the two directions by asking people what they would actually use, which parts feel trustworthy and where the experience still leaves them uncertain."
        ]),
        .init(id: "swipe", title: "Prototype swipe session switching", project: nil, additions: nil, deletions: nil, running: true, paragraphs: [
            "The prototype moves between recently visited sessions with a three-finger vertical swipe. Move your fingers down to reveal an older conversation above. Move them up to return toward newer conversations below.",
            "The important detail is that the screen follows your fingers. You can pause halfway through, see which conversation is next, and pull back without losing your place. The gesture feels like moving something, rather than pressing an invisible button.",
            "Each session keeps its draft and scroll position. Ordinary one-finger scrolling stays available. At either end of the history, the screen resists the movement and settles back into place. Try switching away from this conversation, then coming straight back."
        ]),
        .init(id: "forge", title: "Check the local tools", project: "Side project", additions: "+2,1k", deletions: "−9", running: true, paragraphs: [
            "A verificação pode começar por uma chamada simples: listar as ferramentas disponíveis e confirmar que os nomes e os parâmetros correspondem ao que a interface apresenta.",
            "Depois, vale a pena experimentar uma operação de leitura com um resultado pequeno. Assim conseguimos distinguir um problema na ligação de um problema na apresentação da resposta.",
            "Para a primeira revisão, deixaria os erros visíveis junto à ação que falhou e manteria a conversa aberta. A pessoa deve conseguir corrigir a ligação e voltar a tentar sem perder a pergunta que já tinha escrito. O próximo passo é rever essa sequência no ecrã de configurações."
        ]),
        .init(id: "linkedin", title: "Draft a short launch post", project: "Studio notes", additions: "+159", deletions: "−2", running: false, paragraphs: [
            "Sometimes the difficult part is knowing what to ask. You have the document, the appointment or the decision in front of you, but the words are harder to find.",
            "Small Useful Things starts with those moments. A place to prepare a question, make sense of an explanation and arrive at the next conversation feeling a little more ready.",
            "I’d keep the post personal and concrete. Choose one situation people recognise, show how the tool helps and leave room for their experiences. A useful closing question would be: when did you last leave a conversation wishing you had asked something differently?"
        ]),
        .init(id: "tv", title: "Plan the weekend project", project: "Weekend workshop", additions: nil, deletions: nil, running: false, paragraphs: ["Vamos começar pelo comportamento visível: o ecrã atual, o gesto que a pessoa faz e o resultado que espera encontrar.", "Uma boa transição ajuda a perceber de onde viemos. Quando o movimento acompanha os dedos, a próxima conversa começa a aparecer antes de largarmos o ecrã.", "Esta conversa usa conteúdo de exemplo. A navegação funciona localmente e não altera nenhum projeto real."]),
        .init(id: "rock", title: "Review the prototype", project: nil, additions: nil, deletions: nil, running: false, paragraphs: ["The next step is a short review of the outline. We can keep the conversation focused on what the first prototype needs to demonstrate.", "A familiar screen makes it easier to judge a new interaction. The layout stays recognisable while the navigation changes.", "Try moving back one session and then forward again. The point is to feel whether the gesture makes returning easier."]),
        .init(id: "ideas", title: "Find a name for the idea", project: "Side project", additions: "+2,1k", deletions: "−9", running: false, paragraphs: ["Há várias ideias nesta conversa, mas podemos começar por uma só: regressar rapidamente ao ponto onde estávamos.", "O histórico mantém uma ordem estável. Recuar e avançar não reorganiza as sessões, por isso o gesto seguinte é previsível.", "Abrir outra conversa a partir da lista inicia um novo caminho no histórico, tal como num navegador."]),
        .init(id: "pronounce", title: "Practice a tricky sound", project: "Language notes", additions: nil, deletions: nil, running: false, paragraphs: ["Vamos experimentar uma sequência curta e voltar a ela depois. O importante neste exemplo é manter o ponto de leitura.", "Podes continuar a escrever no campo em baixo, mudar de conversa e regressar sem perder o rascunho.", "Estas mensagens são fictícias e servem apenas para experimentar a interface."])
    ]
    static func session(_ id: String) -> SampleSession { sessions.first { $0.id == id }! }

    static func messages(for session: SampleSession) -> [SampleMessage] {
        if session.id.hasPrefix("wa-") { return WhatsAppData.chat(session.id).messages.map { .init(isUser: $0.outgoing, blocks: [.text($0.text)]) } }
        switch session.id {
        case "approaches":
            return [
                .user("Compare Hear Me Out and A Second Look. Which would you prototype first?"),
                .assistant([
                    .heading("Two different moments"),
                    .text("Hear Me Out helps someone find the words before an important conversation. A Second Look helps them notice a useful question in information they already have."),
                    .text("I’d start with A Second Look. We can show a complete example: bring a document, understand the unclear part, and leave with three questions worth asking.")
                ]),
                .user("What would a small first test look like? Keep it practical."),
                .assistant([
                    .heading("One document. One clearer next step."),
                    .text("Use a fictional appointment letter. Let someone highlight the part they don’t understand, then help them prepare the next conversation."),
                    .checklist([
                        .init(text: "Choose one example letter", checked: true),
                        .init(text: "Show the original wording beside a plain explanation", checked: true),
                        .init(text: "Draft three questions they could ask"),
                        .init(text: "Try the flow with two people")
                    ]),
                    .text("Watch where they hesitate. Finish by asking which question they would actually take into the appointment.")
                ])
            ]
        case "swipe":
            return [
                .user("Show me the Swift for going back and forward through visited sessions without reordering them."),
                .assistant([
                    .text("Keep a cursor into the visit history. Switching only moves that cursor; it doesn’t change the order."),
                    .code("Swift · SessionHistory.swift", """
                    struct History {
                        var visits: [String]
                        var cursor: Int

                        mutating func move(_ step: Int) {
                            let next = cursor + step
                            guard visits.indices
                                .contains(next) else {
                                return
                            }
                            cursor = next
                        }
                    }
                    """),
                ]),
                .user("And if I go back, then open a different chat?"),
                .assistant([
                    .text("Start a new branch from that point, just like browser history."),
                    .code("Swift · Opening a conversation", """
                    mutating func visit(_ id: String) {
                        guard visits[cursor] != id
                            else { return }
                        visits = Array(
                            visits.prefix(cursor + 1)
                        ) + [id]
                        cursor = visits.count - 1
                    }
                    """),
                    .text("For example: A → B → C, back to B, then open D. The history becomes A → B → D. Going forward can’t unexpectedly take you back to C.")
                ])
            ]
        case "linkedin":
            return [
                .user("Draft a short Small Useful Things post. Start with a situation people recognise."),
                .assistant(session.paragraphs.map { .text($0) }),
                .user("Less like an announcement. More like something I would actually say."),
                .assistant([
                    .text("I’ve left plenty of conversations knowing I hadn’t asked the question I meant to ask."),
                    .text("Sometimes I needed a moment to understand the answer. Sometimes I only found the words on the way home."),
                    .text("That’s one of the situations we’re exploring with Small Useful Things: helping someone arrive with a clearer question, and leave knowing what to do next."),
                    .text("When did you last think, ‘I wish I’d asked that’?")
                ])
            ]
        default:
            return [.user(session.title), .assistant(session.paragraphs.map { .text($0) })]
        }
    }
}
