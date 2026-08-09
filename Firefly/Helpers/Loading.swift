import SwiftUI

struct LoadingSpinner: View {
    var body: some View {
        Spacer()
        HStack(alignment: .center) {
            Spacer()
            ProgressView()
            Spacer()
        }
        Spacer()
    }
}

/// Shared empty state for lists with no content
struct EmptyStateView: View {
    var icon = "tray"
    var message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
        .accessibilityElement(children: .combine)
    }
}

/// Shared error state with a retry button, used by list screens
struct ErrorStateView: View {
    var message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
                .padding(.bottom, 4)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                onRetry()
            }
            .buttonStyle(.bordered)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

#Preview {
    LoadingSpinner()
}

#Preview("Error") {
    ErrorStateView(message: "Couldn't load transactions.", onRetry: {})
}
