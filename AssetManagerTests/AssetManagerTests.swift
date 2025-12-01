import XCTest
import SwiftData
@testable import AssetManager

final class AssetManagerTests: XCTestCase {
    @MainActor
    func testQRPayloadEncodingDecoding() throws {
        let asset = Asset(assetName: "测试资产", price: 100, purchaseDate: Date(), scrapYears: 3)
        let payload = AssetPayload(asset: asset)
        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(AssetPayload.self, from: data)
        XCTAssertEqual(payload.asset.assetName, decoded.asset.assetName)
        XCTAssertEqual(payload.asset.id, decoded.asset.id)
    }

    @MainActor
    func testDedupMerge() throws {
        let container = try ModelContainer(for: Asset.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let repo = AssetRepository(context: ModelContext(container))
        let asset = Asset(assetName: "设备A", price: 10, purchaseDate: Date(), scrapYears: 1)
        try repo.add(asset)

        var dto = AssetDTO(asset: asset)
        var payload = AssetPayload(schema: AssetPayload.schema, version: AssetPayload.version, asset: dto)
        var result = try repo.upsertFromPayload(payload)
        XCTAssertFalse(result.created)

        dto = AssetDTO(asset: Asset(id: UUID(), assetName: "新设备", price: 20, purchaseDate: Date(), scrapYears: 2))
        payload = AssetPayload(schema: AssetPayload.schema, version: AssetPayload.version, asset: dto)
        result = try repo.upsertFromPayload(payload)
        XCTAssertTrue(result.created)
    }
}
