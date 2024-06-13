//
//  RequestBuilder.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/06/09.
//

import Foundation

enum RequestBuilderError: Error {
    case urlError
    case requestError
}

struct TokenObject: Codable {
    let accessToken: String
}

func RequestBuilder(apiURL: String, httpMethod: String = "GET") throws -> URLRequest {
    let baseURL = UserDefaults.standard.object(forKey: UserDefaultKeys.baseURLKey) as! String
    //let token = UserDefaults.standard.object(forKey: UserDefaultKeys.apiTokenKey) as! String
    let token = KeychainHelper.standard.read(
        service: keychainConsts.accessToken, account: keychainConsts.account,
        type: TokenObject.self)!.accessToken

    let headers = [
        "Authorization": "Bearer \(token)"
    ]

    let endpoint = baseURL + apiURL

    guard let url = URL(string: endpoint) else {
        throw RequestBuilderError.urlError
    }

    var request = URLRequest(url: url)
    request.httpMethod = httpMethod
    request.allHTTPHeaderFields = headers

    return request
}
