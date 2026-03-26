# 🎯 ArbiTrac: Professional Arbitrage Betting Automation

**ArbiTrac** is a high-precision, real-time analytics engine designed for professional bettors to identify, calculate, and execute arbitrage opportunities across global sportsbooks. Built with Flutter and powered by a custom mathematical engine, ArbiTrac eliminates the guesswork from "sure-bet" strategies.

---

## 🚀 Key Features

### 📡 Real-Time Opportunity Discovery
*   **Live Odds Engine:** Continuous integration with **The Odds API** providing updates on Moneyline (H2H), Spreads, Totals, and Outrights.
*   **Precision Filtering:** Pin your favorite sports and books to cut through the noise and focus on the markets that matter to you.
*   **Freshness Indicators:** Real-time pulse icons and timers show exactly how many seconds ago a line was updated, ensuring you never chase stale odds.

### 🧮 Advanced Mathematical Validation
*   **High-Precision Math:** Built using the `decimal` and `rational` packages to avoid the floating-point errors that can lead to losses in high-stakes betting.
*   **Multi-Leg Support:** A flexible manual calculator that supports 2-leg and 3-leg arbitrage scenarios.
*   **Smart Stake Allocation:** Automatically calculates the exact investment required for each leg to guarantee a profit regardless of the outcome.

### 👤 Seamless User Experience
*   **Unified Dashboard:** A single pane of glass for discovering, searching, and sorting opportunities by profit margin or payout speed.
*   **Search & Discovery:** Instant lookup for games, sportsbooks, and specific markets using a high-performance `SearchDelegate`.
*   **Deep-Dive Analysis:** Drill down into any event to see all reported odds across every bookmaker in the market.

---

## 🧠 The "Math Behind the Magic"

ArbiTrac doesn't just "guess." It uses a rigorous mathematical approach:

1.  **Implied Probability Check:** For any set of outcomes, the system calculates $P = \sum \frac{1}{Decimal Odds_i}$.
2.  **Detection:** If $P < 1$, an arbitrage opportunity exists.
3.  **Optimal Execution:** The system solves for $S_i = \frac{T}{P \times Decimal Odds_i}$, where $T$ is your total investment, ensuring identical payouts across all outcomes.

---

## 🛠️ Technical Excellence

*   **Frontend:** Flutter & Material 3 for a modern, responsive UI.
*   **State Management:** **Riverpod** for a robust, reactive, and testable data flow.
*   **Backend:** **Firebase Auth** (Email & Google) and **Cloud Firestore** for secure profile management and real-time data syncing.
*   **Resilience:** Advanced local caching with `SharedPreferences` to maximize performance and minimize API token consumption.
*   **Architecture:** Clean, layered architecture separating core math logic, data services, and UI components.

---

## 🛤️ Product Roadmap

### 🟡 Now: The MVP Core
*   [x] Real-time opportunity extraction from Live API.
*   [x] Precision math engine for 2-way and 3-way arbs.
*   [x] Manual calculator for custom scenarios.
*   [x] Local persistence for watchlists and pinned sports.
*   [x] Firebase Authentication (Email/Google).

### 🔵 Soon: Phase 3 Integration
*   **Cloud Syncing:** Seamlessly sync your pinned games and sports across all your devices via Firestore.
*   **Push Notifications:** Get alerted the instant a high-margin (>3%) opportunity is detected.
*   **Expanded Markets:** Support for 3-way markets (Soccer/Draw) and player props.

### 🟢 Future: Professional Suite
*   **Risk Management Tools:** Track your actual P&L and account for sportsbook limits and "limit" warnings.
*   **Custom API Keys:** Allow power users to plug in their own Odds API or Betradar keys for ultra-low latency.
*   **One-Tap Execution:** Deep-linking directly to sportsbook bet-slips (where supported).

---

## 🏁 Getting Started

### Prerequisites
- Flutter SDK (Stable)
- A `.env` file containing your `ODDS_API_KEY`.

### Installation
1.  Clone the repository.
2.  Run `flutter pub get`.
3.  Configure Firebase using `flutterfire configure`.
4.  Execute `flutter run`.

---

## ⚖️ Legal & Risk
ArbiTrac is an analytics and tracking tool. Users are responsible for ensuring compliance with local gambling laws and sportsbook Terms of Service. Arbitrage betting involves execution risk (lines moving before both bets are placed); ArbiTrac provides the data, but the user manages the execution.

---
*Developed by CJ Perriello*