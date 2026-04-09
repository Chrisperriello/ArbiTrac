# Project Requirements 

__Developer__: CJ Perriello

__Description__: The core if an Arbitrage betting automation software. The core of this project is to be able to pull live betting data from differenet platforms and compare certain bets with each other to find a place where an overlapping of the odds allows you to 100% make a profit. This should notifiy you when it finds an oppertunity, it should display live odds and allow you to do things like favorite sports , types of bets, ect.


---

## AI Assistant Guardrails
AI Assistant: When reading this file to implement a step, you MUST adhere to the following architectural rules:
1. __State Management__: Use flutter_riverpod exclusively. Do not use setState for complex logic.
2. __Architecture__: Maintain strict separation of concerns:
- /models: Pure Dart data classes (use json_serializable or freezed if helpful).
- /services: Backend/API communication only. No UI code.
- /providers: Riverpod providers linking services to the UI.
- /screens & /widgets: UI only. Keep files small. Extract complex widgets into their own files.
3. __Local Storage__: Use shared_preferences for local app state (e.g., theme toggles, onboarding
status).
4. __Database__: Use Firebase Firestore for persistent cloud data.
5. __Stepwise Execution__ : Only implement the specific step requested in the prompt. Do not jump ahead.


---

## Implementation Map

### Phase 1: Project Setup and Core Infrastructure

- [x] __Step 1.1: Dependecies and Theme__

    - Add Riverpod, Firebase Core, Firebase Auth, Cloud Firestor, and Shared Preferences to pubspec.yaml

    - Create a centralized ThemeData class in lib/theme.dart (colors, typography)

- [x] __Step 1.2: Base Architecture__
    
    - Set up the folder structure (models, screens, widgets, services, providers).

    - Wrap MyApp in a ProviderScope

- [x] __Step 1.3: Security and Config__

    - Create a .env file for API keys and a Config 
    
    - Set up flutter_secure_storage for sensitive user tokens

- [x] __Step 1.4: Math Utility__

    - Create lib/core/utils/arb_engine.dart
    
    - Write a static function that impments the sum(1 / sigma_i) < 1 logic using the Decimal package

    - It should also handle Implied Probability: P = 1 / (Decimal Odds)

    - Indivdual Stakes (Si): Si = (Total Investment / (Arbitrage Percentage) * Sigma_i)

- [x] __Step 1.5: Scraper/API__
    - Create the /lib/services/odds_api_service.dart
    - This will handle all of the heavy lifitng for getting the data 
    - For testing purposes limit api use which means:
        - Use Mock data until the full integration of the math and the use of the API pulling system until really necessary 
        - Use a simple local chaching mechanism (Shared_preferences) SO that everytime you host-restart the app during UI dev, you aren't burning tokens
    - Added conversion support for American odds (`+/-`) into normalized decimal odds (`decimal_price`) in `odds_api_service.dart`

### Phase 2: The "Minimum Viable Product" (MVP)

*Goal: The The core defining feature of the app must function with mock data or local state. Note: Focus on functionality, not perfect styling yet.*

- Mock data, make sure that in /lib/core/constants/ we have a mock_data.dart file that will assit with all mocking of data for the dashboard and anything else

- Here is the list of Betting Markets I will limit for now. 
    - Head to Head (Moneyline) odds
    - Point Spreads (handicap) odds
    - total (over/under) odds
    - outrighs(futures) odds

- [x] __Step 2.1: Main Screen__
    - Develop the main screen for the application

    - We will use tradtional flutter framework to create a place that displays the following:
        - A login button for existing users
        - A sign up button for new users
    - Phase 3 will implment thesee but we need to create the screens for them 

    - [x] __Step 2.1.1: Login__
        - Using a form,  allow for a place to add in the Username
        - Using a form, allow for a place to add password
        - Then an elevated button to allow us to start the login
        - Allow for a icon button in the top left for us to go back to the main screen
    - [x] __Step 2.1.2: Sign up__
        - Using a form display,  allow for aplace to add in the Username
        - Using a form display, allow for a place to add password
        - Then an elevated button to allow us to start the login
        - Inforce the password being at least 8 charcters and need a special character
        - Allow for a icon button in the top left for us to go back to the main screen

