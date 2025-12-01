import Foundation

struct AssetNumberGenerator {
    /// 生成唯一资产编号：AM-年月日-随机4位
    static func generate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let datePart = formatter.string(from: Date())
        let random = String(format: "%04d", Int.random(in: 0...9999))
        return "AM-\(datePart)-\(random)"
    }
}
