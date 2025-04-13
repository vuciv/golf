# VimGolf Plugin

A Vim plugin that lets you play VimGolf challenges directly inside your editor.

## What is VimGolf?

VimGolf is a game where players compete to solve text editing challenges in the fewest keystrokes possible. This plugin brings VimGolf challenges directly to your Vim editor, allowing you to practice and improve your Vim skills offline.

## Features

- Load daily challenges
- Track keystrokes as you edit
- Verify your solution against the target text
- Automatic success detection as you type
- Side-by-side comparison of your work and the target
- Score your performance (Eagle, Birdie, Par, etc.)
- Save your results locally
- Share your achievements

## Installation

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'username/vimgolf'
```

### Using [Vundle](https://github.com/VundleVim/Vundle.vim)

```vim
Plugin 'username/vimgolf'
```

### Manual Installation

```bash
git clone https://github.com/username/vimgolf.git ~/.vim/pack/plugins/start/vimgolf
```

## Usage

1. Start today's challenge:
```vim
:VimGolfToday
```

2. Edit the text using Vim to transform it into the target text. The plugin automatically verifies your solution as you type and will notify you immediately when you've completed the challenge!

3. If you want to see what the target text should look like:
```vim
:VimGolfShowTarget
```
This will open a vertical split showing the target text side-by-side with your working buffer. The windows are synchronized for scrolling, making it easy to compare your progress with the goal.

4. If needed, manually verify your solution:
```vim
:VimGolfVerify
```
This is typically unnecessary since verification happens automatically, but you can use this command to force a verification check.

5. When your solution matches the target, the buffer will be highlighted with a success color, and you'll see your score.

6. Share your results:
```vim
:VimGolfShareSummary
```

## Commands

| Command | Description |
|---------|-------------|
| `:VimGolfToday` | Load today's VimGolf challenge |
| `:VimGolfVerify` | Verify your solution against the target text |
| `:VimGolfShowTarget` | Show the target text in a side-by-side split window for comparison |
| `:VimGolfShareSummary` | Copy a shareable summary to the clipboard |

## Scoring

Scores are calculated based on the number of keystrokes compared to the par:

- **Eagle**: ≤ par - 3  🦅
- **Birdie**: ≤ par - 1  🐦
- **Par**: = par  ⛳
- **Bogey**: par + 1 or 2  😕
- **Double Bogey**: ≥ par + 3  😖

## Configuration

```vim
" Default configuration
let g:vimgolf_data_dir = expand('~/.vimgolf')
let g:vimgolf_challenges_dir = g:vimgolf_data_dir . '/challenges'
```

## How It Works

1. **Challenge Loading**: The plugin loads challenges from a local directory. In this MVP, it generates a sample challenge for the current date.

2. **Keystroke Tracking**: Every keystroke you make in the VimGolf buffer is tracked, including mode changes and navigation.

3. **Auto-Verification**: After each edit, the plugin automatically compares your buffer with the target text. When they match, it immediately shows your success!

4. **Scoring**: Your performance is scored based on the number of keystrokes compared to the par.

5. **Results**: Results are saved locally and can be shared with others.

## Project Status

This is an early version of the VimGolf plugin. Future enhancements may include:

- Connection to official VimGolf API for challenge retrieval
- More accurate keystroke tracking
- Replay functionality
- Leaderboards
- Challenge sharing

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. 