import SwiftUI

struct SystemAbout: View {
    @StateObject private var viewModel = SystemAboutViewModel()
    @State private var urlCopyBounce = 0
    @State private var debugCopyTrigger = 0
    @State private var debugCopied = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                connectedInstanceCard

                if viewModel.isLoading {
                    LoadingSpinner()
                        .padding(.top, 40)
                } else if viewModel.systemInfo == nil, let message = viewModel.errorMessage {
                    ErrorStateView(message: message) {
                        viewModel.fetchSystemInfo()
                    }
                } else if let info = viewModel.systemInfo {
                    fireflyServerCard(info)
                    githubLink
                }

                appInfoCard
                copyDebugInfoButton
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear { viewModel.fetchSystemInfo() }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Connected instance

    private var connectedInstanceCard: some View {
        card(title: "CONNECTED INSTANCE") {
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(statusColor)
                Spacer()
            }

            HStack(spacing: 10) {
                Text(viewModel.connectedURL ?? "No server configured")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer(minLength: 8)

                if let url = viewModel.connectedURL {
                    Button {
                        UIPasteboard.general.string = url
                        urlCopyBounce += 1
                    } label: {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.accentColor)
                            .symbolEffect(.bounce, value: urlCopyBounce)
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.success, trigger: urlCopyBounce)
                    .accessibilityLabel("Copy server URL")
                }
            }
        }
    }

    private var statusColor: Color {
        guard !viewModel.isLoading else { return .secondary }
        return viewModel.systemInfo != nil ? .green : .red
    }

    private var statusText: String {
        if viewModel.isLoading { return "Checking connection…" }
        return viewModel.systemInfo != nil ? "Connected" : "Couldn’t connect"
    }

    // MARK: - Firefly server

    private func fireflyServerCard(_ info: SystemInfoDataClass) -> some View {
        card(title: "FIREFLY SERVER") {
            infoRow(icon: "tag.fill", label: "Firefly III Version", value: info.version)
            Divider()
            infoRow(icon: "terminal.fill", label: "PHP Version", value: info.phpVersion)
            Divider()
            infoRow(icon: "desktopcomputer", label: "OS", value: info.os)
            Divider()
            infoRow(icon: "externaldrive.fill", label: "Driver", value: info.driver)
        }
    }

    private var githubLink: some View {
        Link(destination: URL(string: "https://github.com/firefly-iii/firefly-iii")!) {
            HStack {
                Image(systemName: "link")
                Text("Firefly III on GitHub")
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .imageScale(.small)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color.accentColor.opacity(0.1))
            .foregroundStyle(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - App info

    private var appInfoCard: some View {
        card(title: "APP INFO") {
            infoRow(
                icon: "iphone",
                label: "Hotaru Version",
                value: "\(viewModel.appInfo.version) (\(viewModel.appInfo.build))"
            )
        }
    }

    private var copyDebugInfoButton: some View {
        Button {
            UIPasteboard.general.string = viewModel.debugInfoText
            debugCopyTrigger += 1
            withAnimation(.easeOut(duration: 0.15)) { debugCopied = true }
            doThisAfter(1.5) {
                withAnimation(.easeOut(duration: 0.15)) { debugCopied = false }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: debugCopied ? "checkmark" : "doc.on.clipboard")
                Text(debugCopied ? "Copied" : "Copy Debug Info")
            }
            .font(.system(size: 14.5, weight: .semibold))
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.accentColor.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: debugCopyTrigger)
    }

    // MARK: - Shared row/card building blocks

    private func infoRow(icon: String, label: String, value: String?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value ?? "-")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
    }

    private func card<Content: View>(
        title: String, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 12.5, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
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
        SystemAbout()
    }
}