- [x] __Step 2.2: Dashboard__
    - This is the main dashboard for the app

    - [x] __Step 2.2.1: Account Icon__
        -  Have an icon button in the top left that is a profile button
        - Once pressed have a dropdown popup with the following structure:
            - Display the Username at top
            - Then a settings icon that will go to settings
            - Then a Sign out button that will be used to sign out
        - This can use the flutter PopupMenuButton 
    
    - [x] __Step 2.2.2: Live Opportunity List__ 
        - Create a scrollable list (ListView) on the Dashboard that displays "Arb Opportunities."
        
        - Each Card should show:
            - Event Name 
            - The two sportsbooks involved 
            - The "Arb %" (Profit margin)
            - The Market (EX: Moneyline)
        - Allow for sorting: So Highest profit or soonest payout ect
        - Freshness indicator: a small timer or pulse icon showing how many seconds ago the odds were updated 
        - Remember that this is mocking so we can use mock data for now
- [x] __Step 2.3: Manual Arb Calculator__
    - *Input*: Tow or three text fields for "Odds" from different books
    - Odds mode toggle: user can switch between Decimal and American odds entry
    - In American mode each odds line uses a `+/-` dropdown and a numeric field (no sign parsing from text)
    - Field for "Total Investment": Allow the user to input $100, $300, ect.
    - *Output*: Use the engine to display the "Arbitrage %" and the "Required Stakes" to break even/profit based on a total $ amount
    - Also display:
        - Stake breakdown: "Bet $X on Bookie A, $Y on Bookie B."
        - Net Profit
            
- [x] __Step 2.4: Watchlist or Favorites__
    - Allow the user to pin a game they are looking at so they do not lose it if the screen updates 
    - This should use the shared prefrence to save the users favorited sports/games so they do not refilter when the dashboard refreshes
    - Implemented local pinned-watchlist persistence with `shared_preferences` and favorites-first ordering on dashboard cards
    - Implemented pinned sport preferences with persisted `shared_preferences` keys and dashboard filtering by selected sports
- [x] __Step 2.5: Search__
    - Allow for a mag-glass icon to pull up a blurred text box (SearchDelegate) to search for games in the list of all games that are displayed
    - Added app bar search icon and `SearchDelegate` flow that searches displayed games by event, market, sportsbook, and sport

- [x] __Step 2.6: Sports Card__:
    - You should be able to press on a card and see 
        - the two teams or players or opponents
        - what time the game starts and then 
        - Should be able to select from the given markets and get every odds from every book 
    - Implemented tap-through detail screen with market selector and full bookmaker odds display per selected market
    
### Phase 3: App Functionality and Intergration

*Goal: Complete major functionality and replace mock data with live cloud and authentication.*

- [x] __Step 3.1: Main Screen__
    - Intergrate the main screen for the application


    - [x] __Step 3.1.1: Login__
        - This will use Firebase Auth to check if the login is valid
        - If an error occurs then add a bottom popup (Toast) to say something like "Invalid Username and/or password, if first time pleas go to sign up"
        - If valid login and bring them to the main dashboard
        - Also start the load of any data from the cloud or local data needed to represent that specific user
        - Implemented Firebase email/password sign-in with bottom `SnackBar` error feedback and success routing to dashboard
    - [x] __Step 3.1.2: Sign up__
        - This will use Firebase Auth to check if the sign up is valid
        - If an error occurs then add a bottom popup (Toast) to say something like "Invalid Username and/or password"
        - Inforce the password being at least 8 charcters and need a special character
        - If valid login and bring them to the main dashboard
        - Also start the load of any data from the cloud or local data needed to represent that specific user
        - Implemented Firebase email/password account creation with bottom `SnackBar` error feedback and success routing to dashboard
    - [x] __Step 3.1.3: Google__
        - Alternativley have the sign up page have a google sign up button that uses the firebase Auth google plugin to create or sign up for an account
        - Implemented Google sign-in button on Sign Up screen and Firebase credential-based sign-in flow
    - [x] __Step 3.1.4: Username__
        - IF it is the first time that this has been logged in then we need to allow the person to select a Username and store it in the database for display reasons 
        - Create a new screen called UsernameScreen widget class that is a new screen that allows the person to enter in text that will be their username, then store it to the firebase database

