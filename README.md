# golf.vim



https://github.com/user-attachments/assets/5acb129d-fcca-46ce-9ea8-f9ae6a03159e



golf.vim is a Vim plugin that brings a challenge-based keystroke game to your editor. Inspired by the idea of code golfing, each challenge tasks you with transforming a starting text into a target text by typing as few keystrokes as possible. Your performance is dynamically tracked and scored in real time, and upon completion, you get a detailed summary along with a leaderboard.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Submitting Challenges](#submitting-challenges)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Dynamic Challenges:**  
  - Fetch daily challenges from an external API.
  - Each challenge includes a starting text, target text, and a par value representing the optimal number of keystrokes.
  - Community-contributed challenges with quality assurance through review process.

- **Keystroke Tracking:**  
  - Tracks every keystroke (both normal and insert modes).
  - Calculates your score based on how many keystrokes you use relative to the par.

- **Auto-Verification:**  
  - Automatically compares your current buffer content against the target text.
  - Displays a success message as soon as your solution matches the target, with detailed stats.

- **Visual Feedback & Leaderboard:**  
  - Opens a dedicated success screen with stylish formatting, syntax highlighting, and a leaderboard showing top scores.
  - Displays a split window with the target text for easy reference during the challenge.

## Installation

### Using a Plugin Manager

If you use [vim-plug](https://github.com/junegunn/vim-plug), add the following lines to your `~/.vimrc` or `init.vim`:

```vim
Plug 'vuciv/golf'
```

Then run the command:
```
:PlugInstall
```

### Manual Installation
Copy the golf.vim file into your Vim runtime path (typically ~/.vim/plugin/).

## Usage

### Starting a Challenge

**Play Today's Challenge:**
In Vim, run:
```
:GolfToday
```

This command:
- Saves your current buffer.
- Fetches the daily challenge from the API.
- Opens a new buffer with the challenge text and a side-by-side split showing the target text.
- Begins tracking your keystrokes.

**Play a Random Challenge by Difficulty:**
In Vim, run:
```
:Golf <difficulty>
```
Where `<difficulty>` is one of `easy`, `medium`, or `hard` (case-insensitive).

Examples:
```
:Golf easy
:Golf medium
:Golf hard
```
This command fetches a random challenge matching the specified difficulty.

**Play a Random Challenge (Any Difficulty):**
In Vim, run:
```
:Golf
```
This command fetches a completely random challenge, regardless of difficulty.

**Play a Random Challenge by Tag:**
In Vim, run:
```
:Golf tag <tag-name>
```
Example:
```
:Golf tag regex
:Golf tag "multi line"
```
This command fetches a random challenge that includes the specified tag.

**Play a Challenge from a Specific Date:**
In Vim, run:
```
:Golf date <YYYY-MM-DD>
```
Example:
```
:Golf date 2023-10-27
```
This command fetches the daily challenge designated for the specified date.

**Keystroke Tracking & Auto-Verification:**
Every keystroke is recorded. The plugin continuously compares your edited buffer against the target text. When your solution matches perfectly, a success screen is shown with statistics including the stroke count, time taken, and your score relative to par.

**Exiting the Challenge:**
After reviewing the success and leaderboard screen, press any key to exit, and the plugin will return you to your original file.

## Submitting Challenges

You can contribute new challenges to the Golf community through our web interface. Visit:
```
https://golf-d5bs.onrender.com/submit.html
```

When submitting a challenge:

1. **Challenge Components:**
   - Title: A descriptive name for your challenge
   - Description: Clear instructions about what needs to be done
   - Starting Text: The initial text that players will see
   - Target Text: The text that players need to achieve
   - Par: The expected number of keystrokes for an optimal solution
   - Difficulty: Easy, Medium, or Hard
   - Tags: Relevant categories for your challenge

2. **Review Process:**
   All submitted challenges go through a review process to ensure quality and appropriateness. This includes:
   - Verification of challenge solvability
   - Checking for appropriate content
   - Validating the par score
   - Reviewing tags and difficulty rating

3. **Publication:**
   - Challenges are only made public after approval
   - You'll receive confirmation when your challenge is submitted
   - The review process may take some time

## Contributing

Contributions are welcome! To contribute:

**Fork the Repository:**
Create your own copy to work on your changes.

**Create a Feature Branch:**
Use a descriptive branch name, for example, `feature/add-new-mapping`.

**Commit Your Changes:**
Follow the existing code style and include clear commit messages.

**Submit a Pull Request:**
Open a PR with a detailed explanation of your changes and any related issues.

Please include tests or documentation updates for any new features or bug fixes.

## License

This project is licensed under the MIT License. Feel free to use, modify, and distribute the plugin according to the terms specified in the license.

Enjoy the challenge, fine-tune your keystrokes, and happy golfing!

---
Repository: [https://github.com/vuciv/golf](https://github.com/vuciv/golf)
