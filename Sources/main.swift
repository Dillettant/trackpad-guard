import Cocoa
import Foundation

// MARK: - Configuration

struct Config {
    /// How long (in seconds) to suppress trackpad after the last keystroke
    var timeout: TimeInterval = 0.4

    /// Whether to suppress trackpad clicks in addition to movement
    var suppressClicks: Bool = true

    /// Whether to show status in the terminal
    var verbose: Bool = false
}

// MARK: - TrackpadGuard

class TrackpadGuard {
    private var config: Config
    private var lastKeystrokeTime: TimeInterval = 0
    private var isRunning = false
    private var keyboardTap: CFMachPort?
    private var trackpadTap: CFMachPort?

    init(config: Config) {
        self.config = config
    }

    func start() {
        guard checkAccessibilityPermission() else {
            printError(
                "Accessibility permission required.\n"
                + "Grant access in: System Settings → Privacy & Security → Accessibility\n"
                + "Then re-run trackpad-guard."
            )
            exit(1)
        }

        let keyboardMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)

        var trackpadMask: CGEventMask = (1 << CGEventType.mouseMoved.rawValue)
            | (1 << CGEventType.scrollWheel.rawValue)
            | (1 << CGEventType.otherMouseDragged.rawValue)

        if config.suppressClicks {
            trackpadMask |= (1 << CGEventType.leftMouseDown.rawValue)
                | (1 << CGEventType.leftMouseUp.rawValue)
                | (1 << CGEventType.leftMouseDragged.rawValue)
                | (1 << CGEventType.rightMouseDown.rawValue)
                | (1 << CGEventType.rightMouseUp.rawValue)
                | (1 << CGEventType.rightMouseDragged.rawValue)
        }

        // Keyboard tap: listen-only, records timestamp
        let keyboardContext = Unmanaged.passUnretained(self).toOpaque()
        guard let kbTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: keyboardMask,
            callback: TrackpadGuard.keyboardCallback,
            userInfo: keyboardContext
        ) else {
            printError("Failed to create keyboard event tap. Check permissions.")
            exit(1)
        }
        self.keyboardTap = kbTap

        // Trackpad tap: active, can suppress events
        let trackpadContext = Unmanaged.passUnretained(self).toOpaque()
        guard let tpTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: trackpadMask,
            callback: TrackpadGuard.trackpadCallback,
            userInfo: trackpadContext
        ) else {
            printError("Failed to create trackpad event tap. Check permissions.")
            exit(1)
        }
        self.trackpadTap = tpTap

        let keyboardSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, kbTap, 0)
        let trackpadSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tpTap, 0)

        CFRunLoopAddSource(CFRunLoopGetCurrent(), keyboardSource, .commonModes)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), trackpadSource, .commonModes)

        CGEvent.tapEnable(tap: kbTap, enable: true)
        CGEvent.tapEnable(tap: tpTap, enable: true)

        isRunning = true
        print("TrackpadGuard is active (timeout: \(config.timeout)s, suppress clicks: \(config.suppressClicks))")
        print("Press Ctrl+C to quit.")

        // Handle Ctrl+C gracefully
        signal(SIGINT) { _ in
            print("\nTrackpadGuard stopped.")
            exit(0)
        }

        CFRunLoopRun()
    }

    private func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private func recordKeystroke() {
        lastKeystrokeTime = ProcessInfo.processInfo.systemUptime
        if config.verbose {
            print("⌨  keystroke recorded")
        }
    }

    private func shouldSuppressTrackpad() -> Bool {
        let now = ProcessInfo.processInfo.systemUptime
        let elapsed = now - lastKeystrokeTime
        let suppress = elapsed < config.timeout
        if suppress && config.verbose {
            print("🚫 trackpad suppressed (\(String(format: "%.0f", elapsed * 1000))ms since last key)")
        }
        return suppress
    }

    // MARK: - CGEvent Callbacks

    private static let keyboardCallback: CGEventTapCallBack = {
        proxy, type, event, userInfo in
        guard let userInfo = userInfo else {
            return Unmanaged.passUnretained(event)
        }
        let guard_ = Unmanaged<TrackpadGuard>.fromOpaque(userInfo).takeUnretainedValue()

        if type == .tapDisabledByTimeout {
            if let tap = guard_.keyboardTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard_.recordKeystroke()
        return Unmanaged.passUnretained(event)
    }

    private static let trackpadCallback: CGEventTapCallBack = {
        proxy, type, event, userInfo in
        guard let userInfo = userInfo else {
            return Unmanaged.passUnretained(event)
        }
        let guard_ = Unmanaged<TrackpadGuard>.fromOpaque(userInfo).takeUnretainedValue()

        if type == .tapDisabledByTimeout {
            if let tap = guard_.trackpadTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        if guard_.shouldSuppressTrackpad() {
            return nil  // Suppress the event
        }

        return Unmanaged.passUnretained(event)
    }
}

// MARK: - CLI

func printUsage() {
    print("""
    TrackpadGuard - Disable trackpad while typing on macOS

    USAGE:
      trackpad-guard [OPTIONS]

    OPTIONS:
      -t, --timeout <seconds>   Suppression timeout after last keystroke (default: 0.4)
      --no-clicks               Only suppress movement, allow clicks through
      -v, --verbose             Show debug output
      -h, --help                Show this help message
    """)
}

func printError(_ message: String) {
    FileHandle.standardError.write(Data("Error: \(message)\n".utf8))
}

// Parse arguments
var config = Config()
var args = CommandLine.arguments.dropFirst()
var argsIterator = args.makeIterator()

while let arg = argsIterator.next() {
    switch arg {
    case "-t", "--timeout":
        guard let value = argsIterator.next(), let timeout = TimeInterval(value) else {
            printError("--timeout requires a numeric value")
            exit(1)
        }
        config.timeout = timeout
    case "--no-clicks":
        config.suppressClicks = false
    case "-v", "--verbose":
        config.verbose = true
    case "-h", "--help":
        printUsage()
        exit(0)
    default:
        printError("Unknown option: \(arg)")
        printUsage()
        exit(1)
    }
}

let guard_ = TrackpadGuard(config: config)
guard_.start()
