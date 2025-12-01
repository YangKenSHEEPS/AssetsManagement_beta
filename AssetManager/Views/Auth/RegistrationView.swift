import SwiftUI
import LocalAuthentication

struct RegistrationView: View {
    @EnvironmentObject var appState: AppState
    @State private var userId: String = ""
    @State private var enableFaceID: Bool = false
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var faceIDAvailable: Bool = LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("欢迎使用资产管家")
                    .font(.title)
                TextField("请输入用户 ID（必填）", text: $userId)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                SecureField("请输入密码（必填）", text: $password)
                    .textFieldStyle(.roundedBorder)
                SecureField("请再次确认密码", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)

                if faceIDAvailable {
                    Toggle("启用 FaceID 进入应用", isOn: $enableFaceID)
                } else {
                    Text("设备不支持 FaceID/TouchID")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button {
                    Task { await appState.register(userId: userId, password: password, confirm: confirmPassword, enableFaceID: enableFaceID && faceIDAvailable) }
                } label: {
                    Label("注册并进入", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if let error = appState.authError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("注册")
        }
    }
}
