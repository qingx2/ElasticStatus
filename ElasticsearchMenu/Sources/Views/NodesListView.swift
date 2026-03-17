import SwiftUI

struct NodesListView: View {
    @State private var service = ElasticsearchService()
    @State private var settings = SettingsManager.shared
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            headerView

            Divider()
                .padding(.horizontal)

            // 内容区
            ScrollView {
                VStack(spacing: 8) {
                    if service.isLoading {
                        loadingView
                    } else if let error = service.errorMessage {
                        errorView(error)
                    } else if service.nodes.isEmpty {
                        emptyView
                    } else {
                        ForEach(service.nodes) { node in
                            NodeCardView(node: node)
                        }
                    }
                }
                .padding(12)
            }
            .frame(minHeight: dynamicMinHeight, maxHeight: 1600)

            Divider()
                .padding(.horizontal)

            // 底部按钮栏
            footerView
        }
        .frame(width: 320)
        .onAppear {
            service.isPollingEnabled = true
        }
        .onDisappear {
            service.isPollingEnabled = false
        }
        .onChange(of: settings.refreshInterval) {
            service.reschedulePolling()
        }
    }

    // 计算动态高度
    private var dynamicMinHeight: CGFloat {
        if service.isLoading || service.errorMessage != nil || service.nodes.isEmpty {
            return 150
        }
        // 每个卡片大约 80 高度，间隔 8，上下 padding 24
        let estimatedNodeHeight: CGFloat = 80
        let spacing: CGFloat = 8
        let padding: CGFloat = 24
        let count = CGFloat(service.nodes.count)
        
        let calculatedHeight = count * estimatedNodeHeight + max(0, count - 1) * spacing + padding
        return min(calculatedHeight, 1600)
    }

    // MARK: - 子视图

    private var headerView: some View {
        HStack {
            Image(systemName: "server.rack")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tint)

            Text("Elasticsearch Nodes")
                .font(.system(size: 14, weight: .semibold, design: .rounded))

            Spacer()

            // 刷新按钮
            Button {
                Task { await service.fetchNodes() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Refresh Now")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.small)
            Text("Loading nodes…")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.orange)

            Text("Connection Error")
                .font(.system(size: 13, weight: .semibold))

            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)

            Button("Retry") {
                Task { await service.fetchNodes() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    private var emptyView: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)

            Text("No Nodes Found")
                .font(.system(size: 13, weight: .semibold))

            Text("Check your Elasticsearch configuration.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    private var footerView: some View {
        HStack {
            Button {
                NSApp.activate(ignoringOtherApps: true)
                try? openSettings()
            } label: {
                Label("Settings", systemImage: "gearshape")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Spacer()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
