import Foundation
import LocalAuthentication

@MainActor
final class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var hasRegistered: Bool = false
    @Published var faceIDEnabled: Bool = false
    @Published var userId: String = ""
    @Published var authError: String?
    @Published var loginMessage: String?

    private let userDefaults = UserDefaults.standard
    private let authService = AuthService()
    private let keychain = KeychainService()

    private enum Keys {
        static let userId = "app.user.id"
        static let faceIDEnabled = "app.user.faceid.enabled"
    }

    init() {
        load()
    }

    func load() {
        userId = userDefaults.string(forKey: Keys.userId) ?? ""
        faceIDEnabled = userDefaults.bool(forKey: Keys.faceIDEnabled)
        hasRegistered = !userId.isEmpty
        isAuthenticated = false
    }

    func register(userId: String, password: String, confirm: String, enableFaceID: Bool) async {
        let trimmed = userId.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            authError = "用户 ID 不能为空"
            return
        }
        guard !password.isEmpty else {
            authError = "密码不能为空"
            return
        }
        guard password == confirm else {
            authError = "两次输入的密码不一致"
            return
        }
        self.userId = trimmed
        userDefaults.set(trimmed, forKey: Keys.userId)
        do {
            try keychain.savePassword(password, account: trimmed)
        } catch {
            authError = "保存密码失败"
            return
        }

        if enableFaceID {
            let ok = await authService.authenticate(reason: "使用 FaceID 进入资产管家")
            if ok {
                userDefaults.set(true, forKey: Keys.faceIDEnabled)
                faceIDEnabled = true
                isAuthenticated = true
            } else {
                authError = "FaceID 验证失败，可稍后在设置中开启"
                faceIDEnabled = false
                isAuthenticated = true
            }
        } else {
            userDefaults.set(false, forKey: Keys.faceIDEnabled)
            faceIDEnabled = false
            isAuthenticated = true
        }
        hasRegistered = true
    }

    func login(userId: String, password: String, enableFaceIDNext: Bool) async {
        let trimmed = userId.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            authError = "用户 ID 不能为空"
            return
        }
        guard !password.isEmpty else {
            authError = "密码不能为空"
            return
        }
        do {
            let ok = try keychain.verifyPassword(password, account: trimmed)
            guard ok else {
                authError = "账号或密码错误"
                isAuthenticated = false
                return
            }
        } catch {
            authError = "读取密码失败"
            isAuthenticated = false
            return
        }
        self.userId = trimmed
        userDefaults.set(trimmed, forKey: Keys.userId)
        hasRegistered = true
        if enableFaceIDNext {
            let ok = await authService.authenticate(reason: "启用 FaceID 登录")
            userDefaults.set(ok, forKey: Keys.faceIDEnabled)
            faceIDEnabled = ok
        } else {
            userDefaults.set(false, forKey: Keys.faceIDEnabled)
            faceIDEnabled = false
        }
        isAuthenticated = true
        authError = nil
    }

    func loginWithBiometrics() async {
        guard hasRegistered, faceIDEnabled else { return }
        let ok = await authService.authenticate(reason: "使用 FaceID 登录资产管家")
        if ok {
            isAuthenticated = true
            authError = nil
        } else {
            authError = "FaceID 验证失败"
            isAuthenticated = false
        }
    }

    func tryBiometricAuthIfNeeded() async {
        guard hasRegistered, faceIDEnabled else {
            isAuthenticated = hasRegistered
            return
        }
        let ok = await authService.authenticate(reason: "使用 FaceID 进入资产管家")
        if ok {
            isAuthenticated = true
        } else {
            authError = "FaceID 验证失败"
            isAuthenticated = false
        }
    }

    func logout() {
        isAuthenticated = false
    }
}
