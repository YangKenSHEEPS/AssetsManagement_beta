import Foundation

enum ExportError: Error, LocalizedError {
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .writeFailed: return "导出失败，请重试"
        }
    }
}

struct ExportService {
    func exportCSV(_ assets: [Asset]) throws -> URL {
        let header = [
            "id","名称","价格","购买时间","登记时间","报废年限","状态","分类","位置","负责人","序列号","备注"
        ].joined(separator: ",")

        let formatter = ISO8601DateFormatter()
        let rows = assets.map { asset in
            [
                asset.id.uuidString,
                asset.assetName,
                String(format: "%.2f", asset.price),
                formatter.string(from: asset.purchaseDate),
                formatter.string(from: asset.registerDate),
                "\(asset.scrapYears)",
                asset.status.displayName,
                asset.category ?? "",
                asset.location ?? "",
                asset.owner ?? "",
                asset.serialNumber ?? "",
                asset.note?.replacingOccurrences(of: ",", with: ";") ?? ""
            ].joined(separator: ",")
        }
        let csv = ([header] + rows).joined(separator: "\n")
        return try writeTempFile(name: "assets.csv", data: Data(csv.utf8))
    }

    func exportJSON(_ assets: [Asset]) throws -> URL {
        let payloads = assets.map { AssetDTO(asset: $0) }
        let data = try JSONEncoder().encode(payloads)
        return try writeTempFile(name: "assets-backup.json", data: data)
    }

    private func writeTempFile(name: String, data: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            throw ExportError.writeFailed
        }
    }
}
