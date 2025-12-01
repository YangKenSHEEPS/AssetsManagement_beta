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
            .navigationTitle("资产")
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
                            Button("退出登录", role: .destructive) {
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
        TextField("搜索名称/序列号/负责人/地点", text: Binding(
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
                    Button("全部") { viewModel.filter.status = nil; viewModel.load() }
                    ForEach(AssetStatus.allCases) { status in
                        Button(status.displayName) {
                            viewModel.filter.status = status
                            viewModel.load()
                        }
                    }
                } label: {
                    Label(viewModel.filter.status?.displayName ?? "状态", systemImage: "line.3.horizontal.decrease.circle")
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
                    Label("重置", systemImage: "arrow.counterclockwise")
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
            Text("暂无资产")
                .font(.headline)
            Button("去新增资产") {
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
                        Label("批量删除", systemImage: "trash")
                    }
                    .confirmationDialog("确认删除选中资产？", isPresented: $showDeleteConfirm) {
                        Button("删除", role: .destructive) { viewModel.bulkDelete() }
                        Button("取消", role: .cancel) {}
                    }

                    Button {
                        showScrapConfirm = true
                    } label: {
                        Label("批量报废", systemImage: "exclamationmark.triangle")
                    }
                    .confirmationDialog("标记为报废？", isPresented: $showScrapConfirm) {
                        Button("报废", role: .destructive) { viewModel.bulkScrap() }
                        Button("取消", role: .cancel) {}
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
                Text("编号：\(asset.assetNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("￥\(asset.price, specifier: "%.2f") · \(asset.status.displayName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if let owner = asset.owner {
                    Text("负责人：\(owner)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(asset.category ?? "未分类")
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
