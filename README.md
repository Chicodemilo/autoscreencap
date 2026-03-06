# autoscreencap

A lightweight macOS utility that watches for new screenshots and automatically copies them to your clipboard.

No apps to open. No extra keyboard shortcuts. Just take a screenshot and paste it wherever you need it.

## What it does

When a new screenshot lands in your watch directory:

1. **Copies it to your clipboard** — ready to paste into Slack, email, docs, whatever
2. **Plays a sound** — so you know it worked
3. **Prints clickable links** in your terminal — open the file or reveal it in Finder

## Requirements

- macOS (tested on Sonoma / Apple Silicon)
- [fswatch](https://github.com/emcrisostomo/fswatch) — `brew install fswatch`
- A terminal that supports OSC 8 hyperlinks ([iTerm2](https://iterm2.com), Ghostty, etc.)
- python3 (optional — used for URL-encoding paths, has a fallback)

## Setup

### 1. Install fswatch

```sh
brew install fswatch
```

### 2. Set your screenshot location

Point macOS screenshots to a dedicated folder:

```sh
mkdir -p ~/Desktop/ScreenCap
defaults write com.apple.screencapture location ~/Desktop/ScreenCap
killall SystemUIServer
```

### 3. Run it

```sh
chmod +x autoscreencap.sh
./autoscreencap.sh
```

Take a screenshot (`Cmd+Shift+3` or `Cmd+Shift+4`) and it'll be on your clipboard instantly.

### 4. (Optional) Auto-launch in iTerm2

To have it always running in a dedicated tab:

1. Open **iTerm2 > Settings > Profiles**
2. Create a new profile (e.g., "ScreenCap")
3. Under **General > Command**, select **Custom Shell** and enter the full path to the script
4. Open a new tab with that profile — done

## Configuration

Override defaults with environment variables:

| Variable | Default | Description |
|---|---|---|
| `SCREENCAP_DIR` | `~/Desktop/ScreenCap` | Directory to watch |
| `SCREENCAP_LOG` | `~/autoscreencap.log` | Log file path |
| `SCREENCAP_SOUND` | `Glass` | macOS sound name (see `/System/Library/Sounds/`) |
| `SCREENCAP_DEBOUNCE` | `2` | Seconds to ignore duplicate events |

Example:

```sh
SCREENCAP_DIR=~/Screenshots SCREENCAP_SOUND=Submarine ./autoscreencap.sh
```

## How it works

Uses `fswatch` to monitor the watch directory for filesystem events. When a new `.png` appears, it uses AppleScript to copy the image data directly to the clipboard (not just the file reference), then prints [OSC 8 hyperlinks](https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda) for quick access.

## License

MIT
