import SwiftUI
import Combine
import Charts

struct Trade: Identifiable, Decodable {
    let id: String
    let symbol: String
    let side: String
    let qty: Double
    let price: Double
    let filledAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case side
        case qty
        case price
        case filledAt = "transaction_time"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        symbol = try container.decode(String.self, forKey: .symbol)
        side = try container.decode(String.self, forKey: .side)
        
        if let qtyString = try? container.decode(String.self, forKey: .qty), let qtyValue = Double(qtyString) {
            qty = qtyValue
        } else if let qtyNum = try? container.decode(Double.self, forKey: .qty) {
            qty = qtyNum
        } else {
            qty = 0
        }
        
        if let priceString = try? container.decode(String.self, forKey: .price), let priceValue = Double(priceString) {
            price = priceValue
        } else if let priceNum = try? container.decode(Double.self, forKey: .price) {
            price = priceNum
        } else {
            price = 0
        }
        
        let filledAtString = try container.decode(String.self, forKey: .filledAt)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        filledAt = formatter.date(from: filledAtString) ?? Date()
    }
}

struct AlpacaCredentials: Equatable {
    var apiKey: String
    var apiSecret: String
}

struct PortfolioEquityPoint: Identifiable, Decodable {
    let id = UUID()
    let timestamp: Int
    let equity: Double
    
    enum CodingKeys: String, CodingKey {
        case timestamp
        case equity
    }
}

struct PortfolioHistory: Decodable {
    let equity: [Double]
    let timestamps: [Int]
    
    enum CodingKeys: String, CodingKey {
        case equity
        case timestamps = "timestamp"
    }
}

struct PortfolioAccount: Decodable {
    let equity: Double
    let cash: Double
    let buyingPower: Double
    let lastEquity: Double
    
    let regtBuyingPower: Double
    let daytradingBuyingPower: Double
    let effectiveBuyingPower: Double
    let nonMarginableBuyingPower: Double
    
    let initialMargin: Double
    let maintenanceMargin: Double
    
    let accruedFees: Double
    let daytradeCount: Int
    
    let longMarketValue: Double
    let shortMarketValue: Double
    let positionMarketValue: Double
    
    enum CodingKeys: String, CodingKey {
        case equity
        case cash
        case buyingPower = "buying_power"
        case lastEquity = "last_equity"
        case regtBuyingPower = "regt_buying_power"
        case daytradingBuyingPower = "daytrading_buying_power"
        case effectiveBuyingPower = "effective_buying_power"
        case nonMarginableBuyingPower = "non_marginable_buying_power"
        case initialMargin = "initial_margin"
        case maintenanceMargin = "maintenance_margin"
        case accruedFees = "accrued_fees"
        case daytradeCount = "daytrade_count"
        case longMarketValue = "long_market_value"
        case shortMarketValue = "short_market_value"
        case positionMarketValue = "position_market_value"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        func decodeDouble(_ key: CodingKeys) -> Double {
            if let val = try? container.decode(Double.self, forKey: key) { return val }
            if let str = try? container.decode(String.self, forKey: key), let val = Double(str) { return val }
            return 0.0
        }
        
        func decodeInt(_ key: CodingKeys) -> Int {
            if let val = try? container.decode(Int.self, forKey: key) { return val }
            if let str = try? container.decode(String.self, forKey: key), let val = Int(str) { return val }
            return 0
        }
        
        equity = decodeDouble(.equity)
        cash = decodeDouble(.cash)
        buyingPower = decodeDouble(.buyingPower)
        lastEquity = decodeDouble(.lastEquity)
        
        regtBuyingPower = decodeDouble(.regtBuyingPower)
        daytradingBuyingPower = decodeDouble(.daytradingBuyingPower)
        effectiveBuyingPower = decodeDouble(.effectiveBuyingPower)
        nonMarginableBuyingPower = decodeDouble(.nonMarginableBuyingPower)
        
        initialMargin = decodeDouble(.initialMargin)
        maintenanceMargin = decodeDouble(.maintenanceMargin)
        
