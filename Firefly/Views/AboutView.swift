import SwiftUI

struct AboutView: View {
    @ObservedObject private var user = UserModel()
    @State private var transactions = TransactionsViewModel()
    @EnvironmentObject var menuViewModel: MenuViewModel
    @State private var refreshTrigger = UUID()

    var body: some View {
        NavigationView {
            ScrollView {
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

// struct AboutView_Previews: PreviewProvider {
//    static var previews: some View {
//        AboutView()
//    }
// }
