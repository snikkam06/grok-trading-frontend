import SwiftUI

struct NotesView: View {
    @State private var notes: String = "Loading..."
    @State private var isLoading = true
    @State private var isSaving = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Strategy & Insights")
                                .font(.headline)
                                .foregroundStyle(Theme.textSecondary)
                                .padding(.horizontal)
                            
                            TextEditor(text: $notes)
                                .scrollContentBackground(.hidden)
                                .background(Theme.cardBackground)
                                .foregroundStyle(Theme.textPrimary)
                                .cornerRadius(16)
                                .padding(.horizontal)
                        }
                        .padding(.top)
                    }
                }
            }
            .navigationTitle("Shared Brain")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.textSecondary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveNotes()
                    } label: {
                        if isSaving {
                            ProgressView().tint(Theme.brandPurple)
                        } else {
                            Text("Save")
                                .bold()
                        }
                    }
                    .foregroundStyle(Theme.brandPurple)
                    .disabled(isLoading || isSaving)
                }
            }
        }
        .onAppear {
            fetchNotes()
        }
    }
    
    func fetchNotes() {
        Task {
            do {
                let content = try await SupabaseManager.shared.fetchNotes()
                await MainActor.run {
                    self.notes = content
                    self.isLoading = false
                }
            } catch {
                print("Error loading notes: \(error)")
                await MainActor.run {
                    self.notes = "Error loading notes."
                    self.isLoading = false
                }
            }
        }
    }
    
    func saveNotes() {
        isSaving = true
        Task {
            do {
                try await SupabaseManager.shared.saveNotes(content: notes)
                await MainActor.run {
                    self.isSaving = false
                    dismiss()
                }
            } catch {
                print("Error saving notes: \(error)")
                await MainActor.run {
                    self.isSaving = false
                }
            }
        }
    }
}
