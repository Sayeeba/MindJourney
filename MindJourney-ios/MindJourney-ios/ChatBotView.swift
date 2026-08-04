


import SwiftUI

struct ChatMessageItem: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date = Date()
}

struct ChatBotView: View {
    @State private var messages: [ChatMessageItem] = [
        ChatMessageItem(text: "Hello. You are not alone. How can I help you through this moment?", isUser: false)
    ]
    @State private var inputText: String = ""
    @State private var isSending: Bool = false
    @State private var userId: String = "user_123"

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Message List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { msg in
                                chatBubble(msg: msg)
                                    .id(msg.id)
                            }

                            if isSending {
                                HStack {
                                    Text("AI is typing...")
                                        .font(.caption)
                                        .foregroundColor(Color("MutedText"))
                                        .italic()
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .onChange(of: messages.count) { _ in
                        if let lastId = messages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Input Bar
                HStack(spacing: 12) {
                    TextField("Write a message...", text: $inputText)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color("LavenderBG").opacity(0.3))
                        .cornerRadius(20)

                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.4) : Color("DeepPurple"))
                            .clipShape(Circle())
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white)
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func chatBubble(msg: ChatMessageItem) -> some View {
        HStack {
            if msg.isUser { Spacer() }

            Text(msg.text)
                .font(.subheadline)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .foregroundColor(msg.isUser ? .white : Color("DeepPurple"))
                .background(msg.isUser ? Color("DeepPurple") : Color("LavenderBG").opacity(0.5))
                .cornerRadius(18)
                .frame(maxWidth: 280, alignment: msg.isUser ? .trailing : .leading)

            if !msg.isUser { Spacer() }
        }
        .padding(.horizontal, 16)
    }

    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let userMsg = ChatMessageItem(text: trimmed, isUser: true)
        messages.append(userMsg)
        inputText = ""
        isSending = true

        guard let url = URL(string: "http://127.0.0.1:5001/api/chat") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "user_id": userId,
            "message": trimmed
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                isSending = false
                if let data = data,
                   let response = try? JSONDecoder().decode(ChatResponseModel.self, from: data) {
                    let botMsg = ChatMessageItem(text: response.reply, isUser: false)
                    messages.append(botMsg)
                } else {
                    let errorMsg = ChatMessageItem(text: "I'm having trouble connecting right now. Please try again.", isUser: false)
                    messages.append(errorMsg)
                }
            }
        }.resume()
    }
}

struct ChatResponseModel: Decodable {
    let reply: String
}
#Preview {
    ChatBotView()
}
//
//  ChatBotView.swift
//  MindJourney-ios
//
//  Created by Kazi  Sayeeba Islam on 8/4/26.
//
