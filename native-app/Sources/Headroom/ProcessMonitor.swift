import Foundation

struct TopProcess: Identifiable {
    var id: Int32 { pid }
    let pid: Int32
    let name: String
    let rssGB: Double
}

/// Lists the current user's own processes sorted by memory use. Scoped to
/// `-u <you>` rather than all processes system-wide, which naturally
/// excludes root-owned system daemons (WindowServer, kernel_task, etc.) —
/// those run as a different user, so this can't accidentally target them.
enum ProcessMonitor {
    static func topMemoryConsumers(limit: Int = 6) -> [TopProcess] {
        let user = NSUserName()
        let output = SystemStatsCollector.run("/bin/ps", ["-u", user, "-o", "pid,rss,comm"])
        let myPID = ProcessInfo.processInfo.processIdentifier

        var results: [TopProcess] = []
        for line in output.split(separator: "\n").dropFirst() {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 3 else { continue }
            guard let pid = Int32(parts[0]), let rssKB = Double(parts[1]) else { continue }
            if pid == myPID { continue }

            let fullPath = parts[2...].joined(separator: " ")
            let name = (fullPath as NSString).lastPathComponent
            results.append(TopProcess(pid: pid, name: name, rssGB: rssKB / 1024 / 1024))
        }

        return Array(results.sorted { $0.rssGB > $1.rssGB }.prefix(limit))
    }

    /// Graceful quit (SIGTERM) — lets the app clean up and prompt to save
    /// unsaved work, unlike a force-kill. If a process ignores this, it'll
    /// still show up next refresh so you can decide what to do about it.
    static func quit(pid: Int32) {
        _ = SystemStatsCollector.run("/bin/kill", [String(pid)])
    }
}
