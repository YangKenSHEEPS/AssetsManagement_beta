import SwiftUI

struct StartAuthView: View {
    @EnvironmentObject var appState: AppState
    @State private var showRegistration = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("资产管家")
                    .font(.largeTitle.bold())
                Text("请先注册账号以使用应用")
                    .foregroundColor(.secondary)
                Button {
                    showRegistration = true
                } label: {
                    Label("注册新账号", systemImage: "person.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if appState.hasRegistered {
                    NavigationLink {
                        LoginView()
                    } label: {
                        Label("已有账号？去登录", systemImage: "person.fill.checkmark")
                    }
                }
                Spacer()
            }
            .padding()
            .navigationTitle("开始")
            .sheet(isPresented: $showRegistration) {
                RegistrationView()
                    .environmentObject(appState)
            }
        }
    }
}
