# BijecBet Project Mandates

This document defines the foundational standards and architectural requirements for the BijecBet project. All AI-driven development must adhere strictly to these guidelines.

## Core Tech Stack
- **Framework:** Flutter (Mobile/Web/Desktop)
- **State Management:** Riverpod (Notifier & AsyncNotifier patterns)
- **Backend:** Firebase (Auth, Firestore)
- **Mathematics:** `decimal` and `rational` packages for arbitrary-precision arithmetic.

## Mathematical Integrity & Precision
- **NEVER** use `double` for betting calculations (odds, stakes, profit, implied probability).
- **Mandatory Types:** Use `Decimal` for all stored and calculated monetary/odds values.
- **Precision:** Maintain a scale of 12 decimal places (`scaleOnInfinitePrecision: 12`) when converting `Rational` to `Decimal`.
- **Rounding:** Perform calculations at high precision. Only truncate or round at the UI presentation layer using `toStringAsFixed()` or similar formatting logic.

## Arbitrage Engine Standards
- **Formula Accuracy:**
  - Implied Probability: `1 / Decimal Odds`
  - Arbitrage Sum (Margin): `sum(implied probabilities)`
  - ROI %: `(1 / Arbitrage Sum - 1) * 100` (Note: The current implementation uses `(1 - ArbSum) * 100`. Future updates should transition to ROI).
- **Market Support:**
  - The `ArbEngine` is outcome-agnostic and supports N outcomes.
  - **Constraint:** Automated scanners must verify that all outcomes in a market (e.g., Over AND Under) share the exact same `point` (Spread/Total) before declaring an arbitrage opportunity.

## UI & Theme (Cyber/Quant)
- **Consistency:** All new widgets must respect the custom `CyberArbTheme` or `QuantTheme`.
- **Animations:** Use the established patterns in `lib/widgets/cyber_animations.dart` for interactive elements.
- **Feedback:** Use `FreshnessIndicator` for real-time odds updates to indicate data latency.

## Coding Conventions
- **Riverpod:** Prefer `AsyncNotifier` for any state that requires network or storage I/O.
- **Error Handling:** Use `AsyncValue` patterns in the UI to handle loading and error states gracefully.
- **Documentation:** Document the mathematical intent of any new calculation logic in `arb_engine.dart`.