        accruedFees = decodeDouble(.accruedFees)
        daytradeCount = decodeInt(.daytradeCount)
        
        longMarketValue = decodeDouble(.longMarketValue)
        shortMarketValue = decodeDouble(.shortMarketValue)
        
        if let val = try? container.decode(String.self, forKey: .positionMarketValue), let d = Double(val) {
            positionMarketValue = d
        } else if let val = try? container.decode(Double.self, forKey: .positionMarketValue) {
            positionMarketValue = val
        } else {
            positionMarketValue = abs(decodeDouble(.longMarketValue)) + abs(decodeDouble(.shortMarketValue))
        }
    }
}

struct Position: Identifiable, Decodable {
    var id: String { symbol }
    let symbol: String
    let qty: Double
    let marketValue: Double
    let currentPrice: Double
    let unrealizedPL: Double
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case qty
        case marketValue = "market_value"
        case currentPrice = "current_price"
        case unrealizedPL = "unrealized_pl"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        symbol = try container.decode(String.self, forKey: .symbol)
        
        func decodeDouble(_ key: CodingKeys) -> Double {
            if let val = try? container.decode(Double.self, forKey: key) { return val }
            if let str = try? container.decode(String.self, forKey: key), let val = Double(str) { return val }
            return 0.0
        }
        
        qty = decodeDouble(.qty)
        marketValue = decodeDouble(.marketValue)
        currentPrice = decodeDouble(.currentPrice)
        unrealizedPL = decodeDouble(.unrealizedPL)
    }
}

class TradeViewModel: ObservableObject {
    @Published var trades: [Trade] = []
    @Published var errorMessage: String? = nil
    @Published var loading: Bool = false
    private var credentials: AlpacaCredentials?
    
    @Published var portfolioHistory: [PortfolioEquityPoint] = []
    @Published var account: PortfolioAccount?
    @Published var positions: [Position] = []
    
    var balance: Double { account?.equity ?? 0.0 }
    
    @Published var percentChange: Double = 0.0
    @Published var selectedRange: String = "1D"
    @Published var loadingHistory: Bool = false
    
    private var timer: Timer?
    
    init(credentials: AlpacaCredentials? = nil) {
        self.credentials = credentials
        loadTrades()
    }
    
    func setCredentials(_ credentials: AlpacaCredentials) {
        self.credentials = credentials
        loadTrades()
        fetchAccountBalance()
        fetchPositions()
        fetchPortfolioHistory(for: selectedRange)
        
        startPolling()
    }
    
