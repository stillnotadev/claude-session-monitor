import Foundation
import AppKit

struct RunningProcess: Identifiable {
    var id: Int32 { pid }
    let pid: Int32
    let rssGB: Double
}

/// Detects processes literally named `claude` (the CLI binary). This can't
/// see sessions opened through the Claude desktop app's Code tab — there's
/// no public API for that — only ones started via the CLI in a terminal.
enum ClaudeProcess {
    static func listRunning() -> [RunningProcess] {
        let output = SystemStatsCollector.run("/bin/ps", ["-Ao", "pid,rss,comm"])
        var results: [RunningProcess] = []
        for line in output.split(separator: "\n").dropFirst() {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 3 else { continue }
            let comm = parts[2...].joined(separator: " ")
            guard comm == "claude" || comm.hasSuffix("/claude") else { continue }
            guard let pid = Int32(parts[0]), let rssKB = Double(parts[1]) else { continue }
            results.append(RunningProcess(pid: pid, rssGB: rssKB / 1024 / 1024))
        }
        return results
    }

    static func kill(pid: Int32) {
        _ = SystemStatsCollector.run("/bin/kill", ["-9", String(pid)])
    }
}

enum SessionLauncher {

    /// Opens a Claude Code session directly in the Claude desktop app via
    /// its documented deep link, instead of a bare Terminal window.
    /// https://support.claude.com/en/articles/14729294
    static func openLocal(folder: String) {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        let encoded = folder.addingPercentEncoding(withAllowedCharacters: allowed) ?? folder
        guard let url = URL(string: "claude://code/new?folder=\(encoded)") else { return }
        NSWorkspace.shared.open(url)
    }

    /// No documented desktop deep link exists for `claude --cloud` yet, so
    /// this still opens a Terminal window. Warns first if there are
    /// unpushed commits, since cloud sessions only see what's on GitHub.
    static func openCloud(folder: String, description: String) {
        let script = """
        #!/bin/bash
        cd "\(folder)" || exit 1
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
          git fetch --quiet 2>/dev/null || true
          unpushed="$(git log @{u}.. --oneline 2>/dev/null || true)"
          if [ -n "$unpushed" ]; then
            echo "Warning: you have commits not pushed to GitHub."
            echo "Cloud sessions only see what's on the remote — push first if you want this work included."
            echo
          fi
        else
          echo "Warning: this folder isn't a git repo. Cloud sessions require a pushed GitHub remote."
          echo
        fi
        exec claude --cloud \(shellQuote(description))
        """

        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("claude-launch-\(UUID().uuidString).sh")
        try? script.write(to: tmpURL, atomically: true, encoding: .utf8)
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tmpURL.path)

        let appleScript = "tell application \"Terminal\" to do script \"\(tmpURL.path)\""
        let osa = Process()
        osa.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        osa.arguments = ["-e", appleScript]
        try? osa.run()
    }

    private static func shellQuote(_ s: String) -> String {
        "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

enum QuickActions {
    static func openMemoryLog() {
        let path = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/claude-sessions/memory-log.csv")
        NSWorkspace.shared.open(path)
    }

    static func openGitIdentityFolder() {
        let path = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Developer/claude-session-monitor/git-identity")
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
