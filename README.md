# ArbiTrac

ArbiTrac is a Flutter app that helps bettors find and evaluate arbitrage opportunities across sportsbooks.

At a high level, the app ingests sportsbook odds, identifies markets where the combined implied probability is below 100%, and shows exactly how to split a bankroll across outcomes to lock in a theoretical profit.

## What the app does

ArbiTrac is built around three core user jobs:

- Discover arbitrage opportunities quickly
- Validate stake allocation before placing bets
- Track the games/sports you care about while lines update

The app currently supports these market types in the opportunity pipeline:

- Moneyline (`h2h`)
- Spreads (`spreads`)
- Totals (`totals`)
- Outrights (`outrights`)

## Current user experience

### 1) Entry + auth screens (UI flow)

- Main screen provides `Login` and `Sign Up` entry points
- Login and Sign Up forms are implemented as screen flows
- Successful submit currently routes to dashboard UI flow

### 2) Dashboard (core surface)

The dashboard is the operational center of the app. It includes:

- Live opportunity list (from current data source)
- Sort controls:
  - Highest profit
  - Soonest payout
- Odds freshness indicator (`Updated Xs ago`)
- Pinned favorites (watchlist behavior)
- Pinned-sport filtering chips
- Search icon with `SearchDelegate` game/market/book lookup
- Manual Arb Calculator card (expandable)

Each opportunity card includes:

- Event name
- Sport
- Two sportsbooks used for best-leg prices
- Arb margin (`Arb %`)
- Market label
- Pin/unpin control

### 3) Event detail screen

Tapping an opportunity opens detailed market data:

- Team/event metadata and start time
- Market selector (Moneyline/Spread/Total/Outright when available)
- Bookmaker-by-bookmaker outcome odds
- Per-opportunity investment planner:
  - Enter total investment
  - See suggested stake split
  - View guaranteed payout and net profit estimate

### 4) Manual Arb Calculator

The calculator supports both:

- Decimal odds input
- American odds input with explicit `+/-` sign selectors

Output includes:

- Arbitrage sum value
- Profitability status
- Stake recommendation per leg
- Guaranteed payout
- Net profit

## How ArbiTrac detects arbitrage

Core math lives in `lib/core/utils/arb_engine.dart` and uses `Decimal` + `Rational` for precision-safe calculations (avoids floating point drift).

### Detection rule

For odds legs `o1..on`:

- Implied probability per leg: `Pi = 1 / oi`
- Arbitrage exists when: `sum(Pi) < 1`

### Stake allocation

For total investment `T`, each leg stake is proportionally allocated so payouts converge, producing a near-equal return profile across outcomes.

## Data pipeline (current implementation)

Current odds flow:

`mock_data.dart` -> `OddsApiService` -> Riverpod providers -> Dashboard/Event UI

`OddsApiService` responsibilities:

- Normalize incoming prices (including American -> Decimal conversion)
- Cache payloads via `shared_preferences` (default 5-minute TTL)
- Filter by sport key when needed

This keeps the UI responsive during iteration and preserves API tokens while live integration is still being wired.

## Persistence behavior

- Pinned opportunities: persisted locally with `shared_preferences`
- Pinned sports: persisted locally with `shared_preferences`
- Secure token storage service scaffold exists in `secure_storage_service.dart`

## Project structure

```text
lib/
  core/
    config/app_config.dart
    constants/mock_data.dart
    utils/arb_engine.dart
  models/
    arb_opportunity.dart
    sports_event_detail.dart
  services/
    odds_api_service.dart
    watchlist_service.dart
    secure_storage_service.dart
  providers/
    providers.dart
  screens/
    main_screen.dart
    login_screen.dart
    sign_up_screen.dart
    dashboard_screen.dart
    sports_event_detail_screen.dart
  widgets/
    manual_arb_calculator_card.dart
  theme.dart
  main.dart
```

## Tech stack

- Flutter + Dart
- Material 3 UI
- `flutter_riverpod` state management
- `decimal` / `rational` for odds and stake math
- `shared_preferences` local persistence
- `flutter_secure_storage` sensitive local storage
- `flutter_dotenv` env/config loading
- `firebase_core` + FlutterFire config files (foundation for auth/cloud integration)

## Setup

### Prerequisites

- Flutter SDK (stable channel)
- Platform toolchains (Android Studio / Xcode as needed)

### Install

```bash
flutter pub get
```

### Environment variables

Create a root `.env` file:

```bash
ODDS_API_KEY=your_odds_api_key
```

Loaded via `lib/core/config/app_config.dart`.

### Firebase configuration

If working on cloud/auth paths, run:

```bash
flutterfire configure
```

This generates platform Firebase config files and `lib/firebase_options.dart`.

### Run

```bash
flutter run
```

## Useful commands

```bash
flutter run
flutter analyze
flutter test
flutter build apk
flutter build ios
```

## Security notes

- Never hard-code API keys or tokens in source.
- Keep secrets in `.env` and Firebase config files.
- Sensitive Firebase/env files are covered by `.gitignore`.
- If a secret is ever committed, rotate it immediately.

## What is implemented vs pending

Implemented now:

- Dashboard opportunity discovery and sorting
- Manual calculator with Decimal/American support
- Search and detail drill-down
- Local favorites and pinned-sport persistence

Still being finalized:

- Firebase Auth gate and session routing
- Firestore stream as live data source
- Cross-device cloud sync for favorites/watchlists

## Important reminder

ArbiTrac is an analytics/tracking tool. Users are responsible for legal compliance, sportsbook terms, and execution risk in their region.
