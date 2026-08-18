import Foundation

enum PressureLevel: Int, Comparable {
    case normal = 0, warning = 1, critical = 2

    static func < (lhs: PressureLevel, rhs: PressureLevel) -> Bool { lhs.rawValue < rhs.rawValue }

    var label: String {
        switch self {
        case .normal: return "Normal"
        case .warning: return "Warning"
        case .critical: return "Critical"
        }
    }
}

struct SystemStats {
    var freeGB: Double = 0
    var totalGB: Int = 0
    var pressure: PressureLevel = .normal
    var cpuUsedPercent: Int? = nil
    var diskFreeGB: Double = 0
    var diskTotalGB: Double = 0
    var batteryPercent: Int? = nil
    var isCharging: Bool = false
    var isOnACPower: Bool = true
    var thermalState: ProcessInfo.ThermalState = .nominal
}

enum SystemStatsCollector {

    static func run(_ path: String, _ args: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args
        let outPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = Pipe()
        do {
            try process.run()
        } catch {
            return ""
        }
        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(data: data, encoding: .utf8) ?? ""
    }

    static func collect(config: Config) -> SystemStats {
        var stats = SystemStats()

        // Memory
        let vmStat = run("/usr/bin/vm_stat", [])
        let pageSize = parsePageSize(vmStat)
        let pagesFree = parseValue(vmStat, key: "Pages free")
        let pagesInactive = parseValue(vmStat, key: "Pages inactive")
        let freeBytes = Double(pagesFree + pagesInactive) * Double(pageSize)
        stats.freeGB = freeBytes / 1_073_741_824

        let totalBytesStr = run("/usr/sbin/sysctl", ["-n", "hw.memsize"])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let totalBytes = Double(totalBytesStr) ?? 0
        stats.totalGB = Int(totalBytes / 1_073_741_824)

        let pressureLevelStr = run("/usr/sbin/sysctl", ["-n", "kern.memorystatus_vm_pressure_level"])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let pressureLevel = Int(pressureLevelStr) ?? 0
        switch pressureLevel {
        case 4:
            stats.pressure = .critical
        case 2:
            stats.pressure = .warning
        case 1:
            stats.pressure = .normal
        default:
            let freePct = stats.totalGB > 0 ? (stats.freeGB / Double(stats.totalGB)) * 100 : 100
            if freePct < Double(config.criticalFreePercent) {
                stats.pressure = .critical
            } else if freePct < Double(config.warningFreePercent) {
                stats.pressure = .warning
            } else {
                stats.pressure = .normal
            }
        }

        // CPU
        let topOut = run("/usr/bin/top", ["-l", "1", "-n", "0"])
        stats.cpuUsedPercent = parseCPU(topOut)

        // Disk (root volume)
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/") {
            if let free = attrs[.systemFreeSize] as? NSNumber {
                stats.diskFreeGB = free.doubleValue / 1_073_741_824
            }
            if let total = attrs[.systemSize] as? NSNumber {
                stats.diskTotalGB = total.doubleValue / 1_073_741_824
            }
        }

        // Battery / power
        let battOut = run("/usr/bin/pmset", ["-g", "batt"])
        let (pct, charging, onAC) = parseBattery(battOut)
        stats.batteryPercent = pct
        stats.isCharging = charging
        stats.isOnACPower = onAC

        // Thermal (native API, no shell-out needed)
        stats.thermalState = ProcessInfo.processInfo.thermalState

        return stats
    }

    private static func parsePageSize(_ s: String) -> Int {
        if let range = s.range(of: #"page size of (\d+) bytes"#, options: .regularExpression) {
            let digits = String(s[range]).filter { $0.isNumber }
            return Int(digits) ?? 4096
        }
        return 4096
    }

    private static func parseValue(_ s: String, key: String) -> Int {
        for line in s.split(separator: "\n") where line.hasPrefix(key) {
            let digits = line.filter { $0.isNumber }
            return Int(digits) ?? 0
        }
        return 0
    }

    private static func parseCPU(_ s: String) -> Int? {
        guard let line = s.split(separator: "\n").first(where: { $0.contains("CPU usage") }) else {
            return nil
        }
        guard let range = line.range(of: #"[0-9.]+% idle"#, options: .regularExpression) else {
            return nil
        }
        let numStr = String(line[range]).replacingOccurrences(of: "% idle", with: "")
        guard let idle = Double(numStr) else { return nil }
        return Int(100 - idle)
    }

    private static func parseBattery(_ s: String) -> (Int?, Bool, Bool) {
        let onAC = s.contains("AC Power")
        let charging = s.contains("; charging;") || s.contains("; charged;")
        var pct: Int? = nil
        if let range = s.range(of: #"\d+%"#, options: .regularExpression) {
            let digits = String(s[range]).filter { $0.isNumber }
            pct = Int(digits)
        }
        return (pct, charging, onAC)
    }
}
