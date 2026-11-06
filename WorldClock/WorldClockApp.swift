import SwiftUI

@main
struct WorldClockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("关于 MacClock") {
                    showCustomAboutPanel()
                }
            }
        }
    }
}

/// Display about panel formatted as "v1.2.2" without build number
func showCustomAboutPanel() {
    let rawVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    let displayVersion = rawVersion.hasPrefix("v") ? rawVersion : "v\(rawVersion)"
    NSApplication.shared.orderFrontStandardAboutPanel(options: [
        .applicationVersion: displayVersion,
        .version: ""
    ])
}

// MARK: - App Delegate for Window Configuration

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.configureMainWindow()
            self.configureAboutMenuItem()
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    private func configureMainWindow() {
        guard let window = NSApplication.shared.windows.first else { return }
        
        // Make title bar transparent
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
        
        // Transparent background
        window.backgroundColor = .clear
        window.isOpaque = false
        
        // Allow the window to be moved by dragging anywhere
        window.isMovableByWindowBackground = true
        
        // Enable mouse moved events for crosshair tracking
        window.acceptsMouseMovedEvents = true
    }
    
    private func configureAboutMenuItem() {
        if let appMenu = NSApplication.shared.mainMenu?.items.first?.submenu {
            for item in appMenu.items {
                if item.action == #selector(NSApplication.orderFrontStandardAboutPanel(_:)) {
                    item.target = self
                    item.action = #selector(showAboutPanel(_:))
                }
            }
        }
    }
    
    @objc func showAboutPanel(_ sender: Any?) {
        showCustomAboutPanel()
    }
}
