import SwiftUI

struct ChatRequest: Encodable { let user_id: Int; let message: String }
struct ChatResponse: Decodable { let reply: String }
struct ChatMessageItem: Identifiable { let id = UUID(); let text: String; let isUser: Bool; let date = Date() }

struct ChatBotView: View {
    @AppStorage("userId") private var userId = 0
    @State private var messages: [ChatMessageItem] = [ChatMessageItem(text: "Hi. I'm MindJourney AI. What's on your mind today?", isUser: false)]
    @State private var input = ""
    @State private var sending = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                HStack { if message.isUser { Spacer() }; Text(message.text).padding(13).foregroundStyle(message.isUser ? .white : AppConfig.deepPurple).background(message.isUser ? AppConfig.deepPurple : AppConfig.softLavender).clipShape(RoundedRectangle(cornerRadius: 16)); if !message.isUser { Spacer() } }.id(message.id).padding(.horizontal, 14)
                            }
                            if sending { HStack { Text("MindJourney AI is thinking…").font(.caption).italic().foregroundStyle(AppConfig.muted); Spacer() }.padding(.horizontal, 20) }
                        }.padding(.vertical, 14)
                    }
                    .onChange(of: messages.count) { _, _ in if let id = messages.last?.id { withAnimation { proxy.scrollTo(id, anchor: .bottom) } } }
                }
                Divider()
                HStack(spacing: 10) {
                    TextField("Share what you're feeling...", text: $input, axis: .vertical).lineLimit(1...4).appField()
                    Button { send() } label: { Image(systemName: "paperplane.fill").foregroundStyle(.white).padding(12).background(AppConfig.deepPurple).clipShape(Circle()) }.disabled(input.trimmed.isEmpty || sending)
                }.padding(12)
            }.navigationTitle("MindJourney AI").navigationBarTitleDisplayMode(.inline)
        }
    }

    private func send() {
        let text = input.trimmed; guard !text.isEmpty else { return }
        messages.append(ChatMessageItem(text: text, isUser: true)); input = ""; sending = true
        Task {
            do { let response: ChatResponse = try await APIClient.request("/api/chat", method: "POST", body: ChatRequest(user_id: userId, message: text)); messages.append(ChatMessageItem(text: response.reply, isUser: false)) }
            catch { messages.append(ChatMessageItem(text: "I couldn't reach the server. Please check that the MindJourney backend is running.", isUser: false)) }
            sending = false
        }
    }
}

#Preview { ChatBotView() }
