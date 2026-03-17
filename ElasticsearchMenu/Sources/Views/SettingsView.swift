import SwiftUI

/// 配置界面
struct SettingsView: View {
    @State private var settings = SettingsManager.shared
    @State private var testResult: TestResult?
    @State private var isTesting = false
    @Environment(\.dismiss) private var dismiss

    enum TestResult {
        case success(Int)   // 节点数量
        case failure(String)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(.tint)
                Text("Settings")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 24) {
                // Server 配置项
                VStack(alignment: .leading, spacing: 8) {
                    Text("Server Settings")
                        .font(.system(size: 13, weight: .bold))
                    
                    Text("Elasticsearch URL")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    
                    TextField("http://localhost:9200", text: $settings.elasticsearchURL)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13, design: .monospaced))
                        .frame(maxWidth: .infinity)

                    // 测试连接
                    HStack {
                        Button {
                            Task { await testConnection() }
                        } label: {
                            HStack(spacing: 4) {
                                if isTesting {
                                    ProgressView().controlSize(.mini)
                                } else {
                                    Image(systemName: "bolt.fill")
                                }
                                Text("Test Connection")
                            }
                        }
                        .controlSize(.small)
                        .disabled(isTesting)

                        if let result = testResult {
                            testResultLabel(result)
                        }
                    }
                }

                Divider()

                // 轮询频率配置项
                VStack(alignment: .leading, spacing: 8) {
                    Text("Polling Settings")
                        .font(.system(size: 13, weight: .bold))
                    
                    HStack {
                        Text("Refresh Interval")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Picker("", selection: $settings.refreshInterval) {
                            ForEach(RefreshInterval.allCases) { interval in
                                Text(interval.label).tag(interval)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 250)
                    }
                }
                
                Spacer()
            }
        }
        .padding(24)
        .frame(width: 450, height: 350)
        .onAppear {
            DispatchQueue.main.async {
                NSApplication.shared.activate(ignoringOtherApps: true)
                if let window = NSApplication.shared.windows.first(where: { $0.title == "Settings" || $0.identifier?.rawValue == "com_apple_SwiftUI_Settings_window" }) {
                    window.makeKeyAndOrderFront(nil)
                }
            }
        }
    }

    // MARK: - 连接测试

    private func testConnection() async {
        isTesting = true
        testResult = nil

        let baseURL = settings.elasticsearchURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(baseURL)/_cat/nodes?format=json&h=name") else {
            testResult = .failure("Invalid URL")
            isTesting = false
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                testResult = .failure("HTTP \(statusCode)")
                isTesting = false
                return
            }

            struct NameOnly: Decodable { let name: String }
            let nodes = try JSONDecoder().decode([NameOnly].self, from: data)
            testResult = .success(nodes.count)
        } catch {
            testResult = .failure(error.localizedDescription)
        }

        isTesting = false
    }

    @ViewBuilder
    private func testResultLabel(_ result: TestResult) -> some View {
        switch result {
        case .success(let count):
            Label("\(count) node(s) found", systemImage: "checkmark.circle.fill")
                .font(.system(size: 11))
                .foregroundStyle(.green)
        case .failure(let message):
            Label(message, systemImage: "xmark.circle.fill")
                .font(.system(size: 11))
                .foregroundStyle(.red)
                .lineLimit(1)
        }
    }
}
