import SwiftUI
import AppKit
import Foundation

enum ProcessTab: String, CaseIterable {
    case memory = "Memory"
    case cpu = "CPU"
}

struct ContentView: View {
    @ObservedObject var state: AppState
    @State private var launchAtLogin: Bool = LoginItem.isEnabled
    @State private var processTab: ProcessTab = .memory

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            statsRow
            Divider()
            recommendationBanner
            Divider()
            processSection
            Divider()
            quickActionsSection
        }
        .frame(width: 300)
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

    // MARK: Compact stats row (memory + disk + battery + CPU in one line)

    private var statsRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(state.stats.pressure.label)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(pressureColor.opacity(0.18))
                    .foregroundStyle(pressureColor)
                    .clipShape(Capsule())
                trendIcon
                Spacer()
            }
            HStack(spacing: 12) {
                statItem(icon: "memorychip", text: "\(formatted(state.stats.freeGB)) GB")
                statItem(icon: "internaldrive", text: "\(formatted(state.stats.diskFreeGB, decimals: 0)) GB")
                if let pct = state.stats.batteryPercent {
                    statItem(
                        icon: state.stats.isOnACPower ? "powerplug" : "battery.100",
                        text: "\(pct)%"
                    )
                }
                if let cpu = state.stats.cpuUsedPercent {
                    statItem(icon: "cpu", text: "\(cpu)%")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            if state.stats.thermalState != .nominal {
                Label(thermalLabel, systemImage: "thermometer")
                    .font(.caption2)
                    .foregroundStyle(thermalColor)
            }
        }
        .padding(12)
    }

    private func statItem(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
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

    // MARK: Processes (segmented Memory / CPU, one list at a time)

    private var processSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("", selection: $processTab) {
                ForEach(ProcessTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            switch processTab {
            case .memory:
                memoryList
            case .cpu:
                cpuList
            }
        }
        .padding(12)
    }

    @ViewBuilder
    private var memoryList: some View {
        if state.topMemoryProcesses.isEmpty {
            Text("Nothing significant")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            ForEach(state.topMemoryProcesses) { proc in
                HStack(spacing: 6) {
                    Text(proc.name)
                        .font(.caption)
                        .lineLimit(1)
                    if proc.count > 1 {
                        Text("· \(proc.count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(formatted(proc.totalRssGB)) GB")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Button {
                        state.quitProcessGroup(pids: proc.pids)
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
                .background(Color.gray.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
        }
    }

    @ViewBuilder
    private var cpuList: some View {
        if state.topCPUProcesses.isEmpty {
            Text("Nothing significant")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            ForEach(state.topCPUProcesses) { proc in
                HStack(spacing: 6) {
                    Text(proc.name)
                        .font(.caption)
                        .lineLimit(1)
                    Spacer()
                    Text("\(formatted(proc.cpuPercent, decimals: 0))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Button {
                        state.quitProcess(pid: proc.pid)
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
                .background(Color.gray.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
        }
    }

    // MARK: Quick actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Launch at login", isOn: $launchAtLogin)
                .toggleStyle(.checkbox)
                .font(.caption)
                .foregroundStyle(.primary)
                .onChange(of: launchAtLogin) { newValue in
                    LoginItem.setEnabled(newValue)
                }
            HStack(spacing: 12) {
                Button("Git identity") { QuickActions.openGitIdentityFolder() }
                Button("Thresholds") { QuickActions.openConfigFile() }
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.blue)
        }
        .padding(12)
    }

    // MARK: Formatting

    private func formatted(_ value: Double, decimals: Int = 1) -> String {
        String(format: "%.\(decimals)f", value)
    }
}