    func startPolling() {
        stopPolling()
        timer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            print("Refreshing data...")
            Task { await self.loadTradesAsync(silent: true) }
            self.fetchAccountBalance()
            self.fetchPositions()
        }
    }
    
    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
    
    func refreshAll() async {
        guard credentials != nil else { return }
        print("Pull to refresh...")
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadTradesAsync(silent: true) }
            group.addTask { await self.fetchAccountAsync() }
            group.addTask { await self.fetchPositionsAsync() }
            group.addTask { await self.fetchPortfolioHistoryAsync(for: self.selectedRange) }
        }
    }

    @MainActor
    func loadTrades(silent: Bool = false) {
        Task { await loadTradesAsync(silent: silent) }
    }
    
    @MainActor
    func loadTradesAsync(silent: Bool = false) async {
        guard let credentials = credentials else {
            self.trades = []
            return
        }
        if !silent { self.loading = true }
        self.errorMessage = nil
        
        do {
            let url = URL(string: "https://paper-api.alpaca.markets/v2/account/activities?activity_types=FILL")!
            var request = URLRequest(url: url)
            request.setValue(credentials.apiKey, forHTTPHeaderField: "APCA-API-KEY-ID")
            request.setValue(credentials.apiSecret, forHTTPHeaderField: "APCA-API-SECRET-KEY")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            if let trades = try? JSONDecoder().decode([Trade].self, from: data) {
                self.trades = trades
                self.errorMessage = trades.isEmpty ? "No trades found." : nil
            } else {
                self.trades = []
                self.errorMessage = "Unexpected response from Alpaca API."
            }
        } catch {
            self.errorMessage = "Failed to load trades: \(error.localizedDescription)"
            self.trades = []
        }
        self.loading = false
    }
    
    func fetchAccountBalance() {
        Task { await fetchAccountAsync() }
    }
    
    func fetchAccountAsync() async {
        guard let credentials = credentials else { return }
        do {
            let url = URL(string: "https://paper-api.alpaca.markets/v2/account")!
            var request = URLRequest(url: url)
            request.setValue(credentials.apiKey, forHTTPHeaderField: "APCA-API-KEY-ID")
            request.setValue(credentials.apiSecret, forHTTPHeaderField: "APCA-API-SECRET-KEY")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else { return }
            
            if let acc = try? JSONDecoder().decode(PortfolioAccount.self, from: data) {
                await MainActor.run { self.account = acc }
            }
        } catch {
            print("Error fetching account: \(error)")
        }
    }
    
    func fetchPositions() {
        Task { await fetchPositionsAsync() }
    }
    
    func fetchPositionsAsync() async {
        guard let credentials = credentials else { return }
        do {
            let url = URL(string: "https://paper-api.alpaca.markets/v2/positions")!
            var request = URLRequest(url: url)
            request.setValue(credentials.apiKey, forHTTPHeaderField: "APCA-API-KEY-ID")
            request.setValue(credentials.apiSecret, forHTTPHeaderField: "APCA-API-SECRET-KEY")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else { return }
            
            if let pos = try? JSONDecoder().decode([Position].self, from: data) {
                await MainActor.run { self.positions = pos }
            }
        } catch {
            print("Error fetching positions: \(error)")
        }
    }
    
    func fetchPortfolioHistory(for range: String) {
        Task { await fetchPortfolioHistoryAsync(for: range) }
    }
    
    func fetchPortfolioHistoryAsync(for range: String) async {
        guard let credentials = credentials else { return }
        await MainActor.run { loadingHistory = true }
        
        do {
            var period = "1D"
            var timeframe = "5Min"
            switch range {
            case "1D": period = "1D"; timeframe = "5Min"
            case "1M": period = "1M"; timeframe = "1H"
            case "1Y": period = "1A"; timeframe = "1D"
            case "ALL": period = "ALL"; timeframe = "1D"
            default: break
            }
            let url = URL(string: "https://paper-api.alpaca.markets/v2/account/portfolio/history?period=\(period)&timeframe=\(timeframe)")!
            var request = URLRequest(url: url)
            request.setValue(credentials.apiKey, forHTTPHeaderField: "APCA-API-KEY-ID")
            request.setValue(credentials.apiSecret, forHTTPHeaderField: "APCA-API-SECRET-KEY")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else {
                await MainActor.run { loadingHistory = false }
                return
            }
            
            let history = try JSONDecoder().decode(PortfolioHistory.self, from: data)
            var points: [PortfolioEquityPoint] = []
            for (idx, eq) in history.equity.enumerated() {
                if eq > 0.01 {
                     points.append(PortfolioEquityPoint(timestamp: history.timestamps[idx], equity: eq))
                }
            }
            
            await MainActor.run {
                self.portfolioHistory = points
                if let first = points.first?.equity, let last = points.last?.equity, first > 0 {
                    self.percentChange = 100.0 * (last - first) / first
                } else {
                    self.percentChange = 0.0
                }
                self.loadingHistory = false
            }
        } catch { 
            print("Error loading history: \(error)")
            await MainActor.run { self.loadingHistory = false }
        }
    }
    }


struct ContentView: View {
    @StateObject private var viewModel = TradeViewModel()
    @State private var showingKeySheet = true
    @State private var tempAPIKey = ""
    @State private var tempAPISecret = ""
    @State private var credentials: AlpacaCredentials? = nil
    
    @State private var showingGlobalChat = false
    @State private var globalContext = ""
    @State private var isLoadingChat = false
    @State private var showingNotes = false
    @State private var showingBotLogs = false
    @State private var showingDetailedBalances = false

