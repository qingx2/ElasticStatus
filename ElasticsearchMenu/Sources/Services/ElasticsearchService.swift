import Foundation

/// Elasticsearch 节点数据获取服务
@Observable
@MainActor
final class ElasticsearchService: Sendable {
    var nodes: [NodeInfo] = []
    var isLoading = false
    var errorMessage: String?

    private var timer: Timer?
    private let settings = SettingsManager.shared

    /// 控制是否允许轮询（当菜单关闭时应暂停）
    var isPollingEnabled = false {
        didSet {
            if isPollingEnabled {
                startPolling()
            } else {
                stopPolling()
            }
        }
    }

    /// 开始定时拉取节点数据
    func startPolling() {
        guard isPollingEnabled else { return }
        stopPolling()
        Task { await fetchNodes() }
        scheduleTimer()
    }

    /// 停止定时拉取
    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    /// 根据当前刷新频率重新调度定时器
    func reschedulePolling() {
        stopPolling()
        scheduleTimer()
    }

    private func scheduleTimer() {
        let interval = settings.refreshInterval.rawValue
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchNodes()
            }
        }
    }

    /// 从 Elasticsearch 拉取节点 CPU 数据
    func fetchNodes() async {
        let baseURL = settings.elasticsearchURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(baseURL)/_cat/nodes?format=json&h=name,cpu,ip,node.role") else {
            errorMessage = "Invalid URL: \(settings.elasticsearchURL)"
            return
        }

        isLoading = nodes.isEmpty  // 仅首次加载时显示 loading
        errorMessage = nil

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                errorMessage = "HTTP \(statusCode)"
                isLoading = false
                return
            }

            let decoded = try JSONDecoder().decode([CatNodeResponse].self, from: data)
            nodes = decoded.map { $0.toNodeInfo() }.sorted { $0.name < $1.name }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
