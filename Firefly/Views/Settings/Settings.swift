import SwiftUI

struct Settings: View {
    @StateObject private var settings = SettingsViewModel()
    @State private var showTokenSheet = false
    @State private var showPaginationInfo = false
    @State private var showLocationInfo = false
    @AppStorage(UserDefaultKeys.undoTimeoutSeconds) private var undoTimeoutSeconds =
        PendingDeleteManager.defaultTimeoutSeconds
    @AppStorage(UserDefaultKeys.paginationEnabled) private var paginationEnabled = true
    @AppStorage(UserDefaultKeys.attachLocationToTransactions) private var attachLocation = true
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
                                shown on a map later. Firefly III has no supported way to save a \
                                location, so Hotaru stores it as an extra line inside the \
                                transaction's notes and hides that line from you. Other Firefly \
                                clients and the web interface will show it as plain text. Expect \
                                this to change once Firefly III supports locations properly.
                                """)
                            }
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
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showTokenSheet) {
                TokenSettings()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(24)
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            }
        }
    }
}

#Preview {
    Settings()
}
