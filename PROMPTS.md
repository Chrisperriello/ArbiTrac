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

3/9

- Explain bottleneck issues in arb_engine.dart
- Can we unify everything to use Decimal 

3/10

-  Lets do Step 2.1 in requirements
- Test thiis
- I am getting an error at the comleter.complete(reply) 

3/11
- Continue Pahse 2.2, check off as you go  
- Review the arb_opportunity.dart and step 2.2, dont do it yet make sure you understand how the
  api data gets stored so you know how to use it and manipulate it
- continue with 2.2 check off the boxes as we go 
- Look at the mock_data.dart is there no arb opportunities? 
- can we expand the mock data to include the arb opp for testing purposes
-  Make entire new entries, from your context of mock_data.dart and mock.md, 
  then add it to mock_data.dart
- Lets begin 2.3 and check off as you go
- I want to add a new part to requirements for the arbmanuel, it should eb able to flip inbetween american odds and
   decimal odds, have +/- be a drop down box to control for american odds so its easy for us to know which is which
   so no parsing for it.
- I want you to make the arb app a drop down that can be collased so it is at the top and at the start is
  hidden if slected on the drop down the entire menu will pop up 


3/13

- Continue with 2.4 
- We still have to implment favoriting things like sportts not just games 
- Continue to 2.5 
- Continue to the next requirement 
-  You should be able to add the investment and it tells you what to invest and
  where 
- Refactor it so it is inside the details, so u press on the card and you go in
  and see the investment 
- Continue to the next step 
- firebase startup fails when we set up through google