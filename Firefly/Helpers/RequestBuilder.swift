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

func RequestBuilder(apiURL: String, httpMethod: String = "GET", ignoreBaseURL: Bool = false) throws
  -> URLRequest
{
  let baseURL: String
  if let savedBaseURL = UserDefaults.standard.string(forKey: UserDefaultKeys.baseURLKey) {
    baseURL = savedBaseURL
  } else {
    // Provide a default value or handle the error
    baseURL = "https://default.url.com"
    // Optionally, you might want to log this or show an error to the user
    print("Warning: Base URL not found in UserDefaults")
  }  //let token = UserDefaults.standard.object(forKey: UserDefaultKeys.apiTokenKey) as! String
  let token: String
  if let tokenObject = KeychainHelper.standard.read(
    service: keychainConsts.accessToken,
    account: keychainConsts.account,
    type: TokenObject.self
  ) {
    token = tokenObject.accessToken
  } else {
    // Handle the case where the token doesn't exist or can't be read
    print("Error: Unable to read access token from Keychain")
    // You might want to throw an error here, or handle it in some other way
    // For example, you could return early from the function:
    // return
    // Or set a default value (though this is probably not appropriate for an access token):
    token = ""
    // Or perhaps trigger a re-authentication flow:
    // triggerReAuthentication()
    // For now, let's throw an error:
    //throw KeychainError.itemNotFound
  }
  let headers = [
    "Content-Type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer \(token)",
  ]

  var endpoint = baseURL + apiURL
  if ignoreBaseURL {
    endpoint = apiURL
  }
  guard let url = URL(string: endpoint) else {
    throw RequestBuilderError.urlError
  }

  var request = URLRequest(url: url)
  request.httpMethod = httpMethod
  request.allHTTPHeaderFields = headers

  return request
}
