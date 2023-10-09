//
//  File.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2023/10/09.
//

import Foundation


struct UserData: Codable {
    let data: DataClass
}

struct DataClass: Codable {
    let type, id: String
    let attributes: Attributes
    let links: Links
}

struct Attributes: Codable {
    let createdAt, updatedAt: String
    let email: String
    let blocked: Bool
    let blockedCode: String?
    let role: String

    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case email, blocked
        case blockedCode = "blocked_code"
        case role
    }
}

struct Links: Codable {
    let the0: The0
    let linksSelf: String

    enum CodingKeys: String, CodingKey {
        case the0 = "0"
        case linksSelf = "self"
    }
}

struct The0: Codable {
    let rel, uri: String
}


