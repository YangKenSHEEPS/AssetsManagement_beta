import SwiftUI
import SwiftData

struct AssetDetailView: View {
    let asset: Asset
    let repository: AssetRepositoryType
    @StateObject private var viewModel: AssetDetailViewModel
    @State private var showForm = false
    @State private var showQR = false

    init(asset: Asset, repository: AssetRepositoryType) {
        self.asset = asset
        self.repository = repository
        _viewModel = StateObject(wrappedValue: AssetDetailViewModel(asset: asset, repository: repository))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                infoSection
                actionButtons
            }
            .padding()
        }
        .navigationTitle("资产详情")
        .toolbar {
            Button("编辑") { showForm = true }
        }
        .sheet(isPresented: $showForm) {
            AssetFormView(viewModel: AssetFormViewModel(mode: .edit(asset), repository: repository)) { _ in
                showForm = false
            }
        }
        .sheet(isPresented: $showQR, onDismiss: { viewModel.qrImage = nil }) {
            QRPreviewView(asset: asset, viewModel: viewModel)
        }
        .alert("提示", isPresented: Binding(
            get: { viewModel.message != nil },
            set: { _ in viewModel.message = nil })
        ) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(viewModel.message ?? "")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(asset.assetName)
                .font(.largeTitle)
            Text(asset.status.displayName)
                .font(.headline)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor().opacity(0.15))
                .foregroundStyle(statusColor())
                .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            labeledRow(title: "资产编号", value: asset.assetNumber)
            labeledRow(title: "价格", value: String(format: "￥%.2f", asset.price))
            labeledRow(title: "购买时间", value: asset.purchaseDate.formatted(date: .abbreviated, time: .omitted))
            labeledRow(title: "登记时间", value: asset.registerDate.formatted(date: .abbreviated, time: .omitted))
            labeledRow(title: "报废年限", value: "\(asset.scrapYears) 年")
            if let category = asset.category { labeledRow(title: "分类", value: category) }
            if let location = asset.location { labeledRow(title: "存放地点", value: location) }
            if let owner = asset.owner { labeledRow(title: "负责人", value: owner) }
            if let serial = asset.serialNumber { labeledRow(title: "序列号", value: serial) }
            if let note = asset.note { labeledRow(title: "备注", value: note) }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.generateImage()
                showQR = true
            } label: {
                Label("生成二维码", systemImage: "qrcode")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Menu {
                ForEach(AssetStatus.allCases) { status in
                    Button(status.displayName) {
                        viewModel.updateStatus(status)
                    }
                }
            } label: {
                Label("更改状态", systemImage: "arrow.triangle.2.circlepath")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private func labeledRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
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
