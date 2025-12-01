import Foundation
import UIKit

@MainActor
final class AssetDetailViewModel: ObservableObject {
    @Published var qrImage: UIImage?
    @Published var showShareSheet = false
    @Published var message: String?

    private let asset: Asset
    private let qrService: QRService
    private let photoService: PhotoService
    private let repository: AssetRepositoryType

    init(asset: Asset, repository: AssetRepositoryType, qrService: QRService = QRService(), photoService: PhotoService = PhotoService()) {
        self.asset = asset
        self.repository = repository
        self.qrService = qrService
        self.photoService = photoService
    }

    func payload() -> AssetPayload {
        qrService.makePayload(for: asset)
    }

    func generateImage() {
        do {
            qrImage = try qrService.generateImage(from: payload())
        } catch {
            message = "生成二维码失败：\(error.localizedDescription)"
        }
    }

    func saveToPhotos() async {
        guard let image = qrImage else { return }
        let result = await photoService.save(image: image)
        switch result {
        case .success:
            message = "已保存到相册"
        case .denied:
            message = "没有相册写入权限，请在系统设置开启"
        case .error(let error):
            message = "保存失败：\(error.localizedDescription)"
        }
    }

    func updateStatus(_ status: AssetStatus) {
        asset.status = status
        asset.updatedAt = Date()
        do {
            try repository.update(asset)
        } catch {
            message = "状态更新失败：\(error.localizedDescription)"
        }
    }
}
