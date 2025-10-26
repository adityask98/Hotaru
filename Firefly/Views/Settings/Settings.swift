import SwiftUI

struct Settings: View {
    @StateObject private var settings = SettingsViewModel()
    @State private var startTime = Date.now
    @State private var showTokenSheet = false
    var body: some View {
        NavigationStack {
            TimelineView(.animation) { _ in
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
                            NavigationLink(destination: ThemeView()) {
                                HStack {
                                    Image(systemName: "paintpalette.fill")
                                    Text("Theme")
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
}

#Preview {
    Settings()
}
