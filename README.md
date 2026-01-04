# AlpacaViewer & Paper Trader Tracker

A premium, modern SwiftUI mobile dashboard and log monitoring system for tracking Alpaca paper trading bots. Featuring real-time data, AI-powered trade analysis, and a centralized "Shared Brain" for strategy notes.

## 🚀 Key Features

- **Real-time Portfolio Tracking**: 15-second auto-polling and Manual Pull-to-Refresh for Balance, Positions, and Equity.
- **Detailed Balances**: Comprehensive breakdown of Buying Power (RegT, Day Trading), Margin, and Market Values.
- **AI Portfolio Analyst**: Interactive Gemini-powered chat that analyzes your last 30 trades and current portfolio state.
- **Shared Brain**: Sync strategy notes between the mobile app and the trading bot via Supabase.
- **Bot Log Streamer**: Live `journalctl` log view from your Oracle VM, shipped via a lightweight Python agent.
- **Premium Aesthetics**: High-end "Soft Dark" design with glassmorphism, custom charts, and smooth micro-animations.

## 📁 Project Structure

```text
paperTraderTracker/
├── AlpacaViewer/          # SwiftUI iOS Application
│   ├── AlpacaViewer/      # Source code
│   └── ...
├── log_shipper.py         # VM-side log streaming agent
└── README.md              # This file
```

## 🛠 Setup Instructions

### 1. Supabase Backend
Ensure your Supabase project has the following tables:
- `trade_journal`: For trade history and AI context.
- `trading_notes`: For the Shared Brain strategy notes.
- `bot_logs`: For the terminal log stream.

### 2. AlpacaViewer (iOS App)
1. Open `AlpacaViewer/AlpacaViewer.xcodeproj` in Xcode.
2. Configure `Config.swift` with:
   - `supabaseURL`
   - `supabaseKey`
   - `geminiAPIKey`
3. Run on Simulator or physical device.
4. Input your Alpaca Paper API Keys directly in the app's secure login sheet.

### 3. Log Shipper (VM Side)
To view live server logs in the app:
1. Copy `log_shipper.py` to your trading bot server.
2. Edit the script with your Supabase credentials and service name (e.g., `grok_trading`).
3. Install dependency: `pip install supabase`
4. Run: `python3 log_shipper.py`

## 📊 Technical Stack

- **Frontend**: SwiftUI, Combine, Charts API
- **Backend**: Supabase (PostgreSQL, RLS)
- **AI**: Google Gemini Pro 1.5 (via `google-generative-ai-swift`)
- **VM Agent**: Python 3.9+
- **APIs**: Alpaca Markets V2 (Paper)

## 🛡 Security
- **API Keys**: Alpaca keys are stored locally on the device (State/Memory) and never sent to our backend.
- **RLS**: Ensure Supabase Row Level Security is configured if using a shared database.
# grok-trading-frontend
