import Foundation

@MainActor
final class AssetFormViewModel: ObservableObject {
    enum Mode {
        case create
        case edit(Asset)
    }

    @Published var assetName: String = ""
    @Published var price: String = ""
    @Published var purchaseDate: Date = Date()
    @Published var registerDate: Date = Date()
    @Published var scrapYears: Int = 3
    @Published var assetNumber: String = AssetNumberGenerator.generate()
    @Published var status: AssetStatus = .inUse
    @Published var category: String = ""
    @Published var location: String = ""
    @Published var owner: String = ""
    @Published var serialNumber: String = ""
    @Published var note: String = ""
    @Published var errorMessage: String?

    private let mode: Mode
    private let repository: AssetRepositoryType

    init(mode: Mode, repository: AssetRepositoryType) {
        self.mode = mode
        self.repository = repository
        if case .edit(let asset) = mode {
            assetName = asset.assetName
            price = String(asset.price)
            purchaseDate = asset.purchaseDate
            registerDate = asset.registerDate
            scrapYears = asset.scrapYears
            assetNumber = asset.assetNumber
            status = asset.status
            category = asset.category ?? ""
            location = asset.location ?? ""
            owner = asset.owner ?? ""
            serialNumber = asset.serialNumber ?? ""
            note = asset.note ?? ""
        }
    }

    func save() -> Asset? {
        guard !assetName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "资产名称必填"
            return nil
        }
        guard let priceValue = Double(price), priceValue >= 0 else {
            errorMessage = "价格必须是非负数字"
            return nil
        }
        guard scrapYears >= 0 else {
            errorMessage = "报废年限需为非负整数"
            return nil
        }

        switch mode {
        case .create:
            let asset = Asset(
                assetName: assetName,
                price: priceValue,
                purchaseDate: purchaseDate,
                registerDate: registerDate,
                scrapYears: scrapYears,
                assetNumber: assetNumber,
                status: status,
                category: category.isEmpty ? nil : category,
                location: location.isEmpty ? nil : location,
                owner: owner.isEmpty ? nil : owner,
                serialNumber: serialNumber.isEmpty ? nil : serialNumber,
                note: note.isEmpty ? nil : note
            )
            do {
                try repository.add(asset)
                return asset
            } catch {
                errorMessage = "保存失败：\(error.localizedDescription)"
                return nil
            }
        case .edit(let asset):
            asset.assetName = assetName
            asset.price = priceValue
            asset.purchaseDate = purchaseDate
            asset.registerDate = registerDate
            asset.scrapYears = scrapYears
            asset.assetNumber = assetNumber
            asset.status = status
            asset.category = category.isEmpty ? nil : category
            asset.location = location.isEmpty ? nil : location
            asset.owner = owner.isEmpty ? nil : owner
            asset.serialNumber = serialNumber.isEmpty ? nil : serialNumber
            asset.note = note.isEmpty ? nil : note
            do {
                try repository.update(asset)
                return asset
            } catch {
                errorMessage = "更新失败：\(error.localizedDescription)"
                return nil
            }
        }
    }
}
