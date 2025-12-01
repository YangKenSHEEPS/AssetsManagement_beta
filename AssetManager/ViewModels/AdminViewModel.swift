import Foundation

@MainActor
final class AdminViewModel: ObservableObject {
    @Published var assets: [Asset] = []
    @Published var filter = AssetFilter()
    @Published var exportURL: URL?
    @Published var errorMessage: String?

    private let repository: AssetRepositoryType
    private let exportService: ExportService

    init(repository: AssetRepositoryType, exportService: ExportService = ExportService()) {
        self.repository = repository
        self.exportService = exportService
    }

    var summary: (total: Int, inUse: Int, retired: Int, maintenance: Int, idle: Int, totalValue: Double) {
        let total = assets.count
        let inUse = assets.filter { $0.status == .inUse }.count
        let retired = assets.filter { $0.status == .retired }.count
        let maintenance = assets.filter { $0.status == .maintenance }.count
        let idle = assets.filter { $0.status == .idle }.count
        let totalValue = assets.reduce(0) { $0 + $1.price }
        return (total, inUse, retired, maintenance, idle, totalValue)
    }

    func load() {
        do {
            assets = try repository.fetch(filter: filter)
        } catch {
            errorMessage = "加载失败：\(error.localizedDescription)"
        }
    }

    func exportCSV() {
        do {
            exportURL = try exportService.exportCSV(assets)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func exportJSON() {
        do {
            exportURL = try exportService.exportJSON(assets)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
