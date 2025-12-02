import SwiftUI
import SwiftData

struct AssetListView: View {
    @StateObject var viewModel: AssetListViewModel
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var appState: AppState
    @State private var showForm = false
    @State private var showDeleteConfirm = false
    @State private var showScrapConfirm = false
    @State private var editMode: EditMode = .inactive
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationStack {
            VStack {
                searchBar
                filterBar
                if viewModel.assets.isEmpty {
                    emptyView
                } else {
                    List(selection: $viewModel.selection) {
                        ForEach(viewModel.assets, id: \.id) { asset in
                            NavigationLink {
                                AssetDetailView(asset: asset, repository: AssetRepository(context: context))
                            } label: {
                                AssetRowView(asset: asset)
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.map { viewModel.assets[$0] }.forEach { viewModel.delete($0) }
                        }
                    }
                    .environment(\.editMode, $editMode)
                    batchToolbar
                }
            }
            .navigationTitle(NSLocalizedString("资产", comment: "tab"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            showForm = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        Menu {
                            Button(NSLocalizedString("退出登录", comment: ""), role: .destructive) {
                                showLogoutConfirm = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .onAppear { viewModel.load() }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active { viewModel.load() }
            }
            .sheet(isPresented: $showForm) {
                AssetFormView(viewModel: AssetFormViewModel(mode: .create, repository: AssetRepository(context: context))) { asset in
                    showForm = false
                    if asset != nil { viewModel.load() }
                }
            }
            .alert("提示", isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.errorMessage = nil })
            ) {
                Button("知道了", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .confirmationDialog("确认退出登录？", isPresented: $showLogoutConfirm) {
                Button("退出", role: .destructive) { appState.logout() }
                Button("取消", role: .cancel) {}
            }
        }
    }

    private var searchBar: some View {
        TextField(NSLocalizedString("搜索名称/序列号/负责人/地点", comment: ""), text: Binding(
            get: { viewModel.filter.keyword },
            set: {
                viewModel.filter.keyword = $0
                viewModel.load()
            })
        )
        .textFieldStyle(.roundedBorder)
        .padding(.horizontal)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Menu {
                    Button(NSLocalizedString("全部", comment: "")) { viewModel.filter.status = nil; viewModel.load() }
                    ForEach(AssetStatus.allCases) { status in
                        Button(status.displayName) {
                            viewModel.filter.status = status
                            viewModel.load()
                        }
                    }
                } label: {
                    Label(viewModel.filter.status?.displayName ?? NSLocalizedString("状态", comment: ""), systemImage: "line.3.horizontal.decrease.circle")
                }

                Menu {
                    ForEach(AssetFilter.SortOption.allCases) { option in
                        Button(option.title) {
                            viewModel.filter.sort = option
                            viewModel.load()
                        }
                    }
                } label: {
                    Label(viewModel.filter.sort.title, systemImage: "arrow.up.arrow.down")
                }

                Button {
                    viewModel.filter = AssetFilter()
                    viewModel.load()
                } label: {
                    Label(NSLocalizedString("重置", comment: ""), systemImage: "arrow.counterclockwise")
                }
            }
            .padding(.horizontal)
            .buttonStyle(.bordered)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox")
                .font(.system(size: 48))
            Text(NSLocalizedString("暂无资产", comment: ""))
                .font(.headline)
            Button(NSLocalizedString("去新增资产", comment: "")) {
                showForm = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var batchToolbar: some View {
        Group {
            if editMode == .active && !viewModel.selection.isEmpty {
                HStack {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label(NSLocalizedString("批量删除", comment: ""), systemImage: "trash")
                    }
                    .confirmationDialog(NSLocalizedString("确认删除选中资产？", comment: ""), isPresented: $showDeleteConfirm) {
                        Button(NSLocalizedString("删除", comment: ""), role: .destructive) { viewModel.bulkDelete() }
                        Button(NSLocalizedString("取消", comment: ""), role: .cancel) {}
                    }

                    Button {
                        showScrapConfirm = true
                    } label: {
                        Label(NSLocalizedString("批量报废", comment: ""), systemImage: "exclamationmark.triangle")
                    }
                    .confirmationDialog(NSLocalizedString("标记为报废？", comment: ""), isPresented: $showScrapConfirm) {
                        Button(NSLocalizedString("报废", comment: ""), role: .destructive) { viewModel.bulkScrap() }
                        Button(NSLocalizedString("取消", comment: ""), role: .cancel) {}
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct AssetRowView: View {
    let asset: Asset

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(asset.assetName)
                    .font(.headline)
                Text("\(NSLocalizedString("编号", comment: ""))：\(asset.assetNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("￥\(asset.price, specifier: "%.2f") · \(asset.status.displayName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if let owner = asset.owner {
                    Text("\(NSLocalizedString("负责人", comment: ""))：\(owner)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(asset.category ?? NSLocalizedString("未分类", comment: ""))
                    .font(.caption)
                    .padding(6)
                    .background(.blue.opacity(0.1))
                    .cornerRadius(8)
                Text(asset.location ?? "")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}
