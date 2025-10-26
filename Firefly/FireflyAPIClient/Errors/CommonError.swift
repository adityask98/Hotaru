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
        let errorResult = try decoder.decode(CommonError.self, from: errorData)
        return errorResult
    } catch {
        throw CommonErrorThrow.decodeError
    }
}
