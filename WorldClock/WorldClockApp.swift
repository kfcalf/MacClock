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
    }
}

// MARK: - App Delegate for Window Configuration

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.configureMainWindow()
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
    }
}