    func openGlobalChat() {
        isLoadingChat = true
        Task {
            do {
                let logs = try await SupabaseManager.shared.fetchRecentLogs(limit: 30)
                let combinedContext = logs.map { log in
                    "[\(log.timestamp)] \(log.action) \(log.ticker) @ $\(log.price) (\(log.shares) shares). Reason: \(log.reason)"
                }.joined(separator: "\n\n")
                
                await MainActor.run {
                    self.globalContext = combinedContext.isEmpty ? "No recent trade history." : combinedContext
                    self.showingGlobalChat = true
                    self.isLoadingChat = false
                }
            } catch {
                print("Error fetching logs: \(error)")
                await MainActor.run {
                    self.globalContext = "Error fetching trade history."
                    self.showingGlobalChat = true
                    self.isLoadingChat = false
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        
                        HStack {
                            Button {
                                showingBotLogs = true
                            } label: {
                                Circle()
                                    .fill(Theme.cardBackground)
                                    .frame(width: 44, height: 44)
                                    .overlay(Image(systemName: "terminal.fill").foregroundStyle(Theme.textSecondary))
                            }
                            
                            Spacer()
                            
                            Button {
                                openGlobalChat()
                            } label: {
                                Circle()
                                    .fill(Theme.brandPurple)
                                    .frame(width: 44, height: 44)
                                    .overlay(Image(systemName: "bubble.left.and.bubble.right.fill").foregroundStyle(.white))
                                    .shadow(color: Theme.brandPurple.opacity(0.4), radius: 8, x: 0, y: 4)
                            }
                            .disabled(isLoadingChat)
                            
                            Spacer()

                            Button {
                                showingNotes = true
                            } label: {
                                Circle()
                                    .fill(Theme.cardBackground)
                                    .frame(width: 44, height: 44)
                                    .overlay(Image(systemName: "brain.head.profile").foregroundStyle(Theme.textPrimary))
                            }

                            Spacer()
                            
                            Circle()
                                .fill(Theme.cardBackground)
                                .frame(width: 44, height: 44)
                                .overlay(Image(systemName: "bell.fill").foregroundStyle(Theme.textSecondary))
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Portfolio balance")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                            
                            Text("$\(viewModel.balance, specifier: "%.2f")")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                            
                            HStack(spacing: 8) {
                                Text(String(format: "%+.2f%%", viewModel.percentChange))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Theme.background)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(viewModel.percentChange >= 0 ? Theme.financialGreen : Theme.financialRed)
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        
                        VStack(spacing: 24) {
                            if viewModel.loadingHistory {
                                ProgressView()
                                    .frame(height: 220)
                            } else {
                                let domain = chartDomain
                                Chart(viewModel.portfolioHistory) { point in
                                    AreaMark(
                                        x: .value("Time", Date(timeIntervalSince1970: TimeInterval(point.timestamp))),
                                        yStart: .value("Base", domain.lowerBound),
                                        yEnd: .value("Equity", point.equity)
                                    )
                                    .foregroundStyle(Theme.greenGradient)
                                    .interpolationMethod(.catmullRom)
                                    
                                    LineMark(
                                        x: .value("Time", Date(timeIntervalSince1970: TimeInterval(point.timestamp))),
                                        y: .value("Equity", point.equity)
                                    )
                                    .foregroundStyle(Theme.financialGreen)
                                    .lineStyle(StrokeStyle(lineWidth: 2))
                                    .interpolationMethod(.catmullRom)
                                }
                                .chartYScale(domain: domain)
                                .chartYAxis(.hidden)
                                .chartXAxis(.hidden)
                                .frame(height: 220)
                                .clipped()
                                .padding(.horizontal)
                            }
                            
                            HStack(spacing: 0) {
                                ForEach(["1D", "1M", "1Y", "ALL"], id: \.self) { range in
                                    Button {
                                        viewModel.selectedRange = range
                                        viewModel.fetchPortfolioHistory(for: range)
                                    } label: {
                                        Text(range)
                                            .font(.subheadline.bold())
                                            .foregroundStyle(viewModel.selectedRange == range ? .white : Theme.textSecondary)
                                            .padding(.vertical, 12)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                viewModel.selectedRange == range ?
                                                Capsule().fill(Theme.brandPurple) :
                                                Capsule().fill(Color.clear)
                                            )
                                    }
                                }
                            }
                            .paddingToMatchBackground()
                            .padding(.horizontal)
                        }
                        
                        BalancesCard(account: viewModel.account) {
                            showingDetailedBalances = true
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Portfolio positions")
                                .font(.title3.bold())
                                .foregroundStyle(Theme.textPrimary)
                                .padding(.horizontal)
                            
                            if viewModel.positions.isEmpty {
                                Text("No open positions")
                                    .foregroundStyle(Theme.textSecondary)
                                    .padding(.horizontal)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(viewModel.positions) { pos in
                                        BubblePositionRow(position: pos)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        NavigationLink {
                            TradesListView(trades: viewModel.trades)
                        } label: {
                            HStack {
                                Text("View All Activity")
                                    .font(.headline)
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Theme.brandPurple)
                            }
                            .padding()
                            .background(Theme.cardBackground)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Theme.cardBackground.opacity(0.5), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 40)
                    }
                }
                .refreshable {
                    await viewModel.refreshAll()
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showingGlobalChat) {
            AIChatView(context: globalContext, ticker: "Alpaca Portfolio", isGlobal: true)
        }
        .sheet(isPresented: $showingNotes) {
            NotesView()
        }
        .sheet(isPresented: $showingBotLogs) {
            BotLogsView()
        }
        .sheet(isPresented: $showingDetailedBalances) {
            if let account = viewModel.account {
                DetailedBalancesView(account: account)
            } else {
                Text("No account data loaded.")
                    .font(.headline)
                    .foregroundStyle(Theme.textSecondary)
                    .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showingKeySheet, onDismiss: {
            if let credentials = credentials {
                viewModel.setCredentials(credentials)
            }
        }) {
            APIKeySheet(tempAPIKey: $tempAPIKey, tempAPISecret: $tempAPISecret, credentials: $credentials, isPresented: $showingKeySheet)
        }
    }
    
    private var chartDomain: ClosedRange<Double> {
        let values = viewModel.portfolioHistory.map(\.equity)
        guard let min = values.min(), let max = values.max(), min != max else { return 0...1 }
        let range = max - min
        let padding = range * 0.05
        return (min - padding)...(max + padding)
    }
}

struct TickerIcon: View {
    let symbol: String
    let size: CGFloat
    
    var body: some View {
        let url = URL(string: "https://raw.githubusercontent.com/nvstly/icons/main/ticker_icons/\(symbol.uppercased()).png")
        
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 0.7, height: size * 0.7)
                    .padding(size * 0.15)
                    .background(Circle().fill(Theme.cardBackground))
                    .clipShape(Circle())
            } else if phase.error != nil {
                fallbackView
            } else {
                fallbackView
            }
        }
    }
    
    var fallbackView: some View {
        Circle()
            .fill(Theme.cardBackground.opacity(1.5))
            .frame(width: size, height: size)
            .overlay(
                Text(String(symbol.prefix(1)))
                    .font(.system(size: size * 0.45, weight: .bold))
                    .foregroundStyle(Theme.brandPurple)
            )
    }
}

extension View {
    func paddingToMatchBackground() -> some View {
        self.padding(4).background(Capsule().fill(Theme.cardBackground))
    }
}

struct BubblePositionRow: View {
    let position: Position
    
