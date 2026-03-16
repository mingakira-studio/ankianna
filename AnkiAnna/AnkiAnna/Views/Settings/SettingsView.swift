import SwiftUI

struct SettingsView: View {
    @AppStorage("testModeEnabled") private var testModeEnabled = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = true

    var body: some View {
        NavigationStack {
            Form {
                Section("开发者") {
                    Toggle("测试模式", isOn: $testModeEnabled)
                    Text("开启后在写字界面显示「模拟写对/写错」按钮")
                        .font(DesignTokens.Font.caption)
                        .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
                }

                Section("通用") {
                    Button("重新播放引导") {
                        hasSeenOnboarding = false
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
}
