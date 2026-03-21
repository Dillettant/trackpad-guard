# TrackpadGuard

Automatically disables your Mac's trackpad while you're typing. No more accidental cursor jumps from brushing the trackpad mid-keystroke.

## How it works

TrackpadGuard uses macOS `CGEventTap` to:
1. Monitor keyboard events (listen-only)
2. Suppress trackpad events (movement, scroll, clicks) for a short window after each keystroke

When you stop typing, the trackpad re-enables after the timeout (default: 400ms).

## Requirements

- macOS 13+
- **Accessibility permission** — the app will prompt you on first run. Grant access in:
  System Settings → Privacy & Security → Accessibility

## Build & Install

```bash
swift build -c release
# Binary is at .build/release/trackpad-guard

# Optional: copy to PATH
cp .build/release/trackpad-guard /usr/local/bin/
```

## Usage

```bash
# Run with defaults (400ms timeout)
trackpad-guard

# Custom timeout
trackpad-guard --timeout 0.5

# Only suppress movement, allow clicks
trackpad-guard --no-clicks

# Debug mode
trackpad-guard --verbose
```

### Options

| Flag | Description | Default |
|------|-------------|---------|
| `-t`, `--timeout` | Seconds to suppress trackpad after last keystroke | `0.4` |
| `--no-clicks` | Only suppress movement/scroll, allow clicks | off |
| `-v`, `--verbose` | Print debug output | off |

## Run at Login

Create a Launch Agent to start automatically:

```bash
cat > ~/Library/LaunchAgents/com.trackpadguard.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.trackpadguard</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/trackpad-guard</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/com.trackpadguard.plist
```

## License

MIT
