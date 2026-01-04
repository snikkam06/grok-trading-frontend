import Foundation
import SwiftUI
import Combine
import Supabase

struct TradeLog: Decodable, Identifiable {
    let id: Int
    let timestamp: String
    let ticker: String
    let action: String
    let shares: Double
    let price: Double
    let reason: String
}

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: Config.supabaseURL,
            supabaseKey: Config.supabaseKey
        )
    }
    
    func fetchReasoning(for ticker: String) async throws -> TradeLog? {
        let query = client
            .from("trade_journal")
            .select()
            .eq("ticker", value: ticker)
            .order("timestamp", ascending: false)
            .limit(1)
            
        let logs: [TradeLog] = try await query.execute().value
        return logs.first
    }
    func fetchRecentLogs(limit: Int = 30) async throws -> [TradeLog] {
        let query = client
            .from("trade_journal")
            .select()
            .order("timestamp", ascending: false)
            .limit(limit)
            
        let logs: [TradeLog] = try await query.execute().value
        return logs
    }
    
    func fetchNotes() async throws -> String {
        let query = client
            .from("trading_notes")
            .select()
            .eq("id", value: 1)
            .single()
            
        let note: TradingNote = try await query.execute().value
        return note.content
    }
    
    func saveNotes(content: String) async throws {
        let updateData = ["content": content, "updated_at": ISO8601DateFormatter().string(from: Date())]
        try await client
            .from("trading_notes")
            .update(updateData)
            .eq("id", value: 1)
            .execute()
    }
}

struct TradingNote: Decodable, Encodable {
    let id: Int
    let content: String
    let updated_at: String?
}

struct BotLog: Decodable, Identifiable {
    let id: Int
    let timestamp: String
    let level: String
    let message: String
}

extension SupabaseManager {
    func fetchLogs(limit: Int = 50) async throws -> [BotLog] {
        let query = client
            .from("bot_logs")
            .select()
            .order("timestamp", ascending: false)
            .limit(limit)
            
        let logs: [BotLog] = try await query.execute().value
        return logs
    }
}
