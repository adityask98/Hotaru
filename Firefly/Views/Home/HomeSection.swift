import SwiftUI

/// One section title on the dashboard, optionally with a trailing accessory
/// (a "See all" link). Every section uses this so the page keeps a single
/// heading style and rhythm.
struct HomeSectionHeader<Accessory: View>: View {
    let title: String
    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            Spacer()
            accessory()
                .font(.subheadline)
        }
        .padding(.horizontal)
    }
}

extension HomeSectionHeader where Accessory == EmptyView {
    init(title: String) {
        self.init(title: title, accessory: { EmptyView() })
    }
}

/// The dashboard's standard card treatment.
struct HomeCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
    }
}

/// Compact inline error used inside a card, so a failed section doesn't take
/// over the page the way the full-screen `ErrorStateView` would.
struct HomeSectionError: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Retry", action: onRetry)
                .font(.subheadline)
                .buttonStyle(.bordered)
        }
    }
}

/// Placeholder shown while a section's first load is in flight.
struct HomeSectionLoading: View {
    var height: CGFloat = 60

    var body: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .frame(height: height)
    }
}
