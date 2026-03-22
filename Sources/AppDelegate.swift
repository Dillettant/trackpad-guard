import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var guard_: TrackpadGuard?
    private var isEnabled = true
    private var timeoutMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        startGuard(timeout: 0.4)
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "hand.raised.slash.fill", accessibilityDescription: "TrackpadGuard")
        }

        let menu = NSMenu()

        let statusMenuItem = NSMenuItem(title: "TrackpadGuard: Active", action: nil, keyEquivalent: "")
        statusMenuItem.tag = 100
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        let toggleItem = NSMenuItem(title: "Disable", action: #selector(toggleGuard), keyEquivalent: "t")
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        // Timeout submenu
        let timeoutMenu = NSMenu()
        for ms in [200, 300, 400, 500, 700, 1000] {
            let item = NSMenuItem(
                title: "\(ms)ms",
                action: #selector(changeTimeout(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.tag = ms
            if ms == 400 { item.state = .on }
            timeoutMenu.addItem(item)
        }
        timeoutMenuItem = NSMenuItem(title: "Timeout", action: nil, keyEquivalent: "")
        timeoutMenuItem.submenu = timeoutMenu
        menu.addItem(timeoutMenuItem)

        let clicksItem = NSMenuItem(title: "Suppress Clicks", action: #selector(toggleClicks(_:)), keyEquivalent: "")
        clicksItem.target = self
        clicksItem.state = .on
        menu.addItem(clicksItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func startGuard(timeout: TimeInterval, suppressClicks: Bool = true) {
        guard_?.stop()
        let config = Config(timeout: timeout, suppressClicks: suppressClicks, verbose: false)
        guard_ = TrackpadGuard(config: config)
        guard_?.start()
        isEnabled = true
        updateStatusDisplay()
    }

    @objc private func toggleGuard(_ sender: NSMenuItem) {
        if isEnabled {
            guard_?.stop()
            guard_ = nil
            isEnabled = false
            sender.title = "Enable"
        } else {
            startGuard(timeout: currentTimeout(), suppressClicks: currentSuppressClicks())
            sender.title = "Disable"
        }
        updateStatusDisplay()
    }

    @objc private func changeTimeout(_ sender: NSMenuItem) {
        let ms = sender.tag
        let timeout = TimeInterval(ms) / 1000.0

        // Update checkmarks
        if let submenu = timeoutMenuItem.submenu {
            for item in submenu.items {
                item.state = (item.tag == ms) ? .on : .off
            }
        }

        if isEnabled {
            startGuard(timeout: timeout, suppressClicks: currentSuppressClicks())
        }
    }

    @objc private func toggleClicks(_ sender: NSMenuItem) {
        let newState: NSControl.StateValue = (sender.state == .on) ? .off : .on
        sender.state = newState

        if isEnabled {
            startGuard(timeout: currentTimeout(), suppressClicks: newState == .on)
        }
    }

    @objc private func quitApp() {
        guard_?.stop()
        NSApplication.shared.terminate(nil)
    }

    private func updateStatusDisplay() {
        if let button = statusItem.button {
            let symbolName = isEnabled ? "hand.raised.slash.fill" : "hand.raised.fill"
            button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "TrackpadGuard")
        }

        if let statusItem = statusItem.menu?.item(withTag: 100) {
            statusItem.title = isEnabled ? "TrackpadGuard: Active" : "TrackpadGuard: Disabled"
        }
    }

    private func currentTimeout() -> TimeInterval {
        if let submenu = timeoutMenuItem.submenu {
            for item in submenu.items where item.state == .on {
                return TimeInterval(item.tag) / 1000.0
            }
        }
        return 0.4
    }

    private func currentSuppressClicks() -> Bool {
        if let menu = statusItem.menu {
            for item in menu.items where item.action == #selector(toggleClicks(_:)) {
                return item.state == .on
            }
        }
        return true
    }
}
