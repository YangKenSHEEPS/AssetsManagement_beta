import Foundation
import CoreImage.CIFilterBuiltins
import UIKit

struct QRService {
    private let context = CIContext()

    func makePayload(for asset: Asset) -> AssetPayload {
        AssetPayload(asset: asset)
    }

    func decode(from string: String) throws -> AssetPayload {
        let data = Data(string.utf8)
        do {
            return try JSONDecoder().decode(AssetPayload.self, from: data)
        } catch {
            throw QRCodeError.invalidPayload
        }
    }

    func generateImage(from payload: AssetPayload, size: CGSize = .init(width: 320, height: 320)) throws -> UIImage {
        let data = try JSONEncoder().encode(payload)
        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else {
            throw QRCodeError.invalidPayload
        }
        qrFilter.setValue(data, forKey: "inputMessage")
        qrFilter.setValue("M", forKey: "inputCorrectionLevel")

        guard let outputImage = qrFilter.outputImage else {
            throw QRCodeError.invalidPayload
        }

        // Scale QR to readable size
        let scaleX = size.width / outputImage.extent.size.width
        let scaleY = size.height / outputImage.extent.size.height
        let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else {
            throw QRCodeError.invalidPayload
        }
        return UIImage(cgImage: cgImage)
    }
}
