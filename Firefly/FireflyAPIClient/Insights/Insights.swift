//
//  Insights.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/07/28.
//

import Foundation

enum InsightsError: Error {
  case decodeError
  case categories
  case common
}

func fetchInsights<T: Codable>(for path: String) async throws -> T {
  let request = try RequestBuilder(apiURL: path)

  let (data, response) = try await URLSession.shared.data(for: request)
  guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
    throw InsightsError.common
  }

  let decoder = JSONDecoder()
  return try decoder.decode(T.self, from: data)
}
