# Tech Stack: Arbitrage Betting Automation

This document outlines the complete technical stack for the Arbitrage project, organized by architectural layer.

---

## 📱 Frontend (Mobile App)
- **Framework**: [Flutter](https://flutter.dev/) (Stable Channel)
- **Language**: [Dart](https://dart.dev/)
- **State Management**: [Riverpod 2.x](https://riverpod.dev/) (using `flutter_riverpod` and `riverpod_annotation`)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router) or Flutter Navigator 2.0
- **Local Storage**: 
    - `shared_preferences`: For UI state (theme, onboarding).
    - `flutter_secure_storage`: For sensitive user tokens and API keys.

---

## ⚙️ Core Logic & Math Engine
- **Precision Math**: [decimal](https://pub.dev/packages/decimal) package (to avoid floating-point errors in odds calculation).
- **Business Logic**: Pure Dart classes in `lib/core/utils/arb_engine.dart`.
- **Logic Patterns**: 
    - Formula: $$Arbitrage \% = (\sum \frac{1}{Odds_i}) < 1$$
    - Automated Stake Calculation: Proportional distribution based on total investment.

---

## ☁️ Backend & Infrastructure
- **BaaS**: [Firebase](https://firebase.google.com/)
    - **Authentication**: Firebase Auth (Email/Password & Google Sign-In).
    - **Database**: Cloud Firestore (Real-time updates for live odds and user watchlists).
    - **Cloud Functions**: (Optional) For server-side scraping or heavy background processing.
- **Environment Management**: [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) for `.env` file handling.

---

## 📡 Data & Networking
- **API Client**: [Dio](https://pub.dev/packages/dio) (for robust HTTP requests with interceptors).
- **Serialization**: [json_serializable](https://pub.dev/packages/json_serializable) & [freezed](https://pub.dev/packages/freezed) (for immutable models).
- **External Data**: 
    - **Odds API**: (e.g., [The Odds API](https://the-odds-api.com/)) for real-time sportsbook data.
    - **Web Scraping**: (If applicable) Python/BeautifulSoup or Puppeteer services.

---

## 🛠️ Development Tools
- **IDE**: VS Code or Android Studio.
- **Version Control**: Git (GitHub/GitLab).
- **CI/CD**: Codemagic or GitHub Actions (for automated builds).
- **Testing**:
    - `flutter_test`: Unit and Widget testing.
    - `mocktail`: For mocking service dependencies.

---

## 🎨 UI/UX Resources
- **Design System**: Material Design 3.
- **Icons**: `material_design_icons_flutter`.
- **Theming**: Custom `ThemeData` defined in `lib/theme.dart`.