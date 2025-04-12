# Contributing to VimGolf Plugin

Thank you for your interest in contributing to the VimGolf Plugin! This document provides guidelines and instructions for contributing.

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork to your local machine
3. Create a new branch for your feature or bugfix
4. Make your changes
5. Test your changes
6. Submit a pull request

## Development Setup

1. Clone the repository:
```bash
git clone https://github.com/username/vimgolf.git
cd vimgolf
```

2. Link the plugin to your Vim/Neovim:
```bash
# For Vim
ln -s "$(pwd)" ~/.vim/pack/plugins/start/vimgolf

# For Neovim
ln -s "$(pwd)" ~/.config/nvim/pack/plugins/start/vimgolf
```

## Plugin Structure

- `plugin/vimgolf.vim`: Main plugin file with command definitions
- `autoload/vimgolf.vim`: Core functionality that is lazy-loaded
- `doc/vimgolf.txt`: Documentation in Vim help format
- `samples/`: Sample challenge files

## Adding New Features

If you'd like to add a new feature:

1. Check if there's an existing issue for your feature idea
2. If not, open a new issue to discuss the feature
3. Implement the feature in a new branch
4. Add tests if applicable
5. Update documentation
6. Submit a pull request

## Bug Fixes

If you find a bug:

1. Check if there's an existing issue for the bug
2. If not, open a new issue with steps to reproduce
3. Fix the bug in a new branch
4. Add a test that reproduces the bug if applicable
5. Submit a pull request

## Coding Standards

- Follow Vim script best practices
- Use consistent indentation (2 spaces)
- Document functions with comments
- Keep lines under 80 characters when possible
- Use descriptive variable and function names

## Testing

Before submitting a pull request, test your changes:

1. Ensure the plugin loads without errors
2. Test all affected commands and functionality
3. Check that documentation is up-to-date

## Pull Request Process

1. Update the README.md with details of changes if applicable
2. Update the documentation in doc/vimgolf.txt
3. The PR should work in both Vim and Neovim
4. Include a descriptive title and detailed description

## Code of Conduct

Please be respectful and considerate of others when contributing. We welcome contributors of all experience levels and backgrounds.

## License

By contributing to this project, you agree that your contributions will be licensed under the project's MIT License. 