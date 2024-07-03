//
//  AccountsAPIClient.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2023/10/17.
//

import Alamofire
import Foundation

enum AccountsModelError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
}

class AccountsViewModel: ObservableObject {
    @Published var accounts: Accounts?
    @Published var isLoading: Bool = false

    func getAccounts() async throws {
        isLoading = true
        let request = try RequestBuilder(apiURL: apiPaths.accounts)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw AccountsModelError.invalidResponse
        }

        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(Accounts.self, from: data)
            print(result)
            self.accounts = result
        } catch {
            throw AccountsModelError.invalidData
        }
        isLoading = false
    }
}
//extension AccountsViewModel {
//    static func mock() -> AccountsViewModel {
//        let viewModel = AccountsViewModel()
//        
//        let mockAccounts = Accounts(data: [
//        createMockAccou
//        ], meta: <#T##AccountsMeta?#>, links: <#T##AccountsLinks?#>)
//    }
//}
