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
    
    init() {
        Task.init {
            await fetchData()
        }
    }
    
    
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
    
     func oldfetchData() async {
         let jsonString = "{\"data\":{\"type\":\"users\",\"id\":\"1\",\"attributes\":{\"created_at\":\"2023-06-09T20:43:45+02:00\",\"updated_at\":\"2023-06-09T20:43:46+02:00\",\"email\":\"adityask98@gmail.com\",\"blocked\":false,\"blocked_code\":null,\"role\":\"owner\"},\"links\":{\"self\":\"http:\\/\\/100.69.222.106:9999\\/api\\/v1\\/users\\/1\",\"0\":{\"rel\":\"self\",\"uri\":\"\\/users\\/1\"}}}}"
        let jsonData = jsonString.data(using: .utf8)
        let token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiI2NyIsImp0aSI6Ijc5YWNlM2NiZGQxODA5OGYxM2NkNGJjODFlMDcxNTE4MDIzMWUzYWFmMmM0YzcyM2ZmZjYwMDg4ZDkwMjMyNjdiNDg2OWRmNTI1Y2NjNGJkIiwiaWF0IjoxNjk2ODM3NjA2LjcyNDc1OCwibmJmIjoxNjk2ODM3NjA2LjcyNDc2OCwiZXhwIjoxNzI4NDYwMDA2LjE3Mzk4Niwic3ViIjoiMSIsInNjb3BlcyI6W119.PEyaQDftbZmgSrpq1exSWLUxffhDg23YFpZSBwirOcZCIxVLxFJG0Qx-s_l0iP4QZadoVcGP7-1YMYk1uc25Y6ojZVOYOtp1kEUQM2lMQlyepF1jjJFrzUCoKj-QmvXXiu-yMMZ5uBvM4Fbn6aWovI7t7mj0Hxi38TOQHoIN0HyeIV22OuPM0og97vYQ1eUwLGslgSmXyEll_uJNzn9sPu9mZU4aY37gIIADbo9FALx-Q7F2LF0hy9PLyqIlLYxV50kNTSWlHzaaHeBi178qWzy-bMujG6xMYVvAmom6nBTrFDzjAUszYs70lCGsNrzMLjx0PpVeq57asTWjlhTY_caDLEaHCTCzwWvBU40ts7COtKdby5IRcSmc2TfxOkEaUgarU2x8Pj0yvabUW-kqoaKlNuhvD8vTCIwJTM91cl6FfJ_eoPiG-6pBf8ZiHeylWLn6hhuvNCthr_zTclJZmLWg7sGy2HJ-ikiNHuEITwtxRWDpY0oREcTgtJV7GWEQ5Uo_y5m4TAJNixo4q64W_M3Ccx0zJeAqlmykr2iw8dID-cnj2zKPQfUxdyi7d7eaeZNrYNRvmX8sDU_eyVKaYoVLRLO0wj-yRE3MB17U6g0qZkGxwhowq8Yih3P56sqHVdpKiSdJfCn1aZqkZClG_wMCwkeZBq7Y5apI3cWn56I"
         
        guard let url = URL(string: "http://100.69.222.106:9999/api/v1/about/user") else {fatalError("URL Error")}
        var urlRequest = URLRequest(url: url)
        urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
         urlRequest.httpMethod = "GET"
        do{
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            print(String(data: data, encoding: .utf8))

            let decoder = JSONDecoder()
            //decoder.keyDecodingStrategy = .convertFromSnakeCase
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {fatalError("Error Occurred during API call??")}
            print(response)
            
          
            let decodedData = try decoder.decode(UserData.self, from: data)
            DispatchQueue.main.async {
                self.user = decodedData
            }
           
        } catch {
            print("Error \(error)")
        }
    }
}

