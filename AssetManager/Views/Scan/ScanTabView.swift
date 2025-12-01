import SwiftUI
import AVFoundation
import UIKit

struct ScanTabView: View {
    @StateObject var viewModel: ScanViewModel
    @State private var authorized = false
    @State private var showSettings = false
    @State private var navigate = false

    var body: some View {
        NavigationStack {
            ZStack {
                if authorized {
                    ScanCameraView { text in
                        viewModel.handleScanned(text: text)
                        if viewModel.parsedAsset != nil {
                            navigate = true
                        }
                    }
                    .overlay(alignment: .center) {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.green, lineWidth: 2)
                            .frame(width: 260, height: 260)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 48))
                        Text("需要相机权限以扫码")
                        Button("前往设置") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("扫码")
            .navigationDestination(isPresented: $navigate) {
                if let asset = viewModel.parsedAsset {
                    ScanResultView(asset: asset, isNew: viewModel.didCreate) {
                        navigate = false
                        viewModel.parsedAsset = nil
                    }
                }
            }
            .alert("提示", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.errorMessage = nil })
            ) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task { await requestPermission() }
        }
    }

    private func requestPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            authorized = true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            authorized = granted
        default:
            authorized = false
        }
    }
}
