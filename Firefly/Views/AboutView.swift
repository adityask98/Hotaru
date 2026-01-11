import SwiftUI

struct AboutView: View {
    @ObservedObject private var user = UserModel()
    @State private var transactions = TransactionsViewModel()
    @EnvironmentObject var menuViewModel: MenuViewModel
    @State private var refreshTrigger = UUID()

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], alignment: .center, spacing: 10
                ) {
                    ShortcutItem(
                        name: "Categories",
                        icon: "tray.full.fill",
                        destination: AnyView(CategoriesView())
                    )
                    ShortcutItem(
                        name: "Budgets",
                        icon: "chart.line.text.clipboard.fill",
                        destination: AnyView(BudgetsView())
                    )
                }
                .padding(.horizontal)
                VStack(alignment: .leading, spacing: 24) {
                    CategoriesBarChart(refreshTrigger: refreshTrigger)
                    CategoriesDonut(refreshTrigger: refreshTrigger)
                }
            }
            .refreshable {
                await refreshAllData()
            }

            // .frame(width: .infinity, height: .infinity)
            .task {
                do {
                    try await user.getUser()
                } catch {
                    print(error)
                }
            }

            .navigationTitle("Home")
            //      .toolbar {
            //        Button(action: {
            //          menuViewModel.openSearchSheet()
            //        }) {
            //          Image(systemName: "magnifyingglass.circle.fill")
            //            .padding(6)
            //            .fontWeight(.heavy)
            //        }
            //      }
            //      //            .navigationBarItems(leading: Text("Analytics").font(.subheadline))
            //            .navigationTitle("Home")
            //            .navigationBarTitleDisplayMode(.large)
        }
        .overlay(alignment: .bottomTrailing) {
            FloatingButton(action: {
                menuViewModel.openTransactionSheet()
            })
        }
        .background(.ultraThinMaterial)
    }

    private func refreshAllData() async {
        refreshTrigger = UUID()
        do {
            try await user.getUser()
        } catch {
            print(error)
        }
    }
}

struct ShortcutItem: View {
    let name: String
    let icon: String
    let destination: AnyView

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.blue)
                    .symbolRenderingMode(.hierarchical)

                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// struct AboutView_Previews: PreviewProvider {
//    static var previews: some View {
//        AboutView()
//    }
// }
