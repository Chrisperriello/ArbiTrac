# ArbiTrac

ArbiTrac is a Flutter-based arbitrage betting tracker focused on surfacing profitable cross-sportsbook opportunities in real time.

## Current Project Status

This repository is currently in an early scaffold phase.

- App code currently includes a starter Flutter app in `lib/main.dart`
- Product requirements and architecture are documented in:
  - `REQUIREMENTS.md`
  - `STACK.md`

## Project Goal

ArbiTrac is being built to:

- Ingest odds from multiple sportsbooks
- Identify arbitrage opportunities using precise math
- Show opportunity details (event, market, books, arb %)
- Provide a manual arbitrage calculator
- Support favorites/watchlists and search

## Planned Architecture

Target Flutter structure (from project requirements):

```text
lib/
  core/
    utils/arb_engine.dart
    constants/mock_data.dart
  models/
  services/
  providers/
  screens/
  widgets/
  theme.dart
  main.dart
```

Key technical direction:

- **Framework**: Flutter + Dart
- **State management**: `flutter_riverpod`
- **Precision math**: `decimal` (for odds/stake calculations)
- **Backend**: Firebase Auth + Firestore
- **Local storage**: `shared_preferences` + `flutter_secure_storage`

## Run & Development Commands

```bash
flutter run
flutter build apk
flutter build ios
flutter test
flutter analyze
```

## Notes

- During early MVP work, mock data is expected for odds flows.
- API keys and secrets should be loaded from `.env` (never hard-coded).
