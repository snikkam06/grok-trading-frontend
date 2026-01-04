import SwiftUI

struct BotLogsView: View {
    @State private var logs: [BotLog] = []
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if logs.isEmpty {
                    VStack {
                        Image(systemName: "terminal")
                            .font(.system(size: 48))
                            .foregroundStyle(Theme.textSecondary)
                        Text("No logs found")
                            .foregroundStyle(Theme.textSecondary)
                    }
                } else {
                    List(logs) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(log.timestamp)
                                    .font(.caption2)
                                    .foregroundStyle(Theme.textSecondary)
                                    .monospaced()
                                
                                Spacer()
                                
                                Text(log.level.uppercased())
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(levelColor(for: log.level).opacity(0.2))
                                    .foregroundStyle(levelColor(for: log.level))
                                    .cornerRadius(4)
                            }
                            
                            Text(log.message)
                                .font(.caption)
                                .foregroundStyle(Theme.textPrimary)
                                .monospaced()
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(Theme.textSecondary.opacity(0.2))
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await fetchLogs()
                    }
                }
            }
            .navigationTitle("Bot Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                Task { await fetchLogs() }
            }
        }
    }
    
    func fetchLogs() async {
        do {
            let newLogs = try await SupabaseManager.shared.fetchLogs()
            await MainActor.run {
                self.logs = newLogs
                self.isLoading = false
            }
        } catch {
            print("Error determining logs: \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
    
    func levelColor(for level: String) -> Color {
        switch level.lowercased() {
        case "error": return Theme.financialRed
        case "warning": return .orange
        case "info": return Theme.financialGreen
        default: return Theme.textSecondary
        }
    }
}
