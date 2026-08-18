import Foundation
import AppKit

enum QuickActions {
    static func openMemoryLog() {
        let path = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/claude-sessions/memory-log.csv")
        NSWorkspace.shared.open(path)
    }

    static func openGitIdentityFolder() {
        let path = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Developer/headroom/git-identity")
        NSWorkspace.shared.open(path)
    }

    static func openConfigFile() {
        NSWorkspace.shared.open(Config.path)
    }
}

/// Sends a native notification via osascript rather than UserNotifications —
/// a bare Swift Package executable (no .app bundle / Info.plist) generally
/// can't register for UNUserNotificationCenter permissions reliably, but
/// `display notification` works regardless.
enum Notifier {
    static func send(title: String, subtitle: String, body: String, sound: String = "Basso") {
        let script = "display notification \"\(escape(body))\" with title \"\(escape(title))\" subtitle \"\(escape(subtitle))\" sound name \"\(sound)\""
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\"", with: "\\\"")
    }
}
