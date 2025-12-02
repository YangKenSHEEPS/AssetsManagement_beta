import Foundation
import SwiftData

enum AssetStatus: String, Codable, CaseIterable, Identifiable {
    case inUse
    case retired
    case maintenance
    case idle

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .inUse: return NSLocalizedString("在用", comment: "status")
        case .retired: return NSLocalizedString("报废", comment: "status")
        case .maintenance: return NSLocalizedString("维修", comment: "status")
        case .idle: return NSLocalizedString("闲置", comment: "status")
        }
    }
}

@Model
final class Asset {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var assetNumber: String
    var assetName: String
    var price: Double
    var purchaseDate: Date
    var registerDate: Date
    var scrapYears: Int
    var status: AssetStatus
    var category: String?
    var location: String?
    var owner: String?
    var serialNumber: String?
    var note: String?
    var attachments: [String]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        assetName: String,
        price: Double,
        purchaseDate: Date,
        registerDate: Date = Date(),
        scrapYears: Int,
        assetNumber: String = AssetNumberGenerator.generate(),
        status: AssetStatus = .inUse,
        category: String? = nil,
        location: String? = nil,
        owner: String? = nil,
        serialNumber: String? = nil,
        note: String? = nil,
        attachments: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.assetNumber = assetNumber
        self.assetName = assetName
        self.price = price
        self.purchaseDate = purchaseDate
        self.registerDate = registerDate
        self.scrapYears = scrapYears
        self.status = status
        self.category = category
        self.location = location
        self.owner = owner
        self.serialNumber = serialNumber
        self.note = note
        self.attachments = attachments
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func update(with other: Asset) {
        assetName = other.assetName
        price = other.price
        purchaseDate = other.purchaseDate
        registerDate = other.registerDate
        scrapYears = other.scrapYears
        status = other.status
        category = other.category
        location = other.location
        owner = other.owner
        serialNumber = other.serialNumber
        note = other.note
        attachments = other.attachments
        updatedAt = Date()
    }
}

struct AssetFilter: Equatable {
    var keyword: String = ""
    var status: AssetStatus?
    var category: String?
    var startDate: Date?
    var endDate: Date?
    var sort: SortOption = .registerDateDesc

    enum SortOption: String, CaseIterable, Identifiable {
        case registerDateDesc, registerDateAsc, priceDesc, priceAsc, purchaseDateDesc, purchaseDateAsc, updatedDesc

        var id: String { rawValue }

        var title: String {
            switch self {
            case .registerDateDesc: return NSLocalizedString("登记时间↓", comment: "sort")
            case .registerDateAsc: return NSLocalizedString("登记时间↑", comment: "sort")
            case .priceDesc: return NSLocalizedString("价格↓", comment: "sort")
            case .priceAsc: return NSLocalizedString("价格↑", comment: "sort")
            case .purchaseDateDesc: return NSLocalizedString("购买时间↓", comment: "sort")
            case .purchaseDateAsc: return NSLocalizedString("购买时间↑", comment: "sort")
            case .updatedDesc: return NSLocalizedString("更新时间↓", comment: "sort")
            }
        }
    }
}

// MARK: - QR Payload

struct AssetPayload: Codable, Equatable {
    static let schema = "asset_qr"
    static let version = 1

    let schema: String
    let version: Int
    let asset: AssetDTO

    init(asset: Asset) {
        self.schema = Self.schema
        self.version = Self.version
        self.asset = AssetDTO(asset: asset)
    }

    init(schema: String, version: Int, asset: AssetDTO) {
        self.schema = schema
        self.version = version
        self.asset = asset
    }

    func toAsset() throws -> Asset {
        guard schema == Self.schema else {
            throw QRCodeError.invalidSchema
        }
        guard version == Self.version else {
            throw QRCodeError.unsupportedVersion
        }
        return try asset.toModel()
    }
}

struct AssetDTO: Codable, Equatable {
    let id: UUID
    let assetName: String
    let price: Double
    let purchaseDateISO: String
    let registerDateISO: String
    let scrapYears: Int
    let assetNumber: String
    let status: AssetStatus
    let category: String?
    let location: String?
    let owner: String?
    let serialNumber: String?
    let note: String?

    init(asset: Asset) {
        id = asset.id
        assetName = asset.assetName
        price = asset.price
        purchaseDateISO = ISO8601DateFormatter().string(from: asset.purchaseDate)
        registerDateISO = ISO8601DateFormatter().string(from: asset.registerDate)
        scrapYears = asset.scrapYears
        assetNumber = asset.assetNumber
        status = asset.status
        category = asset.category
        location = asset.location
        owner = asset.owner
        serialNumber = asset.serialNumber
        note = asset.note
    }

    func toModel() throws -> Asset {
        let formatter = ISO8601DateFormatter()
        guard let purchaseDate = formatter.date(from: purchaseDateISO),
              let registerDate = formatter.date(from: registerDateISO) else {
            throw QRCodeError.invalidDate
        }
        return Asset(
            id: id,
            assetName: assetName,
            price: price,
            purchaseDate: purchaseDate,
            registerDate: registerDate,
            scrapYears: scrapYears,
            assetNumber: assetNumber.isEmpty ? AssetNumberGenerator.generate() : assetNumber,
            status: status,
            category: category,
            location: location,
            owner: owner,
            serialNumber: serialNumber,
            note: note
        )
    }
}

enum QRCodeError: Error, LocalizedError {
    case invalidSchema
    case unsupportedVersion
    case invalidDate
    case invalidPayload

    var errorDescription: String? {
        switch self {
        case .invalidSchema: return "不是资产二维码"
        case .unsupportedVersion: return "二维码版本不兼容"
        case .invalidDate: return "日期字段无效"
        case .invalidPayload: return "二维码内容损坏"
        }
    }
}
