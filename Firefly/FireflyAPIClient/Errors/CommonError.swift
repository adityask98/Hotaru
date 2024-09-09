//
//  CommonError.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/09/09.
//

import Foundation

struct CommonError: Codable {
    let message: String?
    let exception: String?
}

enum CommonErrorThrow: Error {
    case decodeError
}

func ErrorDecoder(_ errorData: Data) throws -> CommonError {
    do {
        let decoder = JSONDecoder()
        let errorResult = try decoder.decode(CommonError.self, from: errorData)
        return errorResult
    } catch {
        throw CommonErrorThrow.decodeError
    }
}
