import SwiftUI
import AppKit

/// Hides the Dock icon — without this, a bare Swift Package executable
/// (no .app bundle / Info.plist with LSUIElement) shows up in the Dock
/// like a regular app, which isn't what you want for a menu bar utility.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct ClaudeSessionMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var state = AppState()

    var body: some Scene {
        MenuBarExtra {
            ContentView(state: state)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: menuBarSymbol)
                Text("\(String(format: "%.1f", state.stats.freeGB))GB")
            }
        }
        .menuBarExtraStyle(.window)
    }

    private var menuBarSymbol: String {
        switch state.stats.pressure {
        case .normal: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .critical: return "xmark.octagon"
        }
    }
}
