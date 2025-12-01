import SwiftUI
import Charts

struct AdminHomeView: View {
    @StateObject var viewModel: AdminViewModel
    @State private var unlocked = false
    @State private var showShare = false
    private let authService = AuthService()

    var body: some View {
        NavigationStack {
            Group {
                if unlocked {
                    content
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 48))
                        Text("后台管理已锁定")
                        Button("使用 FaceID 解锁") {
                            Task {
                                unlocked = await authService.authenticate(reason: "进入后台管理")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("后台")
            .sheet(isPresented: $showShare, onDismiss: { viewModel.exportURL = nil }) {
                if let url = viewModel.exportURL {
                    ShareLink(item: url) {
                        Label("分享导出文件", systemImage: "square.and.arrow.up")
                    }
                    .padding()
                }
            }
            .alert("提示", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.errorMessage = nil })
            ) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .onAppear { if unlocked { viewModel.load() } }
        .onChange(of: unlocked) { _, newValue in
            if newValue { viewModel.load() }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summaryCards
                distributionChart
                adminActions
                adminList
            }
            .padding()
        }
    }

    private var summaryCards: some View {
        let stats = viewModel.summary
        return HStack {
            VStack(alignment: .leading) {
                Text("资产总数").font(.caption).foregroundColor(.secondary)
                Text("\(stats.total)")
                    .font(.title.bold())
            }
            Spacer()
            VStack(alignment: .leading) {
                Text("总价值").font(.caption).foregroundColor(.secondary)
                Text("￥\(stats.totalValue, specifier: "%.2f")")
                    .font(.title2.bold())
            }
            Spacer()
            VStack(alignment: .leading) {
                Text("报废").font(.caption).foregroundColor(.secondary)
                Text("\(stats.retired)")
                    .font(.title2.bold())
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }

    private var distributionChart: some View {
        let data: [(String, Int)] = [
            ("在用", viewModel.summary.inUse),
            ("报废", viewModel.summary.retired),
            ("维修", viewModel.summary.maintenance),
            ("闲置", viewModel.summary.idle)
        ]
        return Chart(data, id: \.0) { item in
            BarMark(x: .value("数量", item.1), y: .value("状态", item.0))
        }
        .frame(height: 200)
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }

    private var adminActions: some View {
        HStack {
            Button {
                viewModel.exportCSV()
                showShare = viewModel.exportURL != nil
            } label: {
                Label("导出 CSV", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)

            Button {
                viewModel.exportJSON()
                showShare = viewModel.exportURL != nil
            } label: {
                Label("备份 JSON", systemImage: "tray.and.arrow.down")
            }
            .buttonStyle(.bordered)
        }
    }

    private var adminList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("高级筛选").font(.headline)
                Spacer()
                Button("刷新") { viewModel.load() }
            }
            TextField("搜索", text: Binding(
                get: { viewModel.filter.keyword },
                set: { viewModel.filter.keyword = $0; viewModel.load() })
            )
            .textFieldStyle(.roundedBorder)

            Menu {
                Button("全部") { viewModel.filter.status = nil; viewModel.load() }
                ForEach(AssetStatus.allCases) { status in
                    Button(status.displayName) { viewModel.filter.status = status; viewModel.load() }
                }
            } label: {
                Label(viewModel.filter.status?.displayName ?? "状态筛选", systemImage: "line.3.horizontal.decrease.circle")
            }

            ForEach(viewModel.assets, id: \.id) { asset in
                AssetRowView(asset: asset)
                    .padding(.vertical, 4)
                Divider()
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}
