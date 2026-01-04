import SwiftUI

struct TradeReasoningView: View {
    let ticker: String
    @StateObject private var supabase = SupabaseManager.shared
    @State private var tradeLog: TradeLog?
    @State private var isLoading = true
    @State private var showingChat = false
    @State private var lastError: String?
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else if let log = tradeLog {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Trade Analysis")
                                .font(.largeTitle.bold())
                                .foregroundStyle(Theme.textPrimary)
                            
                            HStack {
                                Text(log.ticker)
                                    .font(.headline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Theme.cardBackground)
                                    .cornerRadius(8)
                                    .foregroundStyle(Theme.brandPurple)
                                
                                Text(log.action.uppercased())
                                    .font(.headline)
                                    .foregroundStyle(log.action.lowercased() == "buy" ? Theme.financialGreen : Theme.financialRed)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AI Reasoning")
                                .font(.headline)
                                .foregroundStyle(Theme.textSecondary)
                            
                            Text(log.reason)
                                .font(.body)
                                .foregroundStyle(Theme.textPrimary)
                                .lineSpacing(6)
                                .padding()
                                .background(Theme.cardBackground)
                                .cornerRadius(16)
                        }
                        
                        Button {
                            showingChat = true
                        } label: {
                            HStack {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                Text("Discuss with AI")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.brandPurple)
                            .cornerRadius(20)
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                }
                .sheet(isPresented: $showingChat) {
                    AIChatView(context: log.reason, ticker: ticker)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(Theme.textSecondary)
                    Text("No reasoning found for \(ticker)")
                        .foregroundStyle(Theme.textSecondary)
                    
                    if let error = lastError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Theme.financialRed)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
        }
        .task {
            do {
                self.tradeLog = try await supabase.fetchReasoning(for: ticker)
            } catch {
                self.lastError = error.localizedDescription
                print("Error fetching reasoning: \(error)")
            }
            self.isLoading = false
        }
    }
}

