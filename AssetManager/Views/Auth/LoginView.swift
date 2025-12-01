import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var userId: String = ""
    @State private var password: String = ""
    @State private var enableFaceIDNext: Bool = false
    @State private var faceIDAvailable: Bool = LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("登录资产管家")
                    .font(.title2)
                TextField("用户 ID", text: $userId)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                SecureField("密码", text: $password)
                    .textFieldStyle(.roundedBorder)

                if faceIDAvailable {
                    Toggle("下次使用 FaceID 登录", isOn: $enableFaceIDNext)
                    if appState.faceIDEnabled {
                        Button {
                            Task { await appState.loginWithBiometrics() }
                        } label: {
                            Label("使用 FaceID 登录", systemImage: "faceid")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Button {
                    Task { await appState.login(userId: userId, password: password, enableFaceIDNext: enableFaceIDNext && faceIDAvailable) }
                } label: {
                    Label("登录", systemImage: "lock.open.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if let err = appState.authError {
                    Text(err).foregroundColor(.red).font(.caption)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("登录")
        }
    }
}
