# Golf.vim Server

This is the server component for the golf.vim Vim plugin. It provides API endpoints for challenges and solutions, manages the database, and handles submission processing.

## Features

- RESTful API for challenges and solutions
- MongoDB database storage
- User score tracking and leaderboards
- Daily challenge rotation
- Challenge difficulty ratings

## Automatic Cleanup

The server automatically performs the following maintenance tasks on startup:

- **Invalid Solution Cleanup**: Removes any solutions with fewer than 5 keystrokes, which are likely to be erroneous or fraudulent data.

## API Endpoints

### Challenges

- `GET /v1/challenges/all` - List all approved challenges
- `GET /v1/challenges/daily` - Get today's challenge
- `GET /v1/challenges/random` - Get a random challenge (with optional difficulty/tag filter)
- `GET /v1/challenges/date/:date` - Get challenge for specific date
- `GET /v1/challenges/:id` - Get specific challenge by ID
- `POST /v1/challenges` - Submit a new challenge (requires approval)

### Solutions

- `POST /v1/solutions` - Submit a solution
- `GET /v1/solutions/leaderboard/:challenge_id` - Get leaderboard for a challenge

## Development

### Setup

1. Clone the repository
2. Run `npm install`
3. Create a `.env` file with `MONGODB_URI` connection string
4. Run `npm start` to start the server

### Environment Variables

- `PORT`: Server port (default: 3000)
- `MONGODB_URI`: MongoDB connection string

## License

MIT
