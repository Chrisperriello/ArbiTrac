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

- [ ] __Step 1.1: Dependecies and Theme__

    - Add Riverpod, Firebase Core, Firebase Auth, Cloud Firestor, and Shared Preferences to pubspec.yaml

    - Create a centralized ThemeData class in lib/theme.dart (colors, typography)

- [ ] __Step 1.2: Base Architecture__
    
    - Set up the folder structure (models, screens, widgets, services, providers).

    - Wrap MyApp in a ProviderScope

- [ ] __Step 1.3: Security and Config__

    - Create a .env file for API keys and a Config 
    
    - Set up flutter_secure_storage for sensitive user tokens

- [ ] __Step 1.4: Math Utility__

    - Create lib/core/utils/arb_engine.dart
    
    - Write a static function that impments the sum(1 / sigma_i) < 1 logic using the Decimal package

- [ ] __Step 1.5: Scraper/API__:
    - Create the /lib/services/odds_api_service.dart
    - This will handle all of the heavy lifitng for getting the data 

### Phase 2: The "Minimum Viable Product" (MVP)

*Goal: The The core defining feature of the app must function with mock data or local state. Note: Focus on functionality, not perfect styling yet.*

- Mock data, make sure that in /lib/core/constants/ we have a mock_data.dart file that will assit with all mocking of data for the dashboard and anything else

- [ ] __Step 2.1__: Main Screen
    - Develop the main screen for the application

    - We will use tradtional flutter framework to create a place that displays the following:
        - A login button for existing users
        - A sign up button for new users
    - Phase 3 will implment thesee but we need to create the screens for them 

    - [ ] __Step 2.1.1: Login__:
        - Using a text box display a place to add in the Username
        - Using a text box display a place to add password
        - Then an elevated button to allow us to start the login
        - Allow for a icon button in the top left for us to go back to the main screen
    - [ ] __Step 2.1.2: Sign up__:
        - Using a text box display a place to add in the Username
        - Using a text box display a place to add password
        - Then an elevated button to allow us to start the login
        - Inforce the password being at least 8 charcters and need a special character
        - Allow for a icon button in the top left for us to go back to the main screen

- [ ] __Step 2.2 Dashboard__:
    - This is the main dashboard for the app

    - [ ] __Step 2.2.1: Account Icon__:
        -  Have an icon button in the top left that is a profile button
        - Once pressed have a dropdown popup with the following structure:
            - Display the Username at top
            - Then a settings icon that will go to settings
            - Then a Sign out button that will be used to sign out
        - This can use the flutter PopupMenuButton 
    
    - [ ] __Step 2.2.2 Live Opportunity List__: 
        - Create a scrollable list (ListView) on the Dashboard that displays "Arb Opportunities."
        
        - Each Card should show:
            - Event Name 
            - The two sportsbooks involved 
            - The "Arb %" (Profit margin)
            - The Market (EX: Moneyline)
        - Allow for sorting: So Highest profit or soonest payout ect
        - Freshness indicator: a small timer or pulse icon showing how many seconds ago the odds were updated 
        - Remember that this is mocking so we can use mock data for now
- [ ] __Step 2.3: Manual Arb Calculator__:
        - *Input*: Tow or three text fields for "Odds" from different books
        - Field for "Total Investment": Allow the user to input $100, $300, ect.
        - *Output*: Use the engine to display the "Arbitrage %" and the "Required Stakes" to break even/profit based on a total $ amount
        - Also display:
            - Stake breakdown: "Bet $X on Bookie A, $Y on Bookie B."
            - Net Profit
            
- [ ] __Step 2.4: Watchlist or Favorites__:
    - Allow the user to pin a game they are looking at so they do not lose it if the screen updates 
    - This should use the shared prefrence to save the users favorited sports/games so they do not refilter when the dashboard refreshes
- [ ] __Step 2.5: Search__:
    - Allow for a mag-glass icon to pull up a blurred text box (SearchDelegate) to search for games in the list of all games that are displayed
    
### Phase 3: App Functionality and Intergration

*Goal: Complete major functionality and replace mock data with live cloud and authentication.*

- [ ] __Step 3.1__: Main Screen
    - Intergrate the main screen for the application


    - [ ] __Step 3.1.1: Login__:
        - This will use Firebase Auth to check if the login is valid
        - If an error occurs then add a bottom popup (Toast) to say something like "Invalid Username and/or password, if first time pleas go to sign up"
        - If valid login and bring them to the main dashboard
        - Also start the load of any data from the cloud or local data needed to represent that specific user
    - [ ] __Step 3.1.2: Sign up__:
        - This will use Firebase Auth to check if the sign up is valid
        - If an error occurs then add a bottom popup (Toast) to say something like "Invalid Username and/or password"
        - Inforce the password being at least 8 charcters and need a special character
        - If valid login and bring them to the main dashboard
        - Also start the load of any data from the cloud or local data needed to represent that specific user
    - [ ] __Step 3.1.3: Google__:
        - Alternativley have the sign up page have a google sign up button that uses the firebase Auth google plugin to create or sign up for an account
    - [ ] __Step 3.1.4 Username__: 
        - IF it is the first time that this has been logged in then we need to allow the person to select a Username and store it in the database for display reasons 
        - Create a new screen called UsernameScreen widget class that is a new screen that allows the person to enter in text that will be their username, then store it to the firebase database

    