    var body: some View {
        HStack(spacing: 16) {
            TickerIcon(symbol: position.symbol, size: 48)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(position.symbol)
                    .font(.headline.bold())
                    .foregroundStyle(Theme.textPrimary)
                Text("\(position.qty, specifier: "%.1f") shares")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(position.marketValue, specifier: "%.2f")")
                    .font(.headline.bold())
                    .foregroundStyle(Theme.textPrimary)
                
                let costBasis = position.marketValue - position.unrealizedPL
                let roi = costBasis != 0 ? (position.unrealizedPL / costBasis) * 100 : 0.0
                
                Text("\(position.unrealizedPL >= 0 ? "+" : "")\(position.unrealizedPL, specifier: "%.2f") (\(String(format: "%.2f%%", roi)))")
                    .font(.caption.bold())
                    .foregroundStyle(position.unrealizedPL >= 0 ? Theme.financialGreen : Theme.financialRed)
            }
        }
        .padding()
        .background(Color(hex: "000000").opacity(0.2))
        .cornerRadius(20)
    }
}

struct APIKeySheet: View {
    @Binding var tempAPIKey: String
    @Binding var tempAPISecret: String
    @Binding var credentials: AlpacaCredentials?
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Text("Connect Alpaca")
                        .font(.title2.bold())
                        .foregroundStyle(Theme.textPrimary)
                    
