import SwiftUI

/// 单个节点 CPU 使用率卡片
struct NodeCardView: View {
    let node: NodeInfo

    /// 根据 CPU 使用率返回渐变色
    private var progressColor: Color {
        switch node.cpuPercent {
        case 0..<60:   return .green
        case 60..<80:  return .orange
        default:       return .red
        }
    }

    /// 渐变背景
    private var progressGradient: LinearGradient {
        LinearGradient(
            colors: [progressColor.opacity(0.7), progressColor],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 顶部：节点名称 + CPU 百分比
            HStack {
                Image(systemName: "cpu")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(progressColor)

                Text(node.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .lineLimit(1)

                Spacer()

                Text("\(node.cpuPercent)%")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(progressColor)
            }

            // CPU 色块进度条
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // 背景轨道
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.quaternary)
                        .frame(height: 8)

                    // 前景进度条
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressGradient)
                        .frame(width: max(geo.size.width * node.cpuFraction, 4), height: 8)
                        .animation(.easeInOut(duration: 0.5), value: node.cpuPercent)
                }
            }
            .frame(height: 8)

            // 底部信息
            HStack(spacing: 12) {
                Label(node.ip, systemImage: "network")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)

                Label(node.nodeRole, systemImage: "tag")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
    }
}
