//
//  Categories.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/07/09.
//

import Foundation

struct AddCategory: Codable {
    let name: String
    let notes: String?
}

enum AddCategoryError: Error {
    case invalidResponse
    case invalidData
}

func addCategory(params: AddCategory) async throws {
    var request = try RequestBuilder(apiURL: postApiPaths.addCategory, httpMethod: "POST")

    let encoder = JSONEncoder()
    let data = try encoder.encode(params)
    request.httpBody = data
    //print(request.url?.absoluteString)

    let (_, response) = try await URLSession.shared.data(for: request)
    print(response)

    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw AddCategoryError.invalidResponse
    }
}
