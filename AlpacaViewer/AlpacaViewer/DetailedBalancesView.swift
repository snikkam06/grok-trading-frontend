import SwiftUI

struct DetailedBalancesView: View {
    let account: PortfolioAccount
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        SectionHeader(title: "Buying Power")
                        BalanceRow(label: "RegT Buying Power", current: account.regtBuyingPower)
                        BalanceRow(label: "Day Trading Buying Power", current: account.daytradingBuyingPower)
                        BalanceRow(label: "Effective Buying Power", current: account.effectiveBuyingPower)
                        BalanceRow(label: "Non-Marginable Buying Power", current: account.nonMarginableBuyingPower)
                        
                        SectionHeader(title: "Margin")
                        BalanceRow(label: "Initial Margin", current: account.initialMargin)
                        BalanceRow(label: "Maintenance Margin", current: account.maintenanceMargin)
                        
                        SectionHeader(title: "Cash")
                        BalanceRow(label: "Cash", current: account.cash)
                        BalanceRow(label: "Cash Withdrawable", current: account.cash) 
                        BalanceRow(label: "Pending Transfer Out", current: 0.0)
                        
                        SectionHeader(title: "Positions")
                        BalanceRow(label: "Equity", current: account.equity)
                        BalanceRow(label: "Long Market Value", current: account.longMarketValue)
                        BalanceRow(label: "Short Market Value", current: account.shortMarketValue)
                        BalanceRow(label: "Position Market Value", current: account.positionMarketValue)
                        
                        SectionHeader(title: "Miscellaneous")
                        BalanceRow(label: "Accrued Fees", current: account.accruedFees)
                        HStack {
                            Text("Day Trade Count")
                                .foregroundStyle(Theme.textSecondary)
                                .font(.subheadline)
                            Spacer()
                            Text("\(account.daytradeCount)")
                                .foregroundStyle(Theme.textPrimary)
                                .font(.subheadline.monospaced())
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Balances")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Theme.brandPurple)
            .padding(.horizontal)
            .padding(.top, 8)
    }
}

struct BalanceRow: View {
    let label: String
    let current: Double
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(Theme.textSecondary)
                .font(.subheadline)
            Spacer()
            Text("$\(current, specifier: "%.2f")")
                .foregroundStyle(Theme.textPrimary)
                .font(.subheadline.monospaced())
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
        
        Divider()
            .background(Theme.textSecondary.opacity(0.1))
            .padding(.leading)
    }
}
