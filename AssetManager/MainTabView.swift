import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        TabView {
            AssetListView(viewModel: AssetListViewModel(repository: AssetRepository(context: context)))
                .tabItem {
                    Label("资产", systemImage: "list.bullet.rectangle")
                }

            ScanTabView(viewModel: ScanViewModel(repository: AssetRepository(context: context)))
                .tabItem {
                    Label("扫码", systemImage: "qrcode.viewfinder")
                }

            AdminHomeView(viewModel: AdminViewModel(repository: AssetRepository(context: context)))
                .tabItem {
                    Label("后台", systemImage: "slider.horizontal.3")
                }
        }
    }
}
