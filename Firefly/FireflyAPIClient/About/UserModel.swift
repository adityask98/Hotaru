import Foundation

struct User: Codable {
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

func getUser() async throws -> User {
    let request = try RequestBuilder(apiURL: ApiPaths.userAbout)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw UserModelError.invalidResponse
    }

    do {
        let decoder = JSONDecoder()
        return try decoder.decode(User.self, from: data)
    } catch {
        throw UserModelError.invalidData
    }
}

@MainActor
final class UserModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    // @Published var errorMessage: String

    func getUser() async throws {
        isLoading = true
        let request = try RequestBuilder(apiURL: ApiPaths.userAbout)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw UserModelError.invalidResponse
        }

        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(User.self, from: data)
            user = result
        } catch {
            throw UserModelError.invalidData
        }
        isLoading = false
    }
}
