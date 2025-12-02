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
        .navigationTitle(NSLocalizedString("资产详情", comment: "Asset detail title"))
        .toolbar {
            Button(NSLocalizedString("编辑", comment: "Edit")) { showForm = true }
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
            labeledRow(title: NSLocalizedString("资产编号", comment: ""), value: asset.assetNumber)
            labeledRow(title: NSLocalizedString("价格", comment: ""), value: String(format: "￥%.2f", asset.price))
            labeledRow(title: NSLocalizedString("购买时间", comment: ""), value: asset.purchaseDate.formatted(date: .abbreviated, time: .omitted))
            labeledRow(title: NSLocalizedString("登记时间", comment: ""), value: asset.registerDate.formatted(date: .abbreviated, time: .omitted))
            labeledRow(title: NSLocalizedString("报废年限", comment: ""), value: "\(asset.scrapYears) \(NSLocalizedString("年", comment: ""))")
            if let category = asset.category { labeledRow(title: NSLocalizedString("分类", comment: ""), value: category) }
            if let location = asset.location { labeledRow(title: NSLocalizedString("存放地点", comment: ""), value: location) }
            if let owner = asset.owner { labeledRow(title: NSLocalizedString("负责人", comment: ""), value: owner) }
            if let serial = asset.serialNumber { labeledRow(title: NSLocalizedString("序列号", comment: ""), value: serial) }
            if let note = asset.note { labeledRow(title: NSLocalizedString("备注", comment: ""), value: note) }
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
                Label(NSLocalizedString("生成二维码", comment: ""), systemImage: "qrcode")
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
                Label(NSLocalizedString("更改状态", comment: ""), systemImage: "arrow.triangle.2.circlepath")
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
