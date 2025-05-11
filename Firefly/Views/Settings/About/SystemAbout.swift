//
//  AboutPage.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2025/05/11.
//

import SwiftUI

struct SystemAbout: View {
  @StateObject private var viewModel = SystemAboutViewModel()

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      if viewModel.isLoading {
        LoadingSpinner()
      } else if let errorMessage = viewModel.errorMessage {
        Text("Something went wrong.").foregroundColor(.red)
      } else if let info = viewModel.systemInfo {
        Group {
          Text("Firefly Client Version: \(info.version ?? "-")")
          Text("API Version: \(info.apiVersion ?? "-")")
          Text("PHP Version: \(info.phpVersion ?? "-")")
          Text("OS: \(info.os ?? "-")")
          Text("Driver: \(info.driver ?? "-")")
          Link(
            destination: URL(
              string: "https://github.com/firefly-iii/firefly-iii")!
          ) {
            Text("About Firefly").fontDesign(.default).foregroundStyle(.blue)
          }
            Spacer()
        }
        .fontDesign(.monospaced)
      } else {
        Text("No data available")
      }
    }
    .padding()
    .onAppear { viewModel.fetchSystemInfo() }
  }
}

#Preview {
  SystemAbout()
}
