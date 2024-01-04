//
//  UserAPIClient.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2023/10/09.
//

import Foundation
import Alamofire

class UserAPIClient: ObservableObject {
    @Published private(set) var user: UserData?  
    
    func fetchData() async {
        let token = API_TOKEN
        let endpoint = "/about/user"
        let apiURL = baseURL + endpoint
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        
        AF.request(apiURL, method: .get, headers: headers)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: UserData.self) {response in
                switch response.result {
                case .success(let userData):
                    print(userData)
                    self.user = userData
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
        
    }
}

