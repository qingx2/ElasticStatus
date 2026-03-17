import Foundation

/// Elasticsearch 节点信息模型
struct NodeInfo: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let ip: String
    let cpuPercent: Int
    let nodeRole: String

    /// CPU 使用率归一化到 0...1
    var cpuFraction: Double {
        Double(cpuPercent) / 100.0
    }
}

/// 用于解码 _cat/nodes API JSON 响应
struct CatNodeResponse: Decodable, Sendable {
    let name: String
    let cpu: String?
    let ip: String?
    let nodeRole: String?

    enum CodingKeys: String, CodingKey {
        case name
        case cpu
        case ip
        case nodeRole = "node.role"
    }

    func toNodeInfo() -> NodeInfo {
        NodeInfo(
            name: name,
            ip: ip ?? "N/A",
            cpuPercent: Int(cpu ?? "0") ?? 0,
            nodeRole: nodeRole ?? "—"
        )
    }
}