- [x] __Step 3.2: The Auth Gate__
    - Create an AuthGate widget that listens to the firebase auth state stream
    - if user == null, show LoginScreen. Else, show MVP screen.
    - Logout Lofic: Implement the functionality for the "Sign out" button defined in Phase 2.2.1


- [x] __Step 3.3: Cloud Database Integration__
    
    - [x] __Step 3.3.1: Live odds integration__
        - Replace mock_data.dart with API-backed local odds storage/cache in OddsApiService
        - Keep live odds local on-device and refresh them from the API on an interval
        - Connect the Live opportunity list (2.2.2) to the refreshed local/API stream provider

    - [x] __Step 3.3.2: Sorting and Filtering Logic__:

        - Implement the functional logic for the "Highest Profit" and "Soonest Payout" sorting ehaders creaded in Phase 2

    - [x] __Step 3.3.3: Favorites Cloud Sync__:
        - Upgrade Phase 2.4 (Watchlist). Instead of only shared_preferences, sync favorited games to the users firestore document so they persist across devices

- [x] __Step 3.4: Manuel Arb Calculator Logic__
    - Connect the ArbEngine (Phae 1.4) to the UI fields from Phase 2.3
    - Ensure the "Total Investment" field updates teh "Required Stakes" dynamically as the user tpyes (using a StateProvider)



### Phase 4: Polish and persistence

