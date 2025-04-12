# VimGolf Server

API server for VimGolf challenges, providing endpoints for daily challenges, challenge management, and solution submissions.

## Features

- Daily challenges with automatic rotation
- Challenge creation and retrieval
- Solution submission and tracking
- Leaderboard functionality
- MongoDB integration for data persistence

## Prerequisites

- Node.js (v14 or higher)
- MongoDB (v4.4 or higher)
- npm or yarn

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/vimgolf-server.git
cd vimgolf-server
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file in the root directory with your configuration:
```env
PORT=3000
MONGODB_URI=mongodb://localhost/vimgolf
NODE_ENV=development
```

4. Start MongoDB if not already running:
```bash
mongod
```

5. Start the server:
```bash
npm run dev  # for development
npm start    # for production
```

## API Endpoints

### Challenges

- `GET /v1/challenges/daily` - Get today's challenge
- `GET /v1/challenges/:id` - Get a specific challenge
- `POST /v1/challenges` - Create a new challenge

### Solutions

- `POST /v1/solutions` - Submit a solution
- `GET /v1/solutions/leaderboard/:challenge_id` - Get challenge leaderboard

## Development

Run the development server with hot reload:
```bash
npm run dev
```

Run tests:
```bash
npm test
```

## Challenge Format

Challenges should be submitted in the following format:

```json
{
  "title": "Challenge Title",
  "start_text": "Initial text content",
  "end_text": "Target text content",
  "par": 20,
  "difficulty": "medium",
  "description": "Challenge description"
}
```

## Solution Format

Solutions should be submitted in the following format:

```json
{
  "challenge_id": "challenge_object_id",
  "keystrokes": 25,
  "keylog": [
    {
      "key": "i",
      "timestamp": "2023-12-20T10:30:00Z"
    }
  ],
  "time_taken": 60,
  "score": -1,
  "user_id": "user_identifier"
}
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT 