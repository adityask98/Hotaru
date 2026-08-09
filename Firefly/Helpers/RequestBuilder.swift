import Foundation

enum RequestBuilderError: Error {
    case urlError
    case requestError
    case missingBaseURL
    case missingToken
}

struct TokenObject: Codable {
    let accessToken: String
}

func RequestBuilder(apiURL: String, httpMethod: String = "GET", ignoreBaseURL: Bool = false) throws
-> URLRequest {
    guard let tokenObject = KeychainHelper.standard.read(
        service: KeychainConsts.accessToken,
        account: KeychainConsts.account,
        type: TokenObject.self
    ), !tokenObject.accessToken.isEmpty else {
        throw RequestBuilderError.missingToken
    }

    let endpoint: String
    if ignoreBaseURL {
        endpoint = apiURL
    } else {
        guard let baseURL = UserDefaults.standard.string(forKey: UserDefaultKeys.baseURLKey),
              !baseURL.isEmpty else {
            throw RequestBuilderError.missingBaseURL
        }
        endpoint = baseURL + apiURL
    }

    guard let url = URL(string: endpoint) else {
        throw RequestBuilderError.urlError
    }

    var request = URLRequest(url: url)
    request.httpMethod = httpMethod
    request.allHTTPHeaderFields = [
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer \(tokenObject.accessToken)",
    ]

    return request
}
