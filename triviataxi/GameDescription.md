# Trivia Taxi – Initial Application Sketch #

## High-Level Design and Technology Stack 
### PROJECT GOALS 
The goal of Trivia Taxi is to create an engaging, trip-based trivia experience that combines structured gameplay with a sense of progression and competition. The application is designed for casual and competitive trivia players who are seeking short, repeatable gameplay sessions that reward knowledge, strategy, and consistency. By anchoring trivia progression to a virtual journey, Trivia Taxi transforms traditional question-and-answer gameplay into a dynamic experience that evolves over time rather than discrete rounds. The core outcomes of the project are to (1) deliver an intuitive and immersive mobile trivia experience, (2) sustain long-term user engagement through progression and competitive ranking systems, and (3) ensure scalability and performance as the user base grows. 
### TECH STACK 
Trivia Taxi will use a modern, mobile-first technology stack. The backend will be implemented in Python, which is well-suited for rapid development, data processing, and integration with external services such as trivia databases and AI-powered hint generation. The mobile application will be developed using Swift for iOS to ensure high performance, smooth animations, and deep integration with native mobile capabilities.  
On the backend, FastAPI will be used to expose RESTful endpoints responsible for game state management, trivia delivery, user progression, and leaderboard updates. FastAPI is selected for its low-latency performance, strong typing, and built-in API documentation, all of which are valuable for a real-time, API-driven game. On the client side, SwiftUI will be used to build a reactive and visually consistent interface that responds directly to changes in gameplay state, such as question timing, strike accumulation, and earnings updates. 
### THIRD PARTY SERVICES 
The Mapbox Maps SDK for iOS will serve as the core mapping and visualization library, enabling animated virtual journeys that progress in tandem with gameplay. Mapbox is chosen for its performance, customization options, and suitability for interactive, non-navigation-focused applications.  
To source trivia content, Trivia Taxi will leverage external trivia APIs to retrieve question sets dynamically during gameplay. These APIs provide structured trivia questions and metadata and can be selected based on desired scale, cost, and feature requirements:  
Open Trivia Database: A free, user-contributed trivia API returning questions across multiple categories and difficulty levels. It does not require an API key, supports session tokens to avoid duplicates, and returns results in simple JSON format. 
Pros: Zero cost, easy to integrate, no authentication requirements, and supports filtering by category and difficulty. 
Cons: Limited to 50 questions per request, smaller database size relative to premium services, and question quality and coverage can vary since content is user-generated. 
The Trivia API (the-trivia-api.com): A more professionally curated database offering over 10,000 vetted questions, category filtering, and structured metadata. 
Pros: Larger question pool than many free APIs, professional curation and structured categories, modern endpoints with customizable difficulty and tags. 
Cons: May require a subscription for full access or advanced features, and usage could incur cost depending on the plan. 
User authentication and account management will be handled through Firebase Authentication to ensure secure and reliable login flows. Cloud infrastructure and data storage will be hosted on a platform such as AWS or Google Cloud, enabling reliable performance, logging, analytics, and future expansion into additional features such as personalized question caching, category weighting algorithms, or AI-generated hints. AI-powered hints will use the OpenAI API to generate contextual, non-spoiler clues for each trivia question. 
## System Architecture 
### APPLICATION TYPE 
Trivia Taxi is a native iOS mobile app (iOS only) built in Swift + SwiftUI, backed by a Python FastAPI service. The app is the main “game client” that handles the UI, animations, map journey visualization (Mapbox), timers, and moment-to-moment gameplay. The backend is the single source of truth for accounts, game sessions, scoring, progression, and leaderboards. 
### FRONTEND/BACKEND SEPARATION 
iOS Client (SwiftUI + Mapbox) responsibilities 
Authentication UX (sign in, sign out, session handling) using Firebase Auth on-device. 
Game UI and state presentation: question screens, timer countdown, strikes, earnings, trip progress. 
Map visualization: renders the “virtual journey” and animates progress based on server-provided trip state (distance, checkpoints, destination). 
Local responsiveness: optimistic UI updates for button taps and transitions, then reconciles with server results. 
Basic caching: store most recent session state and question payloads in memory (and optionally local persistence later). 
Backend (FastAPI) responsibilities 
User profile storage (linked to Firebase UID), progression, stats, and ranking. 
Creates and manages “Trip Sessions” (the core unit of gameplay). 
Trivia delivery pipeline: pulls questions from the chosen trivia API, normalizes format, dedupes, and tags metadata (category, difficulty). 
Scoring + anti-cheat logic: validates answers, enforces time limits, calculates earnings, strikes, streaks, and trip progress. 
Leaderboard updates and retrieval (global, friends, weekly, etc. depending on how much time we have to implement ). 
Hint generation orchestration: calls OpenAI API for “non-spoiler” hints with guardrails and caching. 
Observability: logging, metrics, error tracking, and rate limiting. 
### COMMUNICATION PROTOCOL 
Primary pattern: REST over HTTPS 
The iOS app communicates with FastAPI using RESTful JSON endpoints over HTTPS. 
Each request includes a Firebase Auth ID token. The backend verifies the token and maps it to a user record. 
Caching and performance 
Cache frequently accessed data like leaderboards and hint outputs (Redis is a common choice). 
Cache trivia questions short-term to reduce external API calls and avoid duplicates. 
### API SKETCH 
Auth / Users 
POST /users/me 
Creates the user profile on first login (uses Firebase UID from token). 
GET /users/me 
Returns profile, stats, current rank, progression. 
PUT /users/me 
Updates display name, avatar URL, settings (if you add them). 
Trips / Game sessions 
POST /sessions 
Creates a new trivia trip session. Returns session_id, trip metadata (route length, checkpoints), initial question. 
GET /sessions/{session_id} 
Fetches current session state (progress, strikes, earnings, current question index, remaining time if needed). 
POST /sessions/{session_id}/answer 
Submits an answer for the current question. Returns correctness, updated earnings, strikes, progress, and next question (or end-of-trip result). 
POST /sessions/{session_id}/skip (optional) 
Skip with penalty (if you support it). 
POST /sessions/{session_id}/end 
Ends session early, returns final score + summary. 
Trivia + hints 
GET /sessions/{session_id}/question 
Fetches the current question payload (if you don’t return it on session creation/answer submit). 
POST /sessions/{session_id}/hint 
Generates or retrieves a cached hint. Returns a “safe” hint string and any penalty rules (if hints cost earnings/time). 
Leaderboards 
GET /leaderboards/global?timeframe=weekly 
Returns top players and the current user’s position. 
GET /leaderboards/friends?timeframe=weekly (optional) 
If you add friends later. 
GET /leaderboards/me/history 
Returns personal performance trends (optional but nice). 
Map / trip visualization 
GET /routes/{route_id} (optional) 
If you want predefined routes. Otherwise route data can be generated during POST /sessions. 
In MVP, the backend can just return a lightweight “trip model”: 
total_distance, checkpoints, progress_percent, and a polyline or simplified coordinate list for Mapbox rendering. 
## Core Functionality 
### MVP Core Features 
Virtual Journey: A Mapbox view that renders a start and end point. The taxi icon must move along proportionally to the number of correct answers 
Without this, our app does not have any distinction from any other quiz apps 
Journey Selection / Initialization: Users can start a game by selecting from a set of predefined virtual journeys. Each journey initializes a new game session with a defined route, earning potential, and strike limit. 
Without this, there is no way to start the game. 
Session State Management: Tracking earnings and strikes.  
This is needed to terminate the game if the user hits three strikes or increases their earnings if they reach the destination. 
Global Leaderboard: Ranked list of lifetime earnings 
This can show the user where they stand and motivate continued gameplay. 
Profile Set-up: Firebase authorization and creation of a user in the database  
Profiles are necessary to track lifetime statistics and create a profile to be used on the leaderboard. 
Dynamic Trivia Engine: Pull from APIs, handle parsing, and present multiple-choice options and a timer 
There must be trivia questions being presented in real-time for the game to continue 
User Flows 
New User Onboarding and Account Creation  
A new user downloads Trivia Taxi, creates an account, and completes a short onboarding flow that introduces the game mechanics, strike system, and scoring rules. After onboarding, the user remains logged in across sessions and is taken to the home screen, where they can view available journeys, their balance, and basic game information. 
Journey Gameplay and Progression 
A logged-in user clicks a button on the home page to go to the journey selection screen. They select one of their unlocked virtual journeys and begin gameplay. As the journey progresses, trivia questions appear at regular intervals, increasing in difficulty and value. The user earns virtual cash for correct answers and receives strikes for incorrect ones. The journey ends either upon reaching the destination or after three strikes, at which point the user sees a summary of earnings and performance. 
In-Game Hint Usage  
During an active journey, the user encounters a challenging question and chooses to use a limited “shout-out” hint. The request is sent to the backend, which generates a contextual, non-spoiler hint using an AI service. The hint is displayed immediately, and gameplay resumes without interrupting the flow of the journey. 

