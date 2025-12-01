import SwiftUI
import SwiftData

@main
struct AssetManagerApp: App {
    private let container: ModelContainer

    init() {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            container = try ModelContainer(for: Asset.self, configurations: config)
        } catch {
            fatalError("无法初始化数据存储：\(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(container)
    }
}
