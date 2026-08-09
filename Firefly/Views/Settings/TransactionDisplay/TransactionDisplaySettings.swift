import SwiftUI

struct TransactionDisplaySettings: View {
    @AppStorage(UserDefaultKeys.showSourceBalanceAfter) private var showSourceBalanceAfter = false
    @AppStorage(UserDefaultKeys.showDestinationBalanceAfter) private var showDestinationBalanceAfter = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                toggleRow(
                    icon: "arrow.up.right.circle.fill",
                    tint: .green,
                    title: "Source Balance After",
                    caption: "Show the source account's balance right after this transaction",
                    isOn: $showSourceBalanceAfter
                )
                toggleRow(
                    icon: "arrow.down.right.circle.fill",
                    tint: .blue,
                    title: "Destination Balance After",
                    caption: "Show the destination account's balance right after this transaction",
                    isOn: $showDestinationBalanceAfter
                )
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Transaction Display")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggleRow(
        icon: String, tint: Color, title: String, caption: String, isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(caption)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        )
    }
}

#Preview {
    NavigationStack {
        TransactionDisplaySettings()
    }
}
