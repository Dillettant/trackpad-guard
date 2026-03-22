# TrackpadGuard

Automatically disables your Mac's trackpad while you're typing. No more accidental cursor jumps from brushing the trackpad mid-keystroke.

## How it works

TrackpadGuard uses macOS `CGEventTap` to:
1. Monitor keyboard events (listen-only)
2. Suppress trackpad events (movement, scroll, clicks) for a short window after each keystroke

When you stop typing, the trackpad re-enables after the timeout (default: 400ms). Runs as a menu bar app — no dock icon.

## Install

### Homebrew

```bash
brew install --cask --no-quarantine Dillettant/tap/trackpad-guard
```

### DMG

Download the latest DMG from [Releases](https://github.com/Dillettant/trackpad-guard/releases), open it, and drag TrackpadGuard to Applications.

### Build from source

```bash
git clone https://github.com/Dillettant/trackpad-guard.git
cd trackpad-guard
./build-app.sh
cp -r build/TrackpadGuard.app /Applications/
```

## Requirements

- macOS 13+
- **Accessibility permission** — the app will prompt you on first run. Grant access in:
  System Settings → Privacy & Security → Accessibility

## Usage

Launch TrackpadGuard from Applications. It appears in the **menu bar** with a hand icon.

From the menu bar you can:
- **Toggle** guard on/off
- **Change timeout** (200ms–1000ms)
- **Toggle click suppression**
- **Quit**

## License

MIT
