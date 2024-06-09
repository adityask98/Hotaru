////
////  UserAPIClient.swift
////  Firefly
////
////  Created by Aditya Srinivasa on 2023/10/09.
////
//
//import Alamofire
//import Foundation
//
//class UserAPIClient: ObservableObject {
//    @Published private(set) var user: UserData?
//
//    func fetchData() async {
//        let token = API_TOKEN
//        let endpoint = "/about/user"
//        let apiURL = baseURL + endpoint
//        print(apiURL)
//        let headers: HTTPHeaders = [
//            "Authorization": "Bearer \(token)",
//            "Accept": "application/json",
//        ]
//
//        AF.request(apiURL, method: .get, headers: headers)
//            .validate(statusCode: 200..<300)
//            .responseDecodable(of: UserData.self) { response in
//                switch response.result {
//                case .success(let userData):
//                    print(userData)
//                    self.user = userData
//                case .failure(let error):
//                    print(response.data!)
//                    print("Error: \(error)")
//                }
//            }
//
//    }
//}
//
//// Transitioning to URLSession
//
////import Foundation
//
//enum DataError: Error {
//    case invalidData
//    case invalidResponse
//    case message(_ error: Error?)
//}
//
//class TempUserAPIClient {
//
//    let defaultURL = UserDefaults.standard.object(forKey: "DefaultURL")
//    static let shared = TempUserAPIClient()
//    private init() {}
//    
//    let url = URL(filePath: "http://100.96.204.49:8888/")
//    
//    
//    func fetchData(completion: @escaping (Result<[UserData]>, Error) -> Void) {
//        URLSession.shared.dataTask(with: url) { data, response, error in
//            guard let data else {
//                completion(.failure(.invalidData))
//            }
//        }
//    }
//}
