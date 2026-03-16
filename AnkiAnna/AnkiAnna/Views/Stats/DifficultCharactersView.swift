import SwiftUI

struct DifficultCharactersView: View {
    let stats: [CharacterStats]

    private var difficultChars: [CharacterStats] {
        stats.filter { $0.practiceCount >= 3 && $0.errorRate > 0.3 }
            .sorted { $0.errorRate > $1.errorRate }
            .prefix(10)
            .map { $0 }
    }

    var body: some View {
        if difficultChars.isEmpty {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(DesignTokens.Colors.success)
                Text("暂无易错字，继续加油！")
                    .font(DesignTokens.Font.body)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
            }
            .padding(.vertical)
        } else {
            ForEach(difficultChars, id: \.id) { char in
                HStack(spacing: DesignTokens.Spacing.md) {
                    Text(char.character)
                        .font(DesignTokens.Font.promptText)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(char.words.prefix(2).joined(separator: "、"))
                            .font(DesignTokens.Font.caption)
                            .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("练习 \(char.practiceCount) 次")
                            .font(DesignTokens.Font.caption)
                            .foregroundStyle(DesignTokens.Colors.onSurfaceSecondary)
                        Text("错误率 \(Int(char.errorRate * 100))%")
                            .font(DesignTokens.Font.caption)
                            .foregroundStyle(DesignTokens.Colors.error)
                    }
                }
            }
        }
    }
}
