import SwiftUI

struct StockDetailView: View {
    let trade: Trade
    @Environment(\.dismiss) var dismiss
    @State private var showingReasoning = false
    
    var isPositive: Bool {
        return trade.side == "buy"
    }
    
    var gradientColors: [Color] {
        if isPositive {
            return [Theme.financialGreen.opacity(0.6), Color.black]
        } else {
            return [Theme.financialRed.opacity(0.6), Color.black]
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            Theme.background.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    
                    Spacer()
                    
                    Text(trade.symbol)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal)
                
                ScrollView {
                    VStack(spacing: 32) {
                        VStack(spacing: 16) {
                            TickerIcon(symbol: trade.symbol, size: 80)
                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            VStack(spacing: 8) {
                                Text("$\(trade.price, specifier: "%.2f")")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                
                                Text("+29.70 (8.73%)")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(isPositive ? Theme.financialGreen : Theme.financialRed)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(Color.black.opacity(0.4)))
                            }
                        }
                        
                        HStack(spacing: 12) {
                            ActionButton(title: "Buy", icon: "arrow.down.left", color: Theme.brandPurple)
                            ActionButton(title: "Sell", icon: "arrow.up.right", color: Theme.cardBackground)
                            
                            Button {
                                showingReasoning = true
                            } label: {
                                VStack {
                                    Image(systemName: "sparkles")
                                        .font(.title2)
                                    Text("AI")
                                        .font(.caption.bold())
                                }
                                .foregroundStyle(.white)
                                .frame(width: 60, height: 60)
                                .background(Theme.financialGreen.opacity(0.8))
                                .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            InfoCard(title: "Quantity", value: "\(String(format: "%.0f", trade.qty)) st")
                            InfoCard(title: "Price per piece", value: String(format: "$%.2f", trade.price))
                            InfoCard(title: "Filled At", value: trade.filledAt.formatted(date: .abbreviated, time: .shortened))
                            InfoCard(title: "Side", value: trade.side.capitalized)
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Mock Chart")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                            
                            HStack(alignment: .bottom, spacing: 6) {
                                ForEach(0..<20) { _ in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(isPositive ? Theme.financialGreen : Theme.financialRed)
                                        .frame(height: CGFloat.random(in: 20...60))
                                }
                            }
                            .frame(height: 80)
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(24)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingReasoning) {
            TradeReasoningView(ticker: trade.symbol)
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button {
        } label: {
            HStack {
                Text(title)
                Image(systemName: icon)
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .cornerRadius(20)
        }
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 100)
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}
