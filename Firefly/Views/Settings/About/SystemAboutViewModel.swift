//
//  SystemAboutViewModel.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2025/05/11.
//

import Foundation

struct SystemInfo: Codable {
  let data: SystemInfoDataClass?
}
struct SystemInfoDataClass: Codable {
  let version: String?
  let apiVersion: String?
  let phpVersion: String?
  let os: String?
  let driver: String?

  enum CodingKeys: String, CodingKey {
    case version
    case apiVersion = "api_version"
    case phpVersion = "php_version"
    case os, driver
  }
}

class SystemAboutViewModel: ObservableObject {
  @Published var systemInfo: SystemInfoDataClass?
  @Published var isLoading = true
  @Published var errorMessage: String?
  private var fetchTask: Task<Void, Never>?

  func fetchSystemInfo() {
    errorMessage = nil
    fetchTask?.cancel()
    isLoading = true
    fetchTask = Task {
      do {
        try await performFetch()
        if Task.isCancelled { return }
      } catch {
        if Task.isCancelled { return }
        self.errorMessage = error.localizedDescription
        self.isLoading = false
      }
    }
  }

  @MainActor
  func performFetch() async throws {
    var request = try RequestBuilder(apiURL: apiPaths.systemAbout)
    let (data, response) = try await URLSession.shared.data(for: request)

    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
      return
    }

    do {
      let decoder = JSONDecoder()
      let result = try decoder.decode(SystemInfo.self, from: data)
      self.systemInfo = result.data
      self.isLoading = false
      #if DEBUG
        print("systeminfo: \(String(describing: self.systemInfo))")
      #endif
    }
  }
}
