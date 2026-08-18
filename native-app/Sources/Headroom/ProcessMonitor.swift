import Foundation

struct GroupedProcess: Identifiable {
    var id: String { name }
    let name: String
    let totalRssGB: Double
    let pids: [Int32]
    var count: Int { pids.count }
}

struct CPUProcess: Identifiable {
    var id: Int32 { pid }
    let pid: Int32
    let name: String
    let cpuPercent: Double
}

/// Lists the current user's own processes, scoped to `-u <you>` rather than
/// all processes system-wide — that naturally excludes root-owned system
/// daemons (WindowServer, kernel_task, etc.), since those run as a
/// different user and can't accidentally end up in this list.
enum ProcessMonitor {

    static func topMemoryConsumers(limit: Int = 6) -> [GroupedProcess] {
        let user = NSUserName()
        let output = SystemStatsCollector.run("/bin/ps", ["-u", user, "-o", "pid,rss,comm"])
        let myPID = ProcessInfo.processInfo.processIdentifier

        var grouped: [String: (rss: Double, pids: [Int32])] = [:]
        for line in output.split(separator: "\n").dropFirst() {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 3 else { continue }
            guard let pid = Int32(parts[0]), let rssKB = Double(parts[1]) else { continue }
            if pid == myPID { continue }

            let fullPath = parts[2...].joined(separator: " ")
            let name = groupName(for: (fullPath as NSString).lastPathComponent)

            var entry = grouped[name] ?? (0, [])
            entry.rss += rssKB / 1024 / 1024
            entry.pids.append(pid)
            grouped[name] = entry
        }

        let items = grouped.map { name, value in
            GroupedProcess(name: name, totalRssGB: value.rss, pids: value.pids)
        }
        return Array(items.sorted { $0.totalRssGB > $1.totalRssGB }.prefix(limit))
    }

    static func topCPUConsumers(limit: Int = 5) -> [CPUProcess] {
        let user = NSUserName()
        let output = SystemStatsCollector.run("/bin/ps", ["-u", user, "-o", "pid,pcpu,comm"])
        let myPID = ProcessInfo.processInfo.processIdentifier

        var results: [CPUProcess] = []
        for line in output.split(separator: "\n").dropFirst() {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 3 else { continue }
            guard let pid = Int32(parts[0]), let cpu = Double(parts[1]) else { continue }
            if pid == myPID { continue }

            let fullPath = parts[2...].joined(separator: " ")
            let name = (fullPath as NSString).lastPathComponent
            results.append(CPUProcess(pid: pid, name: name, cpuPercent: cpu))
        }
        return Array(results.sorted { $0.cpuPercent > $1.cpuPercent }.prefix(limit))
    }

    /// Graceful quit (SIGTERM) — lets the app clean up and prompt to save
    /// unsaved work, unlike a force-kill. If a process ignores this, it'll
    /// still show up next refresh so you can decide what to do about it.
    static func quit(pid: Int32) {
        _ = SystemStatsCollector.run("/bin/kill", [String(pid)])
    }

    static func quit(pids: [Int32]) {
        for pid in pids { quit(pid: pid) }
    }

    /// Collapses helper/renderer processes into their parent app so e.g.
    /// four "Google Chrome Helper (Renderer)" rows become one "Google
    /// Chrome" entry with a combined total, instead of a wall of
    /// near-identical rows.
    private static func groupName(for raw: String) -> String {
        let suffixes = [
            " Helper (Renderer)",
            " Helper (GPU)",
            " Helper (Plugin)",
            " Helper (Alerts)",
            " Helper"
        ]
        for suffix in suffixes where raw.hasSuffix(suffix) {
            return String(raw.dropLast(suffix.count))
        }
        return raw
    }
}
