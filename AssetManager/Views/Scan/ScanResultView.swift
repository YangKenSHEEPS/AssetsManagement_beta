import SwiftUI

struct ScanResultView: View {
    let asset: Asset
    let isNew: Bool
    let onDone: () -> Void
    let onDetail: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isNew ? "已保存新资产" : "已更新现有资产")
                .font(.headline)
            infoRow("名称", asset.assetName)
            infoRow("价格", String(format: "￥%.2f", asset.price))
            infoRow("购买时间", asset.purchaseDate.formatted(date: .abbreviated, time: .omitted))
            infoRow("登记时间", asset.registerDate.formatted(date: .abbreviated, time: .omitted))
            infoRow("报废年限", "\(asset.scrapYears) 年")
            infoRow("状态", asset.status.displayName, color: statusColor())
            Spacer()
            Button {
                onDetail()
            } label: {
                Label("查看资产详情", systemImage: "info.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            Button("完成") { onDone() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .navigationTitle("扫码结果")
    }

    private func infoRow(_ title: String, _ value: String, color: Color? = nil) -> some View {
        HStack {
            Text(title).foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(color ?? .primary)
        }
    }

    private func statusColor() -> Color {
        switch asset.status {
        case .inUse: return .green
        case .retired: return .red
        case .maintenance: return .yellow
        case .idle: return .gray
        }
    }
}
