import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct QRPreviewView: View {
    let asset: Asset
    @ObservedObject var viewModel: AssetDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let image = viewModel.qrImage {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 240, height: 240)
                        .padding()

                    ShareLink(item: QRImageItem(image: image), preview: SharePreview(asset.assetName, image: Image(uiImage: image))) {
                        Label("分享二维码", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        Task { await viewModel.saveToPhotos() }
                    } label: {
                        Label("保存到相册", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    ProgressView()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(asset.assetName).font(.headline)
                    Text("价格：￥\(asset.price, specifier: "%.2f")")
                    Text("登记：\(asset.registerDate.formatted(date: .abbreviated, time: .omitted))")
                    Text("状态：\(asset.status.displayName)")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
            .padding()
            .navigationTitle("二维码预览")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { dismiss() }
                }
            }
            .onAppear { if viewModel.qrImage == nil { viewModel.generateImage() } }
        }
    }
}

struct QRImageItem: Transferable {
    let image: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            item.image.pngData() ?? Data()
        }
    }
}
