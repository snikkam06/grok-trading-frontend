import SwiftUI

struct AIChatView: View {
    let context: String
    let ticker: String
    var isGlobal: Bool = false
    @Environment(\.dismiss) var dismiss
    @StateObject private var llm = LLMService.shared
    @State private var messages: [ChatMessage] = [] 
    @State private var inputText = ""
    @State private var isTyping = false
    
    @State private var currentNotes: String = ""
    @State private var pendingNotes: String? = nil
    
    struct ChatMessage: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 16) {
                                Text(isGlobal ? "Global portfolio discussion" : "Discussion about \(ticker) trade")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                                    .padding(.top)
                                
                                ForEach(messages) { message in
                                    HStack {
                                        if message.isUser { Spacer() }
                                        
                                        Text(message.text)
                                            .padding()
                                            .background(message.isUser ? Theme.brandPurple : Theme.cardBackground)
                                            .foregroundStyle(.white)
                                            .cornerRadius(16)
                                            .cornerRadius(message.isUser ? 4 : 16, corners: .bottomRight)
                                            .cornerRadius(!message.isUser ? 4 : 16, corners: .bottomLeft)
                                        
                                        if !message.isUser { Spacer() }
                                    }
                                    .padding(.horizontal)
                                    .id(message.id)
                                }
                                
                                if isTyping {
                                    HStack {
                                        ProgressView()
                                            .tint(.white)
                                            .padding()
                                            .background(Theme.cardBackground)
                                            .cornerRadius(16)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.bottom, 20)
                        }
                        .onChange(of: messages.count) {
                            if let last = messages.last {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    VStack(spacing: 0) {
                        if let proposal = pendingNotes {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Suggested Strategy Update")
                                    .font(.headline)
                                    .foregroundStyle(Theme.textPrimary)
                                
                                Text(proposal)
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                                    .lineLimit(4)
                                    .padding(8)
                                    .background(Theme.background)
                                    .cornerRadius(8)
                                
                                HStack {
                                    Button {
                                        pendingNotes = nil
                                    } label: {
                                        Text("Reject")
                                            .font(.subheadline.bold())
                                            .foregroundStyle(Theme.financialRed)
                                            .frame(maxWidth: .infinity)
                                            .padding(8)
                                            .background(Theme.financialRed.opacity(0.1))
                                            .cornerRadius(12)
                                    }
                                    
                                    Button {
                                        confirmNotes(proposal)
                                    } label: {
                                        Text("Confirm Update")
                                            .font(.subheadline.bold())
                                            .foregroundStyle(Theme.financialGreen)
                                            .frame(maxWidth: .infinity)
                                            .padding(8)
                                            .background(Theme.financialGreen.opacity(0.1))
                                            .cornerRadius(12)
                                    }
                                }
                            }
                            .padding()
                            .background(Theme.cardBackground)
                            .cornerRadius(20, corners: [.topLeft, .topRight])
                            .transition(.move(edge: .bottom))
                        }
                        
                        HStack {
                            TextField("Ask about this trade...", text: $inputText)
                                .padding()
                                .background(Theme.cardBackground)
                                .cornerRadius(24)
                                .foregroundStyle(.white)
                            
                            Button {
                                sendMessage()
                            } label: {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(inputText.isEmpty ? Theme.textSecondary : Theme.brandPurple)
                            }
                            .disabled(inputText.isEmpty || isTyping)
                        }
                        .padding()
                        .background(Theme.background)
                    }
                }
            }
            .navigationTitle(isGlobal ? "Global Analysis" : "Trade Insight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body.bold())
                    .foregroundStyle(Theme.brandPurple)
                }
            }
        }
        .onAppear {
            if isGlobal {
                Task {
                    do {
                        currentNotes = try await SupabaseManager.shared.fetchNotes()
                    } catch {
                        print("Failed to fetch notes: \(error)")
                    }
                }
            }
            if messages.isEmpty {
                let greeting = isGlobal 
                    ? " I've analyzed your recent portfolio activity. What questions do you have?"
                    : "I've reviewed the reasoning for this \(ticker) trade. What would you like to know?"
                messages.append(ChatMessage(text: greeting, isUser: false))
            }
        }
    }
    
    func confirmNotes(_ newNotes: String) {
        Task {
            do {
                try await SupabaseManager.shared.saveNotes(content: newNotes)
                await MainActor.run {
                    self.currentNotes = newNotes
                    self.pendingNotes = nil
                    self.messages.append(ChatMessage(text: "✅ Shared Brain updated successfully.", isUser: false))
                }
            } catch {
                print("Error saving notes: \(error)")
            }
        }
    }
    
    func sendMessage() {
        guard !inputText.isEmpty else { return }
        let userMsg = inputText
        messages.append(ChatMessage(text: userMsg, isUser: true))
        inputText = ""
        isTyping = true
        
        Task {
            do {
                let responseStruct = try await llm.chat(message: userMsg, context: context, currentNotes: isGlobal ? currentNotes : nil)
                
                await MainActor.run {
                    messages.append(ChatMessage(text: responseStruct.reply, isUser: false))
                    if let proposal = responseStruct.proposed_notes {
                        self.pendingNotes = proposal
                    }
                    isTyping = false
                }
            } catch {
                await MainActor.run {
                    messages.append(ChatMessage(text: "Error: \(error.localizedDescription)", isUser: false))
                    isTyping = false
                }
            }
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
