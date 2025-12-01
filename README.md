# 资产管家 (iOS 17 / Swift 5.9 / SwiftUI)

一款本地化的资产管理 App：录入资产→生成二维码→保存/分享→扫码识别并落库；内置后台管理（列表、搜索、筛选、批量、导出、仪表盘）。

## 功能亮点
- 资产录入/编辑：必填校验、价格小数、日期选择、报废年限 Stepper。
- 二维码闭环：CoreImage 生成 QR（JSON Schema），预览/保存相册/分享；AVFoundation 实时扫码并解析。
- 去重合并：按资产 UUID 去重，扫码导入已存在则更新；未登记的资产扫码会提示“资产不存在”，不会自动创建；缺失/错误字段有中文错误提示。
- 资产编号：新增资产时自动生成唯一编号（示例：AM-YYYYMMDD-xxxx），在资产详情/列表展示。
- 数据持久化：SwiftData @Model，字段覆盖资产名称、价格、时间、分类、负责人、位置、备注等，自动维护 createdAt/updatedAt。
- 后台管理：搜索/筛选/排序，批量删除/报废，仪表盘统计（Charts），CSV/JSON 导出并系统分享。
- 安全：后台入口支持 FaceID/TouchID 解锁。
- 权限兜底：相机、相册写入权限弹窗及拒绝提示。
- 启动认证：首次进入需注册用户 ID，可选开启 FaceID；已开启 FaceID 的用户再次进入需生物识别通过。
- 登录逻辑：注册需填写 ID+密码（确认），登录默认使用账号密码，可选启用/使用 FaceID。

## 架构
- **UI**：SwiftUI + 少量 UIKit (扫码相机)。
- **分层**：Models（SwiftData @Model）、Repositories（数据读写）、Services（二维码/照片/导出/认证）、ViewModels（MVVM 状态与业务）、Views。
- **可扩展**：AssetRepositoryType/ExportService/AuthService 等接口化，方便未来接入远端 API 或替换实现。

## 工程结构
```
AssetManager.xcodeproj
AssetManager/
  App.swift
  Models/Asset.swift
  Repositories/AssetRepository.swift
  Services/{QRService,PhotoService,ExportService,AuthService}.swift
  ViewModels/*.swift
  Views/
    Assets/{AssetListView,AssetDetailView,AssetFormView}.swift
    Scan/{ScanTabView,ScanCameraView,ScanResultView}.swift
    QR/QRPreviewView.swift
    Admin/AdminHomeView.swift
  Resources/Assets.xcassets (含 AppIcon)
  Supporting/Info.plist
AssetManagerTests/AssetManagerTests.swift
README.md
```

## 权限
- 相机（NSCameraUsageDescription）：用于扫码资产二维码。
- 相册写入（NSPhotoLibraryAddUsageDescription/NSPhotoLibraryUsageDescription）：保存二维码图片。
- FaceID/TouchID（NSFaceIDUsageDescription）：进入后台管理时验证。

## 运行方式
1. Xcode 15+ 打开 `AssetManager.xcodeproj`，选择 iOS 17+ 模拟器或真机。
2. 首次进入“扫码”或保存二维码会弹出权限请求，请允许。
3. 测试：`⌘+U` 或在 Xcode Test navigator 运行 `AssetManagerTests`.

## 二维码 Schema
```json
{
  "schema": "asset_qr",
  "version": 1,
  "asset": {
    "id": "UUID",
    "assetName": "...",
    "price": 1234.5,
    "purchaseDateISO": "2024-01-01T12:00:00Z",
    "registerDateISO": "2024-01-02T00:00:00Z",
    "scrapYears": 5,
    "status": "inUse",
    "category": "...",
    "location": "...",
    "owner": "...",
    "serialNumber": "...",
    "note": "..."
  }
}
```
- `schema` 必须为 `asset_qr`，`version` 当前为 1。二维码解析时会校验 schema/version，异常返回“不是资产二维码/版本不兼容”。
- 日期使用 ISO8601 字符串；字段缺失/类型错误会提示“二维码内容损坏”。
- 未实现签名/加密（保持轻量离线）；若需防篡改，可在未来用 CryptoKit 加 HMAC 并在 payload 增加 `signature` 字段，在 README “Next Steps” 留出说明。

## 常见问题
- **权限被拒**：在系统设置 > 隐私 中开启相机/照片权限。
- **二维码无法识别**：确认二维码是本应用生成且 schema/version 符合；否则会提示原因。
- **去重规则**：按资产 UUID；扫码发现本地已有则更新，否则新增。

## 测试说明
- `testQRPayloadEncodingDecoding`：验证 QR payload 编码/解码一致性。
- `testDedupMerge`：验证扫描导入时的去重合并逻辑（存在则更新，不存在则新增）。

## Next Steps（可选增强）
- 二维码签名/校验（CryptoKit HMAC）。
- 附件图片/发票照片存储与预览。
- 从文件导入 JSON 备份、增量合并。
- 资产状态流转历史记录与操作日志。
