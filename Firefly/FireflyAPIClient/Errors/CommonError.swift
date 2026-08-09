import Foundation

struct CommonError: Codable {
    let message: String?
    let exception: String?
}

enum CommonErrorThrow: Error {
    case decodeError
}

func errorDecoder(_ errorData: Data) throws -> CommonError {
    do {
        let decoder = JSONDecoder()
        return try decoder.decode(CommonError.self, from: errorData)
    } catch {
        throw CommonErrorThrow.decodeError
    }
}
