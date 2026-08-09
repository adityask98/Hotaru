import SwiftUI

struct BudgetsView: View {
    @Environment(\.openURL) var openURL

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {}
            }
        }
        .navigationTitle("Budgets")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Open Webview", systemImage: "safari") {
                        SafariBuilder(apiURL: WebviewPaths.budgets(), openURL: openURL)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel("More options")
            }
        }
    }
}

// #Preview {
//    BudgetsView()
// }
