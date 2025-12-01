import SwiftUI

struct AssetFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AssetFormViewModel
    var completion: (Asset?) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("资产名称*", text: $viewModel.assetName)
                    TextField("价格*", text: $viewModel.price)
                        .keyboardType(.decimalPad)
                    DatePicker("购买日期", selection: $viewModel.purchaseDate, displayedComponents: .date)
                    DatePicker("登记日期", selection: $viewModel.registerDate, displayedComponents: .date)
                    Stepper(value: $viewModel.scrapYears, in: 0...50) {
                        Text("报废年限：\(viewModel.scrapYears) 年")
                    }
                    Picker("状态", selection: $viewModel.status) {
                        ForEach(AssetStatus.allCases) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                }
                Section("补充信息") {
                    HStack {
                        Text("资产编号")
                        Spacer()
                        Text(viewModel.assetNumber)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    TextField("分类", text: $viewModel.category)
                    TextField("存放地点", text: $viewModel.location)
                    TextField("负责人/部门", text: $viewModel.owner)
                    TextField("序列号", text: $viewModel.serialNumber)
                    TextField("备注", text: $viewModel.note, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error).foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("资产表单")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let asset = viewModel.save()
                        if asset != nil {
                            completion(asset)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
