# Discord Scribble Task Organizer

This project collects unstructured messages from specific Discord channels ("Scribble" channels), uses Gemini AI to organize them into actionable tasks, and posts a summary to a designated channel.

## Features
- **Serverless**: Runs entirely on GitHub Actions (Free tier friendly).
- **AI Powered**: Uses Gemini 2.0 Flash to intelligently parse context.
- **Automated**: Runs on a schedule or manually.

## Setup

1. **Prerequisites**
   - A Discord Bot Token (from Discord Developer Portal).
   - A Gemini API Key (from Google AI Studio).
   - Channel IDs for:
     - Source Channel 1 (Scribble A)
     - Source Channel 2 (Scribble B)
     - Target Channel (Where tasks appear)

2. **GitHub Repository**
   - Push this code to a new GitHub repository.

3. **Secrets**
   Go to `Settings > Secrets and variables > Actions` in your repo and add:
   - `DISCORD_BOT_TOKEN`: Your bot token.
   - `GEMINI_API_KEY`: Your Gemini API key.
   - `SOURCE_CHANNEL_IDS`: Comma-separated IDs (e.g. `123456789,987654321`).
   - `TARGET_CHANNEL_ID`: The ID of the channel to post results to.

## Note on Buttons & Interactvity
This system uses GitHub Actions, which is a batch processing system. It cannot "listen" for button clicks in real-time.
- The "List" functionality is fully implemented.
- To implement "Button to Create Forum Thread", you would need a simplified web server (webhook) hosted on a service like Vercel, Render, or AWS Lambda to receive the interaction events from Discord.
