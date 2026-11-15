import SwiftUI

struct Settings: View {
    @StateObject private var settings = SettingsViewModel()
    @State private var showTokenSheet = false
    @State private var showPaginationInfo = false
    @State private var showLocationInfo = false
    @State private var showLocationNotesInfo = false
    @AppStorage(UserDefaultKeys.undoTimeoutSeconds) private var undoTimeoutSeconds =
        PendingDeleteManager.defaultTimeoutSeconds
    @AppStorage(UserDefaultKeys.paginationEnabled) private var paginationEnabled = true
    @AppStorage(UserDefaultKeys.attachLocationToTransactions) private var attachLocation = true
    @AppStorage(UserDefaultKeys.writeLocationToNotes) private var writeLocationToNotes = false
    @AppStorage(UserDefaultKeys.minimizeTabBarOnScroll) private var minimizeTabBarOnScroll = true
    @AppStorage(UserDefaultKeys.hideTabTitles) private var hideTabTitles = true
    var body: some View {
        NavigationStack {
            List {
                Group {
                    Section {
                        NavigationLink(destination: CategoriesView()) {
                            HStack {
                                Image(systemName: "tray.full.fill")
                                Text("Categories")
                                Spacer()
                            }
                        }
                        NavigationLink {
                            BudgetsView()
                        } label: {
                            HStack {
                                Image(systemName: "chart.line.text.clipboard.fill")
                                Text("Budgets")
                                Spacer()
                            }
                        }

                        NavigationLink(destination: ThemeView()) {
                            HStack {
                                Image(systemName: "paintpalette.fill")
                                Text("Theme")
                                Spacer()
                            }
                        }
                        NavigationLink(destination: TransactionDisplaySettings()) {
                            HStack {
                                Image(systemName: "slider.horizontal.3")
                                Text("Transaction Display")
                                Spacer()
                            }
                        }
                        Button {
                            showTokenSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "key.horizontal.fill")
                                Text("Credentials")
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                        NavigationLink(destination: SystemAbout()) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                Text("About")
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        Toggle(isOn: $settings.webviewsInline, label: { Text("Open Webviews inline") })
                        HStack {
                            Toggle(isOn: $paginationEnabled, label: { Text("Load more on scroll") })
                            Button {
                                showPaginationInfo = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Why disable load more on scroll")
                            .alert("Load more on scroll", isPresented: $showPaginationInfo) {
                                Button("OK", role: .cancel) {}
                            } message: {
                                Text("""
                                Some self-hosted Firefly III servers report the wrong web address \
                                (http instead of https) when the app asks for more transactions, \
                                which can make "load more" fail with an authentication error. \
                                Turn this off to only load a single page of transactions until \
                                your server's reverse proxy configuration is fixed.
                                """)
                            }
                        }
                        HStack {
                            Toggle(isOn: $attachLocation) {
                                HStack(spacing: 6) {
                                    Text("Attach location")
                                    Image(systemName: "testtube.2")
                                        .foregroundStyle(.orange)
                                        .accessibilityLabel("Beta feature")
                                }
                            }
                            Button {
                                showLocationInfo = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("About attaching location to transactions")
                            .alert("Attach location (beta)", isPresented: $showLocationInfo) {
                                Button("OK", role: .cancel) {}
                            } message: {
                                Text("""
                                Records where you are when you create a transaction, so it can be \
                                shown on a map later. The location is saved in Firefly III itself, \
                                so the web interface shows it on the transaction's map too.
                                """)
                            }
                        }
                        HStack {
                            Toggle(isOn: $writeLocationToNotes) {
                                Text("Also save location in notes")
                            }
                            .disabled(!attachLocation)
                            Button {
                                showLocationNotesInfo = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("About saving location in notes")
                            .alert("Save location in notes", isPresented: $showLocationNotesInfo) {
                                Button("OK", role: .cancel) {}
                            } message: {
                                Text("""
                                Also writes the location as an extra line at the end of the \
                                transaction's notes. Hotaru hides that line, but the web \
                                interface and other apps show it as plain text.

                                Turn this on if your server runs Firefly III older than 6.7.0: \
                                those versions save a location when a transaction is created but \
                                drop it when it's edited, and the notes line keeps it safe. It \
                                also keeps the place name and accuracy, which Firefly III doesn't \
                                store.

                                Transactions that already have the line always show their \
                                location, whether this is on or off.
                                """)
                            }
                        }
                        NavigationLink(destination: LocationMigrationView()) {
                            Text("Move locations out of notes")
                        }
                        Picker(selection: $undoTimeoutSeconds) {
                            Text("3 seconds").tag(3)
                            Text("5 seconds").tag(5)
                            Text("10 seconds").tag(10)
                            Text("15 seconds").tag(15)
                        } label: {
                            HStack {
                                Image(systemName: "arrow.uturn.backward.circle.fill")
                                Text("Undo timeout")
                            }
                        }
                    }

                    Section("Tab Bar") {
                        Toggle("Minimize tab bar on scroll", isOn: $minimizeTabBarOnScroll)
                        Toggle("Hide tab titles", isOn: $hideTabTitles)
                    }

                    Section {
                        Button {
                            Task { await settings.exportAllTransactions() }
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up.fill")
                                Text("Export all transactions")
                                Spacer()
                                if settings.isExportingTransactions {
                                    ProgressView()
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(settings.isExportingTransactions)
                    } footer: {
                        Text("""
                        Downloads every transaction as a CSV file, the same file as \
                        "Export all transactions" in the Firefly III web interface.
                        """)
                    }
                }

                //                    VStack {
                //                        Text("All the umbrellas")
                //                            .multilineTextAlignment(.center)
                //                            .font(Font.system(.title))
                //                            .fontWeight(.ultraLight)
                //                            .foregroundColor(.white)
                //                    }
                //                    .frame(width: 350, height: 350)
                //                    .background(
                //                        RoundedRectangle(
                //                            cornerRadius: /*@START_MENU_TOKEN@*/ 25.0 /*@END_MENU_TOKEN@*/
                //                        )
                //                        .fill(.grainGradient(time: elapsedTime)))
            }
            .navigationTitle("Settings")
            .transactionNavigationDestination()
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showTokenSheet) {
                TokenSettings()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(24)
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            }
            .sheet(item: $settings.exportedTransactions) { file in
                ActivityView(items: [file.url])
                    .presentationDetents([.medium, .large])
                    .ignoresSafeArea()
            }
            .alert(
                "Couldn't export transactions",
                isPresented: Binding(
                    get: { settings.exportErrorMessage != nil },
                    set: {
                        if !$0 {
                            settings.exportErrorMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(settings.exportErrorMessage ?? "")
            }
        }
        .transactionNavigationScope()
    }
}

/// The system share sheet for an already-downloaded file. `ShareLink` needs its item before it's
/// tapped, but the export file only exists once the download finishes, so this is presented after.
private struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context _: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}

#Preview {
    Settings()
}
