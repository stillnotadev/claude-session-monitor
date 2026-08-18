import SwiftUI
import AppKit
import Foundation

struct ContentView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            memorySection
            Divider()
            environmentSection
            Divider()
            recommendationBanner
            Divider()
            quickActionsSection
        }
        .frame(width: 340)
        .padding(.bottom, 8)
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Image(systemName: "gauge")
                .foregroundStyle(.blue)
            Text("Headroom")
                .font(.headline)
            Spacer()
            Button {
                state.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
        }
        .padding(12)
    }

    // MARK: Memory

    private var memorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Memory pressure")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                trendIcon
                Text(state.stats.pressure.label)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(pressureColor.opacity(0.18))
                    .foregroundStyle(pressureColor)
                    .clipShape(Capsule())
            }
            ProgressView(value: memoryFraction)
                .tint(pressureColor)
            HStack {
                Text("\(formatted(state.stats.freeGB)) GB free of \(state.stats.totalGB) GB")
                Spacer()
                if let cpu = state.stats.cpuUsedPercent {
                    Label("\(cpu)%", systemImage: "cpu")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(12)
    }

    private var memoryFraction: Double {
        guard state.stats.totalGB > 0 else { return 0 }
        return min(state.stats.freeGB / Double(state.stats.totalGB), 1)
    }

    @ViewBuilder
    private var trendIcon: some View {
        switch state.trend {
        case .rising:
            Image(systemName: "arrow.up").foregroundStyle(.orange).font(.caption2)
        case .easing:
            Image(systemName: "arrow.down").foregroundStyle(.green).font(.caption2)
        case .flat:
            EmptyView()
        }
    }

    private var pressureColor: Color {
        switch state.stats.pressure {
        case .normal: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }

    // MARK: Disk / battery / thermal

    private var environmentSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("\(formatted(state.stats.diskFreeGB, decimals: 0)) GB free disk", systemImage: "internaldrive")
                Spacer()
                if let pct = state.stats.batteryPercent {
                    Label(
                        "\(pct)%" + (state.stats.isOnACPower ? " · plugged in" : ""),
                        systemImage: state.stats.isOnACPower ? "powerplug" : "battery.100"
                    )
                }
            }
            if state.stats.thermalState != .nominal {
                Label(thermalLabel, systemImage: "thermometer")
                    .foregroundStyle(thermalColor)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(12)
    }

    private var thermalLabel: String {
        switch state.stats.thermalState {
        case .nominal: return "Thermal: normal"
        case .fair: return "Thermal: elevated"
        case .serious: return "Thermal: throttling"
        case .critical: return "Thermal: critical"
        @unknown default: return "Thermal: unknown"
        }
    }

    private var thermalColor: Color {
        switch state.stats.thermalState {
        case .serious: return .orange
        case .critical: return .red
        default: return .secondary
        }
    }

    // MARK: Recommendation

    private var recommendationBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: state.recommendation.level == .normal ? "checkmark.circle" : "cloud")
            Text(state.recommendation.text)
        }
        .font(.caption.weight(.medium))
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(recommendationColor.opacity(0.18))
        .foregroundStyle(recommendationColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(12)
    }

    private var recommendationColor: Color {
        switch state.recommendation.level {
        case .normal: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }

    // MARK: Quick actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button("Open memory log") { QuickActions.openMemoryLog() }
            Button("Open git identity folder") { QuickActions.openGitIdentityFolder() }
            Button("Edit thresholds config") { QuickActions.openConfigFile() }
            Divider()
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
        .buttonStyle(.plain)
        .font(.caption)
        .foregroundStyle(.blue)
        .padding(12)
    }

    // MARK: Formatting

    private func formatted(_ value: Double, decimals: Int = 1) -> String {
        String(format: "%.\(decimals)f", value)
    }
}
