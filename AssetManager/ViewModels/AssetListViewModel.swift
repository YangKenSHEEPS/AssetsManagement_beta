import Foundation
import SwiftData

@MainActor
final class AssetListViewModel: ObservableObject {
    @Published var assets: [Asset] = []
    @Published var filter = AssetFilter()
    @Published var errorMessage: String?
    @Published var selection = Set<UUID>()

    private let repository: AssetRepositoryType

    init(repository: AssetRepositoryType) {
        self.repository = repository
    }

    func load() {
        do {
            assets = try repository.fetch(filter: filter)
        } catch {
            errorMessage = "加载资产失败：\(error.localizedDescription)"
        }
    }

    func delete(_ asset: Asset) {
        do {
            try repository.delete(asset)
            load()
        } catch {
            errorMessage = "删除失败：\(error.localizedDescription)"
        }
    }

    func bulkDelete() {
        let toDelete = assets.filter { selection.contains($0.id) }
        do {
            try repository.bulkDelete(toDelete)
            selection.removeAll()
            load()
        } catch {
            errorMessage = "批量删除失败：\(error.localizedDescription)"
        }
    }

    func bulkScrap() {
        let toScrap = assets.filter { selection.contains($0.id) }
        do {
            try repository.bulkUpdateStatus(toScrap, status: .retired)
            selection.removeAll()
            load()
        } catch {
            errorMessage = "批量报废失败：\(error.localizedDescription)"
        }
    }
}
