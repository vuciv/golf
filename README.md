# Golf

A Vim plugin and server implementation for practicing and improving your Vim skills through coding challenges.

## Project Structure

This repository consists of two main components:

- `golfPlugin/`: A Vim plugin for interacting with Golf challenges directly from your editor
- `server/`: A Node.js server implementation for hosting and managing Golf challenges

## What is Golf?

Golf is a game where you compete to solve text manipulation challenges in the fewest keystrokes possible using Vim. Each challenge presents you with a starting text and a target text - your goal is to transform the start text into the target text using as few keystrokes as possible.

## Getting Started

### Prerequisites

- Vim 8.0 or higher
- Node.js (v14 or higher) for running the server
- MongoDB (v4.4 or higher) for the server

### Plugin Installation

1. Clone this repository:
```bash
git clone https://github.com/vuciv/golf.git
```

2. Copy or symlink the plugin files to your Vim plugin directory:
```bash
cp -r golfPlugin/* ~/.vim/plugin/
# or for Neovim
cp -r golfPlugin/* ~/.config/nvim/plugin/
```

### Server Setup

1. Navigate to the server directory:
```bash
cd server
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file with your configuration:
```env
PORT=3000
MONGODB_URI=mongodb://localhost/golf
NODE_ENV=development
```

4. Start the server:
```bash
npm run dev  # for development
npm start    # for production
```

## Usage

[Coming soon - Add usage instructions for both the plugin and server]

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

MIT 