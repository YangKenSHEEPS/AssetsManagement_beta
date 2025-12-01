import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            Form {
                Section("账号") {
                    HStack {
                        Text("当前用户")
                        Spacer()
                        Text(appState.userId.isEmpty ? "未登录" : appState.userId)
                            .foregroundColor(.secondary)
                    }
                    Button(role: .destructive) {
                        appState.logout()
                    } label: {
                        Label("退出登录", systemImage: "rectangle.portrait.and.arrow.forward")
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
}