                    VStack(spacing: 20) {
                        CustomTextField(placeholder: "API Key ID", text: $tempAPIKey, isSecure: false)
                        CustomTextField(placeholder: "Secret Key", text: $tempAPISecret, isSecure: true)
                    }
                    
                    Button {
                        credentials = AlpacaCredentials(apiKey: tempAPIKey, apiSecret: tempAPISecret)
                        isPresented = false
                    } label: {
                        Text("Connect")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.brandPurple)
                            .cornerRadius(16)
                    }
                    .disabled(tempAPIKey.isEmpty || tempAPISecret.isEmpty)
                    .opacity(tempAPIKey.isEmpty || tempAPISecret.isEmpty ? 0.6 : 1)
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    
    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(12)
        .foregroundStyle(Theme.textPrimary)
    }
}


struct BalancesCard: View {
    let account: PortfolioAccount?
    let onTapArrow: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "wallet.pass.fill")
                    .foregroundStyle(Theme.textPrimary)
                Text("Balances")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                
                Spacer()
                
                Button {
                    onTapArrow()
                } label: {
                    Circle()
                        .fill(Color(hex: "FDE047"))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "arrow.right")
                                .font(.caption.bold())
                                .foregroundStyle(.black)
                        )
                }
            }
            
            Divider().background(Theme.textSecondary.opacity(0.2))
            
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Buying Power")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Text("$\(account?.buyingPower ?? 0, specifier: "%.2f")")
                        .font(.callout.bold())
                        .foregroundStyle(Theme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cash")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Text("$\(account?.cash ?? 0, specifier: "%.2f")")
                        .font(.callout.bold())
                        .foregroundStyle(Theme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Daily Change")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    
                    let change = calculateDailyChange()
                    Text(String(format: "%+.2f%%", change))
                        .font(.callout.bold())
                        .foregroundStyle(change >= 0 ? Theme.financialGreen : Theme.financialRed)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
    func calculateDailyChange() -> Double {
        guard let acc = account, acc.lastEquity > 0 else { return 0.0 }
        return ((acc.equity - acc.lastEquity) / acc.lastEquity) * 100.0
    }
}

struct TradesListView: View {
    let trades: [Trade]
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            if trades.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.textSecondary)
                    Text("No Recent Activity")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(trades) { trade in
                            NavigationLink(destination: StockDetailView(trade: trade)) {
                                HStack(spacing: 16) {
                                    TickerIcon(symbol: trade.symbol, size: 44)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(trade.symbol)
                                            .font(.headline)
                                            .foregroundStyle(Theme.textPrimary)
                                        Text(trade.filledAt, style: .date)
                                            .font(.caption)
                                            .foregroundStyle(Theme.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(trade.side.uppercased())
                                            .font(.caption2.bold())
                                            .foregroundStyle(Theme.background)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                Capsule()
                                                    .fill(trade.side == "buy" ? Theme.financialGreen : Theme.financialRed)
                                            )
                                        
                                        Text("\(trade.qty, specifier: "%.2f")")
                                            .font(.subheadline)
                                            .foregroundStyle(Theme.textPrimary)
                                            .monospacedDigit()
                                    }
                                }
                                .padding()
                                .background(Color(hex: "000000").opacity(0.2))
                                .cornerRadius(20)
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
}
