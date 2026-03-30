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
- Remove all firebase stuff, this needs a complete overhaul
- Go through the entire code base and make sure everything that has firebase api keys are in git ignore 
- Go through the entire project and update the readme.md

3/15
-  Now reveiw yourself on firebase and the firebase_options.dart file  
- Continue to Phase 3

3/16

- read step 3.1.1 and read the codebase and assess next steps for
  integration 
- Lets continue with implmentation 
- If you are done with 3.1.1 check it off in requirements 
- continue to 3.1.2 

3/18
- Begin with step 3.1.3   
- do flutter compile test and see the error    
- Everytime I hit the signup with google button in the sign up it says              
   "Unexpected error occured with google sign in"    
- do flutter anayliss there is an error
- UnImplmeted error, autheticate is not supported on the web instead use a          
   render button insted - is the error that i get for refrence: Web:                 
   The signInWithPopup method is supported on web platforms, but you must ensure     
   all authorized domains are registered in both the Google Cloud Project and        
   Firebase Auth consoles.     
- Now for the username it says that it failed to save becuase of             
   insufficent permissions    
- failed to save username is now the error no document to update  
- Give me the sign out workflow, we should never have a "guest user" if there is a sign out then it must  
   leave back to the main_screen.dart  
- Now look at requirements and see what is next 
-  Continue to 3.3.1 
- Tell me the entire 3.3.1 plan 
- Do you understand how the OddsAPI works 
- Now do you understand the point of api call conservation, we store these api pulls locally so that we do not refresh super quickly adn use
  all our tokens, In the end we can control the refresh rate on the api through the UI and also give our own api keys but I want to make sure
  you understand that
  - No you did it wrong, the data comes from oddsAPI not from firebase, once we pull it we store it (probably locally) thats not what you did 
  - The fallback should not be mock data, mock data is useless, just use either stored data or the api clal 
  - OKAY THIS IS IMPORTANT AND I WANT TO MAKE SURE FOR TESTING how do i set how often the api key calls refresh, calalcuate the number call and
  amke sure i dont overload my key instantly on start up 

  3/26
  -  Right now I want you to explore the api calls all it is giving is futures but I want the outlined
  h2h,
     spreads, ect 
     -This is all it returns this is from inspect application local data odd_api_cache_odds: <pasted_content
file="/Users/chrisperriello/.copilot/session-state/2ece46b6-c631-4218-9fb7-e490facb54f1/files/paste-177
4536051041.txt" size="47.4 KB" lines="1" />

- Check off all step requirments that have been done but not checked
- Why is 3.3.1 and 3.3.3 not implemented yet explain fully 
- Lets rewrite 3.3.1, odds should live locally and be refreshed by the api the firestore does nothing
for that 
- Now I do want favorites to be added to the firestore and code base 
-  Bug fix plan it out: if i have already registerd an email on either the normal auth or the google auth
  then i want it to return it to thre main screen and tell the user (on a pop up) that you need to sign
  in throught the sign in (something like "alreadyed registerde go throgh sign up) so go to the sign up
  pipeline and if we get that they are already signed up then route them to main screen and dispaly
  popup 


3/30
-  Okay implment 4.1 