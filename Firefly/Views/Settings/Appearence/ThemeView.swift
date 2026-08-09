import SwiftUI

enum ThemeMode: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"

    var icon: String {
        switch self {
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        case .system: "circle.righthalf.filled"
        }
    }

    var iconTint: Color {
        switch self {
        case .light: .orange
        case .dark: .indigo
        case .system: .secondary
        }
    }

    var caption: String {
        switch self {
        case .light: "Always light"
        case .dark: "Always dark"
        case .system: "Matches your device setting"
        }
    }
}

struct ThemeView: View {
    @AppStorage(UserDefaultKeys.selectedTheme) private var selectedTheme: ThemeMode = .system

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(ThemeMode.allCases, id: \.self) { theme in
                    themeRow(theme)
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .sensoryFeedback(.selection, trigger: selectedTheme)
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func themeRow(_ theme: ThemeMode) -> some View {
        let selected = selectedTheme == theme
        return Button {
            withAnimation(.easeOut(duration: 0.15)) {
                selectedTheme = theme
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(theme.iconTint.opacity(selected ? 0.18 : 0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: theme.icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(theme.iconTint)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(theme.caption)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 21))
                    .foregroundStyle(selected ? Color.accentColor : Color(.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        selected ? Color.accentColor.opacity(0.6) : Color.primary.opacity(0.06),
                        lineWidth: selected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

#Preview {
    NavigationStack {
        ThemeView()
    }
}
