import Combine
import Foundation

class MenuViewModel: ObservableObject {
    @Published var tokenSheetShown = false
    @Published var hasCheckedToken = false
    @Published var transactionSheetShown = false
    @Published var shouldRefresh = false
    @Published var searchSheetShown = false
    @Published var transactionAddSheetShown = false // New transction add page

    // private var tokenSettingsValue = TokenSettingsViewModel()

    func openTransactionSheet() {
        transactionSheetShown = true
    }

    func openSearchSheet() {
        searchSheetShown = true
    }

    func openTransactionAddSheet() {
        transactionAddSheetShown = true
    }
}
