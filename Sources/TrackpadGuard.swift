import Cocoa
import Foundation

struct Config {
    var timeout: TimeInterval = 0.4
    var suppressClicks: Bool = true
    var verbose: Bool = false
}

class TrackpadGuard {
    private var config: Config
    private var lastKeystrokeTime: TimeInterval = 0
    fileprivate var keyboardTap: CFMachPort?
    fileprivate var trackpadTap: CFMachPort?

    init(config: Config) {
        self.config = config
    }

    /// Start monitoring. Runs event taps on the current run loop.
    /// For the app bundle, call from the main thread.
    func start() {
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

        let context = Unmanaged.passUnretained(self).toOpaque()

        guard let kbTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: keyboardMask,
            callback: TrackpadGuard.keyboardCallback,
            userInfo: context
        ) else {
            NSLog("TrackpadGuard: Failed to create keyboard event tap.")
            return
        }
        self.keyboardTap = kbTap

        guard let tpTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: trackpadMask,
            callback: TrackpadGuard.trackpadCallback,
            userInfo: context
        ) else {
            NSLog("TrackpadGuard: Failed to create trackpad event tap.")
            return
        }
        self.trackpadTap = tpTap

        let keyboardSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, kbTap, 0)
        let trackpadSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tpTap, 0)

        CFRunLoopAddSource(CFRunLoopGetMain(), keyboardSource, .commonModes)
        CFRunLoopAddSource(CFRunLoopGetMain(), trackpadSource, .commonModes)

        CGEvent.tapEnable(tap: kbTap, enable: true)
        CGEvent.tapEnable(tap: tpTap, enable: true)

        NSLog("TrackpadGuard: Active (timeout: %.1fs, suppress clicks: %@)",
              config.timeout, config.suppressClicks ? "yes" : "no")
    }

    func stop() {
        if let tap = keyboardTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
            keyboardTap = nil
        }
        if let tap = trackpadTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
            trackpadTap = nil
        }
        NSLog("TrackpadGuard: Stopped")
    }

    static func checkAccessibilityPermission(prompt: Bool = true) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    fileprivate func recordKeystroke() {
        lastKeystrokeTime = ProcessInfo.processInfo.systemUptime
    }

    fileprivate func shouldSuppressTrackpad() -> Bool {
        let now = ProcessInfo.processInfo.systemUptime
        let elapsed = now - lastKeystrokeTime
        return elapsed < config.timeout
    }

    // MARK: - CGEvent Callbacks

    private static let keyboardCallback: CGEventTapCallBack = {
        proxy, type, event, userInfo in
        guard let userInfo = userInfo else {
            return Unmanaged.passUnretained(event)
        }
        let self_ = Unmanaged<TrackpadGuard>.fromOpaque(userInfo).takeUnretainedValue()

        if type == .tapDisabledByTimeout {
            if let tap = self_.keyboardTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        self_.recordKeystroke()
        return Unmanaged.passUnretained(event)
    }

    private static let trackpadCallback: CGEventTapCallBack = {
        proxy, type, event, userInfo in
        guard let userInfo = userInfo else {
            return Unmanaged.passUnretained(event)
        }
        let self_ = Unmanaged<TrackpadGuard>.fromOpaque(userInfo).takeUnretainedValue()

        if type == .tapDisabledByTimeout {
            if let tap = self_.trackpadTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        if self_.shouldSuppressTrackpad() {
            return nil
        }

        return Unmanaged.passUnretained(event)
    }
}