- [x] __Step 4.1: Local State (Shared Preferences)__
    - Implemet a feature that saves to the local device (e.g., a "Dark Mode" toggle or a "Don't show
    this again" intro screen)


- [ ] __Step 4.2: Error Handling and Loading State__
    - Ensure all asynchronous Riverpod provider correctly handle loading and error states in the UI using AsyncValue.when()

- [x] __Step 4.3: Final Theming and Cleanup__
    - Apply Consistent PAdding, colors, and typography
    - Refacto any files that have grown too large 
    

- [ ] __Step 5: Market__(As of March 26, skip might come back):
    - This is if there is anytime left at all

    - Add different plug ins for different APIs that pull from markets and get JSON formatted data. This will allow users to put in their own api keys for services if they have them


### Phase 5: Addtion 

This section should be dated and also numbered for prioty (number removed once completed)

- [x] __5.1 Book filter__:
    *Goal: Give users the power to filter their "Live Opportunity List" based on the specific books they actually have accounts with, ensuring every displayed "Arb" is actionable.*

    - [x] __5.1.1: Favorite Sportsbooks (Logic & Filtering)__
        - **The Filtering Engine**: Enhance the `opportunitiesProvider` to accept a second list of filters: `activeBookmakers`.
        - **Logic Proximity**: Co-locate the methods for filtering books in the same Service/Provider as the sport-category filtering to ensure a dual-pass check:
            1. *Is the sport category currently active?*
            2. *Are BOTH bookmakers involved in this specific Arb currently active?*
        - **The Arb-Validity Rule**: Strictly exclude any opportunity from the dashboard if one or more of the books involved are not in the user's "Favorites" list.
        - Implemented provider-layer dual-pass filtering (`sport` then `bookmakers`) with `activeBookmakerKeysProvider`; empty bookmaker selection defaults to no bookmaker constraint.

    - [x] __5.1.2: Saving (Dual-Layer Persistence)__
        - **Local-First Strategy**: Store favorite sportsbook IDs in `shared_preferences` to allow the UI to render filters instantly upon app launch, even before the Firebase handshake.
        - **Cloud-Sync Strategy**: Trigger an asynchronous update to the user's Firestore document (e.g., `users/{userId}/preferences/bookmakers`) whenever a toggle occurs.
        - **Conflict Resolution**: Implement a sync check on app initialization that compares local timestamps against Firestore to ensure the user's latest preferences are reflected across all devices.
        - Implemented `favoriteBookmakerKeysProvider` + `WatchlistService` persistence with local timestamped `shared_preferences`, Firestore sync at `users/{uid}/preferences/bookmakers`, and latest-write conflict resolution on initialization.

    - [x] __5.1.3: UI Implementation (The Filter Stack)__
        - **The Filter Bar Hierarchy**: Place a horizontal scrollable row of `FilterChip` widgets directly beneath the "Favorite Sports" row to create a logical "Filter Stack."
        - **Component Design**: 
            - Use sportsbook branding/logos within the chips for quick recognition.
            - Utilize high-contrast "Active" states (defined in `theme.dart`) to show which books are currently filtering the list.
            - Integrate a "Select All" toggle at the start of the row to prevent "Filter Fatigue" when managing multiple books.
        - **Reactivity**: Ensure the Dashboard `ListView` reactively updates via Riverpod as soon as a chip is toggled.
        - Added a dashboard sportsbook chip row beneath pinned sports with a leading "Select All" toggle, high-contrast active chip styling from `QuantTheme`, and reactive Riverpod-driven updates tied to persisted bookmaker preferences.

        
- [ ] __5.2: Settings expanded__:
    *Goal: Transform the basic settings into a granular control center for user preferences and app aesthetics, utilizing a tabbed layout for improved navigation.*

    - [x] __5.2.1: Settings Tabbed Layout (Favorites Hub)__
        - **Navigation Architecture**: Implement a `DefaultTabController` at the top of the Settings screen with a `TabBar` containing "Favorites" and "Theme" tabs.
        - **The Favorites Tab**: Organize this view into two distinct, vertically scrollable sections: "Favorite Sports" and "Favorite Books."
        - **Section Layout**: Each section will feature a header with a "Plus" (+) action button to trigger the addition workflow.
        - Implemented `DefaultTabController` settings shell with Favorites/Theme tabs, vertically scrollable favorites sections, and section header add actions.
        - [x] __5.2.1.1: Setting Favorite Card Component__
            - **Visual Design**: A streamlined, low-profile `Card` widget displaying the name of the entity (Sport or Bookmaker).
            - **Interaction**: Include a trailing "Minus" (-) or "Trash" icon button. When pressed, it triggers the removal logic from both `shared_preferences` and `Firestore`.
            - Implemented `_SettingFavoriteCard` low-profile cards with trailing remove buttons wired to the existing Riverpod favorite toggles (local + Firestore sync path).
        - [x] __5.2.1.2: Add-Favorite Modal (The Discovery Overlay)__
            - **UI/UX**: Implement a `showDialog` or `showModalBottomSheet` with a `BackdropFilter` to create a professional blurred-background effect. 
            - **Dynamic Loading**: The modal will populate cards based on the API's full list of supported sports or bookmakers.

            - **Add Logic**: Each card in the modal features a "Plus" (+) button. Once pressed, the item is added to the user's active list, and the UI reactively updates the background Settings page via Riverpod.
            - Added a blurred `showDialog` add-favorite overlay for sports/books with provider-backed dynamic lists and per-item add actions that update favorites immediately.


    - [ ] __5.2.2: Universal Theme Engine & Refactor__
        - **Theme Centralization**: Refactor `lib/theme.dart` into a "Theme Registry." Instead of simple variables, create a class that defines distinct `ThemeData` objects for each mode:
            - **Dark Mode**: High-contrast blacks/greys for night betting.
            - **Quant Mode**: A clean, data-heavy "Bloomberg-style" aesthetic.
            - **Cyber Mode**: Neon accents and dark backgrounds for a high-tech automation feel.
        - **Dynamic Theme Switcher**: 
            - **UI**: In the "Theme" tab of Settings, implement a `DropdownButtonFormField` or a series of `RadioListTile` widgets displaying the available theme names.
            - **State Management**: Connect the selection to a `ThemeNotifier` (Riverpod) that wraps the `MaterialApp`'s `theme` property.
            - **Persistence**: Ensure the selected theme ID is saved to `shared_preferences` so the user's aesthetic preference persists across app restarts.
        
- [ ] __5.3: API limitation calling__:
    Purpose: If we are filtering based on sports books and classes
    - We want api calls to only call sports that are saved as favorites, so only lines for NBA if that is the only favorite
    - WE want api call to only call for the books that the filter has as filtered books
