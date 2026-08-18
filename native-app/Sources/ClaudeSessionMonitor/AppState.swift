import Foundation
import Combine

final class AppState: ObservableObject {
    enum Trend { case rising, easing, flat }

    @Published var stats = SystemStats()
    @Published var recommendation = Recommendation(level: .normal, text: "Loading…")
    @Published var runningProcesses: [RunningProcess] = []
    @Published var trend: Trend = .flat

    let config: Config

    private var timer: Timer?
    private var previousLevel: RecommendationLevel = .normal
    private var previousFreeGB: Double = 0
    private var isFirstRefresh = true

    init() {
        config = Config.load()
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: config.refreshIntervalSeconds, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func refresh() {
        let newStats = SystemStatsCollector.collect(config: config)
        let newRecommendation = computeRecommendation(stats: newStats, config: config)

        if !isFirstRefresh {
            if newStats.freeGB > previousFreeGB + 0.2 {
                trend = .easing
            } else if newStats.freeGB < previousFreeGB - 0.2 {
                trend = .rising
            } else {
                trend = .flat
            }

            if newRecommendation.level > previousLevel {
                Notifier.send(
                    title: "Claude sessions",
                    subtitle: "Memory pressure: \(newStats.pressure.label)",
                    body: "\(String(format: "%.1f", newStats.freeGB)) GB free — \(newRecommendation.text)"
                )
            }
        }

        previousFreeGB = newStats.freeGB
        previousLevel = newRecommendation.level
        isFirstRefresh = false

        stats = newStats
        recommendation = newRecommendation
        runningProcesses = ClaudeProcess.listRunning()
    }

    func killProcess(pid: Int32) {
        ClaudeProcess.kill(pid: pid)
        refresh()
    }
}
