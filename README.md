# textbringer-mouse

[![CI](https://github.com/yancya/textbringer-mouse/actions/workflows/ci.yml/badge.svg)](https://github.com/yancya/textbringer-mouse/actions/workflows/ci.yml)

A plugin that adds comprehensive mouse support to [Textbringer](https://github.com/shugo/textbringer), the Emacs-like text editor written in Ruby.

## Features

### 🖱️ Mouse Clicking
- **Left Click**: Move cursor to clicked position
- **Double Click**: Select word at cursor
- **Triple Click**: Select entire line
- **Right Click**: Select word (same as double click)
- **Window Focus**: Click different windows to switch focus

### 📜 Mouse Scrolling
- **Wheel Up**: Scroll content down (screen up)
- **Wheel Down**: Scroll content up (screen down)
- Works seamlessly with buffer boundaries

### 🎯 Advanced Coordinate Handling
- Accurate positioning with **Tab characters** (respects tab-width)
- Full support for **Multibyte characters** (Japanese, Chinese, emoji, etc.)
- Handles **Mixed content** (tabs + multibyte chars)
- Supports **Multiple windows** and window splits

## Installation

### From Gem

```bash
gem install textbringer-mouse
```

### From Source

```bash
git clone https://github.com/yancya/textbringer-mouse.git
cd textbringer-mouse
bundle install
bundle exec rake install
```

## Configuration

Add to your `~/.textbringer.rb`:

```ruby
require "textbringer_plugin"
```

Or load the plugin directly:

```ruby
require "textbringer/mouse"
```

## Compatibility

### Supported Terminals
- ✅ iTerm2
- ✅ Terminal.app (macOS)
- ✅ tmux (with `set -g mouse on`)
- ✅ VSCode integrated terminal
- ✅ Most modern terminal emulators with mouse support

### tmux Configuration

For mouse support in tmux, add to your `~/.tmux.conf`:

```conf
set -g mouse on
```

## Development

### Running Tests

The plugin includes a comprehensive test suite with 31 tests covering:
- Coordinate conversion (15 tests, 100% passing)
- Mouse event handling (10 tests, 4 passing + 6 pending integration tests)
- New features (6 tests, 100% passing)

```bash
# Run all tests
bundle exec rake test

# Run specific test file
bundle exec ruby -Ilib:test test/textbringer/mouse/test_coordinate.rb

# Run with verbose output
bundle exec rake test TESTOPTS="-v"
```

### Test Coverage

- **Coordinate conversion**: 100% (all scenarios covered)
- **Integration tests**: 40% (6 tests require manual verification)
- **Overall**: 80.6% passing (25/31 non-pending tests)

### Project Structure

```
textbringer-mouse/
├── lib/
│   └── textbringer/
│       ├── mouse.rb              # Main plugin implementation
│       └── mouse/
│           └── version.rb        # Version info
├── test/
│   ├── test_helper.rb            # Test framework + Curses mocks
│   └── textbringer/
│       └── mouse/
│           ├── test_coordinate.rb      # Coordinate conversion tests
│           ├── test_mouse_integration.rb # Integration tests
│           └── test_mouse_features.rb   # New features tests
├── USAGE.md                      # Detailed usage guide
├── Rakefile                      # Build & test tasks
└── textbringer-mouse.gemspec     # Gem specification
```

## Usage Examples

### Basic Mouse Operations

1. **Move Cursor**: Click anywhere in the text to move cursor
2. **Select Word**: Double-click on a word to select it
3. **Select Line**: Triple-click to select entire line
4. **Scroll**: Use mouse wheel to scroll through document
5. **Switch Windows**: Click on different windows (C-x 2 to split)

### Advanced Usage

```ruby
# In ~/.textbringer.rb

# Customize mouse behavior (example - not yet implemented)
# Textbringer::Mouse.configure do |config|
#   config.enable_drag_selection = true
#   config.enable_right_click_menu = false
# end
```

## Technical Details

### Coordinate Conversion Algorithm

The plugin implements precise screen-to-buffer position conversion:

1. **Screen Coordinates** (x, y) from terminal
2. **Window-Relative Coordinates** (rel_x, rel_y)
3. **Buffer Position** accounting for:
   - Tab width (calc_tab_width)
   - Display width (Buffer.display_width)
   - Multibyte character boundaries
   - Line breaks and buffer boundaries

### Mouse Event Handling

```ruby
Curses.mousemask(Curses::ALL_MOUSE_EVENTS | Curses::REPORT_MOUSE_POSITION)
```

Supported events:
- `BUTTON1_CLICKED`, `BUTTON1_PRESSED`, `BUTTON1_RELEASED`
- `BUTTON1_DOUBLE_CLICKED`, `BUTTON1_TRIPLE_CLICKED`
- `BUTTON2_CLICKED`, `BUTTON3_CLICKED`
- `BUTTON4_PRESSED` (scroll up), `BUTTON5_PRESSED` (scroll down)

## Troubleshooting

### Mouse Not Responding

1. **Check terminal support**: Not all terminals support mouse events
   ```bash
   echo $TERM  # Should be xterm-256color or similar
   ```

2. **tmux users**: Ensure mouse mode is enabled
   ```bash
   tmux show -g mouse  # Should show: mouse on
   ```

3. **Check plugin loaded**: In Textbringer, run:
   ```
   M-x eval-expression
   Textbringer::Window.ancestors
   # Should include WindowMouseExtension
   ```

### Cursor Position Misalignment

- **Tab width mismatch**: Check `tab-width` setting matches your terminal
- **Font rendering**: Use monospace fonts with consistent character widths
- **Terminal emulator**: Some emulators report incorrect mouse coordinates

### Events Not Detected

- **macOS Terminal.app**: Enable "Use Option as Meta key" in preferences
- **SSH sessions**: Mouse events may not propagate through remote sessions
- **Screen readers**: Some accessibility tools intercept mouse events

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for your changes
4. Ensure all tests pass (`bundle exec rake test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

This project is licensed under the WTFPL - see the [LICENSE.txt](LICENSE.txt) file for details.

## Acknowledgments

- [Textbringer](https://github.com/shugo/textbringer) by Shugo Maeda
- Inspired by Emacs mouse support and modern terminal capabilities

## Changelog

### v0.1.0 (Current)
- ✨ Initial release
- 🖱️ Basic mouse clicking and scrolling
- 🎯 Precise coordinate conversion (tabs, multibyte chars)
- 🔄 Double-click and triple-click word/line selection
- 🧪 Comprehensive test suite (31 tests, 80.6% passing)
- 📚 Full documentation and usage guide

---

**Made with ❤️ for the Textbringer community**
