import SwiftUI

struct ChatMessageItem: Identifiable, Codable {
    var id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
    
    init(id: UUID = UUID(), text: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
    }

    enum CodingKeys: String, CodingKey {
        case text, isUser, timestamp
    }
}

// Request and Response payload models
struct APIHistoryMessage: Encodable {
    let role: String // "user" or "model"
    let text: String
}

struct APIChatRequest: Encodable {
    let user_id: String
    let message: String
    let history: [APIHistoryMessage]
}

struct ChatResponseModel: Decodable {
    let reply: String
}

struct ChatBotView: View {
    @State private var messages: [ChatMessageItem] = [
        ChatMessageItem(
            text: "Hello. I'm MindJourney AI. You are not alone—how are you feeling in this moment?",
            isUser: false
        )
    ]
    @State private var inputText: String = ""
    @State private var isSending: Bool = false
    @State private var userId: String = "user_123"
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        // REMOVED NavigationStack here (your Sheet Router provides it)
        VStack(spacing: 0) {
            // Conversation Area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(messages) { msg in
                            chatBubble(msg: msg)
                                .id(msg.id)
                        }

                        if isSending {
                            typingIndicator
                                .id("typing_indicator")
                        }
                    }
                    .padding(.vertical, 16)
                }
                .onTapGesture {
                    isTextFieldFocused = false
                }
                .onChange(of: messages.count) { _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: isSending) { _ in
                    scrollToBottom(proxy: proxy)
                }
            }

            Divider()

            // Input Bar
            HStack(spacing: 12) {
                TextField("Share what's on your mind...", text: $inputText, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .focused($isTextFieldFocused)

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending
                                ? Color.gray.opacity(0.4)
                                : Color("DeepPurple")
                        )
                        .clipShape(Circle())
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
        .navigationTitle("MindJourney AI")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Views
    @ViewBuilder
    private func chatBubble(msg: ChatMessageItem) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if msg.isUser { Spacer(minLength: 50) }

            VStack(alignment: msg.isUser ? .trailing : .leading, spacing: 4) {
                Text(msg.text)
                    .font(.body)
                    .foregroundColor(msg.isUser ? .white : .primary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        msg.isUser
                        ? Color("DeepPurple")
                        : Color("LavenderBG").opacity(0.4)
                    )
                    .cornerRadius(18)

                Text(msg.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }

            if !msg.isUser { Spacer(minLength: 50) }
        }
        .padding(.horizontal, 16)
    }

    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("MindJourney is typing...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .cornerRadius(14)

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Helpers
    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.25)) {
            if isSending {
                proxy.scrollTo("typing_indicator", anchor: .bottom)
            } else if let lastId = messages.last?.id {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }

    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMsg = ChatMessageItem(text: trimmed, isUser: true)
        messages.append(userMsg)
        inputText = ""
        isSending = true

        // FIX #1: dropFirst() excludes initial bot greeting so history starts with a 'user' turn
        let historyMessages = messages.count > 2 ? Array(messages.dropFirst().dropLast()) : []
        let historyPayload = historyMessages.map { item in
            APIHistoryMessage(
                role: item.isUser ? "user" : "model",
                text: item.text
            )
        }

        let payload = APIChatRequest(
            user_id: userId,
            message: trimmed,
            history: historyPayload
        )

        // FIX #2: Update this string to your Mac's LAN IP address when running on physical iPhone
        guard let url = URL(string: "http://192.168.0.111:8000/api/chat") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            isSending = false
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isSending = false
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    let errorMsg = ChatMessageItem(
                        text: "The AI service is temporarily busy. Please try again in a few seconds.",
                        isUser: false
                    )
                    self.messages.append(errorMsg)
                    return
                }
                
                if let data = data,
                   let response = try? JSONDecoder().decode(ChatResponseModel.self, from: data) {
                    let botMsg = ChatMessageItem(text: response.reply, isUser: false)
                    self.messages.append(botMsg)
                }
            }
        }.resume()
    }
}

#Preview {
    ChatBotView()
}
