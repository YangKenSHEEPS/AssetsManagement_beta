import Foundation
import SwiftData

@MainActor
protocol AssetRepositoryType {
    func fetch(filter: AssetFilter) throws -> [Asset]
    func add(_ asset: Asset) throws
    func update(_ asset: Asset) throws
    func delete(_ asset: Asset) throws
    func upsertFromPayload(_ payload: AssetPayload) throws -> (asset: Asset, created: Bool)
    func find(by id: UUID) throws -> Asset?
    func bulkDelete(_ assets: [Asset]) throws
    func bulkUpdateStatus(_ assets: [Asset], status: AssetStatus) throws
}

@MainActor
final class AssetRepository: AssetRepositoryType {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetch(filter: AssetFilter) throws -> [Asset] {
        let sortDescriptor: SortDescriptor<Asset>
        switch filter.sort {
        case .registerDateDesc: sortDescriptor = SortDescriptor(\.registerDate, order: .reverse)
        case .registerDateAsc: sortDescriptor = SortDescriptor(\.registerDate, order: .forward)
        case .priceDesc: sortDescriptor = SortDescriptor(\.price, order: .reverse)
        case .priceAsc: sortDescriptor = SortDescriptor(\.price, order: .forward)
        case .purchaseDateDesc: sortDescriptor = SortDescriptor(\.purchaseDate, order: .reverse)
        case .purchaseDateAsc: sortDescriptor = SortDescriptor(\.purchaseDate, order: .forward)
        case .updatedDesc: sortDescriptor = SortDescriptor(\.updatedAt, order: .reverse)
        }

        var results = try context.fetch(FetchDescriptor<Asset>(sortBy: [sortDescriptor]))

        // In-memory filters to avoid predicate compile complexity
        if let status = filter.status {
            results = results.filter { $0.status == status }
        }
        if let category = filter.category, !category.isEmpty {
            results = results.filter { ($0.category ?? "") == category }
        }
        if let start = filter.startDate {
            results = results.filter { $0.registerDate >= start }
        }
        if let end = filter.endDate {
            results = results.filter { $0.registerDate <= end }
        }
        if !filter.keyword.isEmpty {
            let keyword = filter.keyword
            results = results.filter { asset in
                asset.assetName.localizedStandardContains(keyword) ||
                (asset.serialNumber?.localizedStandardContains(keyword) ?? false) ||
                (asset.owner?.localizedStandardContains(keyword) ?? false) ||
                (asset.location?.localizedStandardContains(keyword) ?? false)
            }
        }
        return results
    }

    func find(by id: UUID) throws -> Asset? {
        let descriptor = FetchDescriptor<Asset>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }

    func add(_ asset: Asset) throws {
        context.insert(asset)
        try context.save()
    }

    func update(_ asset: Asset) throws {
        asset.updatedAt = Date()
        try context.save()
    }

    func delete(_ asset: Asset) throws {
        context.delete(asset)
        try context.save()
    }

    func bulkDelete(_ assets: [Asset]) throws {
        assets.forEach { context.delete($0) }
        try context.save()
    }

    func bulkUpdateStatus(_ assets: [Asset], status: AssetStatus) throws {
        assets.forEach { $0.status = status; $0.updatedAt = Date() }
        try context.save()
    }

    func upsertFromPayload(_ payload: AssetPayload) throws -> (asset: Asset, created: Bool) {
        let incoming = try payload.toAsset()
        let targetID = incoming.id
        let idPredicate = #Predicate<Asset> { asset in
            asset.id == targetID
        }
        if let existing = try context.fetch(FetchDescriptor<Asset>(predicate: idPredicate)).first {
            // 保持本地最新状态，避免扫码旧二维码时覆盖后台状态
            let currentStatus = existing.status
            existing.update(with: incoming)
            existing.status = currentStatus
            try context.save()
            return (existing, false)
        } else {
            context.insert(incoming)
            try context.save()
            return (incoming, true)
        }
    }
}
