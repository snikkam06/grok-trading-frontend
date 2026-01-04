import Foundation
import SwiftUI
import Combine
import GoogleGenerativeAI

class LLMService: ObservableObject {
    static let shared = LLMService()
    
    private let model: GenerativeModel
    
    private init() {
        self.model = GenerativeModel(name: "gemini-3-flash-preview", apiKey: Config.geminiAPIKey)
    }
    
    struct LLMResponse: Decodable {
        let thought: String?
        let reply: String
        let proposed_notes: String?
    }
    
    func chat(message: String, context: String, currentNotes: String? = nil) async throws -> LLMResponse {
        var contextPrompt = "Context (Last 30 Trades):\n\(context)"
        
        if let notes = currentNotes {
            contextPrompt += "\n\nCurrent Strategy Notes (Shared Brain):\n\(notes)"
        }
        
        let prompt = """
        You are a trading assistant with access to a "Shared Brain" strategy document.
        
        \(contextPrompt)
        
        User Question:
        \(message)
        
        Instructions:
        1. Parse the user's intent. If they want to change the strategy, you MUST propose an update to the "Shared Brain".
        2. Output STRICT JSON format only. No markdown fences.
        3. Format:
        {
          "thought": "Internal reasoning...",
          "reply": "Conversational response to user...",
          "proposed_notes": "The full updated text of the Shared Brain notes (only if changing)"
        }
        4. If no changes to notes are needed, set "proposed_notes" to null.
        5. Keep "reply" concise (under 3 sentences).
        """
        
        let response = try await model.generateContent(prompt)
        let text = response.text ?? ""
        
        let cleanText = text.replacingOccurrences(of: "```json", with: "")
                            .replacingOccurrences(of: "```", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            
        if let data = cleanText.data(using: .utf8),
           let structured = try? JSONDecoder().decode(LLMResponse.self, from: data) {
            return structured
        } else {
            return LLMResponse(thought: nil, reply: text, proposed_notes: nil)
        }
    }
}
