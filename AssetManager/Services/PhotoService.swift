import Foundation
import Photos
import UIKit

enum PhotoSaveResult {
    case success
    case denied
    case error(Error)
}

final class PhotoService {
    func requestAuthorization() async -> PHAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    func save(image: UIImage) async -> PhotoSaveResult {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .notDetermined {
            let newStatus = await requestAuthorization()
            if newStatus != .authorized && newStatus != .limited {
                return .denied
            }
        } else if status != .authorized && status != .limited {
            return .denied
        }

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                if success {
                    continuation.resume(returning: .success)
                } else if let error {
                    continuation.resume(returning: .error(error))
                } else {
                    continuation.resume(returning: .error(NSError(domain: "photo.save", code: -1, userInfo: nil)))
                }
            }
        }
    }
}
