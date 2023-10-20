//
//  AccountsAPIClient.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2023/10/17.
//

import Foundation
import Alamofire


class AccountsAPIClient: ObservableObject {
    @Published private(set) var account: AccountData?
    
    init() {
        Task.init {
            await fetchData()
        }
    }
    
    func fetchData() async {
        let apiURL = "\(baseURL)/accounts/1/transactions"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(API_TOKEN)",
            "Accept": "application/json"
        ]
        
        AF.request(apiURL, method: .get, headers: headers)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: AccountData.self) {response in
                switch response.result {
                case .success(let accountData):
                    print(accountData)
                    self.account = accountData
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
    }
}
