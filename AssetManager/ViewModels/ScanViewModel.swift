import Foundation

@MainActor
final class ScanViewModel: ObservableObject {
    @Published var parsedAsset: Asset?
    @Published var errorMessage: String?
    @Published var didCreate: Bool = false
    @Published var selectedAsset: Asset?

    private let repository: AssetRepositoryType
    private let qrService: QRService

    init(repository: AssetRepositoryType, qrService: QRService = QRService()) {
        self.repository = repository
        self.qrService = qrService
    }

    func handleScanned(text: String) {
        do {
            let payload = try qrService.decode(from: text)
            // 若资产未登记则提示，不自动创建
            guard let _ = try repository.find(by: payload.asset.id) else {
                errorMessage = "资产不存在，请先在后台登记"
                parsedAsset = nil
                return
            }

            let result = try repository.upsertFromPayload(payload)
            if let refreshed = try repository.find(by: payload.asset.id) {
                parsedAsset = refreshed
            } else {
                parsedAsset = result.asset
            }
            didCreate = false
        } catch let error as QRCodeError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "解析失败：\(error.localizedDescription)"
        }
    }
}
