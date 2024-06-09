//
//  File.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2023/10/09.
//

import Foundation

struct UserModel: Codable {
    let data: DataClass?
}

struct DataClass: Codable {
    let type, id: String?
    let attributes: Attributes?
    let links: Links?
}

struct Attributes: Codable {
    let createdAt, updatedAt: String?
    let email: String?
    let blocked: Bool?
    let blockedCode: String?
    let role: String?

    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case email, blocked
        case blockedCode = "blocked_code"
        case role
    }
}

struct Links: Codable {
    let the0: The0?
    let linksSelf: String?

    enum CodingKeys: String, CodingKey {
        case the0 = "0"
        case linksSelf = "self"
    }
}

struct The0: Codable {
    let rel, uri: String?
}

enum UserModelError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
}

func getUser() async throws -> UserModel {
    let baseURL = UserDefaults.standard.object(forKey: "DefaultURL")
    let token = UserDefaults.standard.object(forKey: "APIToken")
    let apiURL = "api/v1/about/user"
    let headers = [
        "Authorization": "Bearer \(token as! String)"
    ]

    let endpoint = baseURL as! String + apiURL
    guard let url = URL(string: endpoint) else {
        throw UserModelError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = headers

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw UserModelError.invalidResponse
    }

    do {
        let decoder = JSONDecoder()
        return try decoder.decode(UserModel.self, from: data)
    } catch {
        throw UserModelError.invalidData
    }
}
