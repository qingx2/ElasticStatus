import Foundation
import SwiftUI

/// 刷新频率枚举
enum RefreshInterval: Double, CaseIterable, Identifiable, Sendable {
    case oneSecond = 1
    case fiveSeconds = 5
    case fifteenSeconds = 15
    case thirtySeconds = 30
    case sixtySeconds = 60

    var id: Double { rawValue }

    var label: String {
        switch self {
        case .oneSecond:      return "1s"
        case .fiveSeconds:    return "5s"
        case .fifteenSeconds: return "15s"
        case .thirtySeconds:  return "30s"
        case .sixtySeconds:   return "60s"
        }
    }
}

/// 配置管理器，使用 UserDefaults 持久化
@Observable
@MainActor
final class SettingsManager: Sendable {
    static let shared = SettingsManager()

    var elasticsearchURL: String {
        didSet { UserDefaults.standard.set(elasticsearchURL, forKey: "elasticsearchURL") }
    }

    var refreshInterval: RefreshInterval {
        didSet { UserDefaults.standard.set(refreshInterval.rawValue, forKey: "refreshInterval") }
    }

    private init() {
        self.elasticsearchURL = UserDefaults.standard.string(forKey: "elasticsearchURL") ?? "http://localhost:9200"
        let savedInterval = UserDefaults.standard.double(forKey: "refreshInterval")
        self.refreshInterval = RefreshInterval(rawValue: savedInterval) ?? .fiveSeconds
    }
}
