REMEMBER BEFORE ANY SESSION YOU SHOULD HAVE READ AND COMPLETED STARTUP.md 

Prompts 

3/4: 
- Read STARTUP.md
- Exectute and do everything STARTUP.md stays
- Begin Phase 1, get an overview of what you want to do once complete be ready for more prompts
- Just making sure that you have in memory to refer back to REQUIREMENTS.md not just your own plan
- Continue on with 1.1
- Make sure if it is complete then to check it off in the requirements.md 
- Continue to 1.2
- Continue to 1.3
- Session Path = copilot --resume=843d6acd-392a-46db-a828-cd012e25f7e5


3/4

- Read STARTUP.md and do what it says
-  Do Step 1.4
- Do step 1.5 
- this is refrence of what the json data is: [Paste #1 - 218 lines] for the mock data 
- I need you to generate a realistic mock JSON response that mimics the output of The Odds API v4 /sports/{sport}/odds endpoint.

Please follow these specific requirements based on their documentation:

Structure: The top-level should be an array of game objects.

Game Fields: Each game must include id, sport_key, sport_title, commence_time (in ISO 8601 format), home_team, and away_team.

Bookmakers: Each game should contain a bookmakers array. Include at least two bookmakers (e.g., 'DraftKings' and 'FanDuel') for each game.

Markets: Inside each bookmaker, include a markets array. Please include 'h2h' (head-to-head) and 'totals' markets.

Outcomes: * For h2h, provide outcomes for both the home and away teams with decimal prices.

For totals, provide 'Over' and 'Under' outcomes, including the point value (e.g., 48.5).

Data Volume: Please generate mock data for 3 different upcoming NFL or NBA games.

Ensure the final output is valid JSON and uses realistic team names and betting odds.


*Not a prompt* I deleted the last input and made the mock.md file 

- Read STARTUP.md and do what it says
- Read step 1.5, then read mock.md and then do step 1.5