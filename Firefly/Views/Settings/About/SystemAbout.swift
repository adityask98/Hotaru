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
    VStack(alignment: .center, spacing: 20) {
      if viewModel.isLoading {
        VStack {
          LoadingSpinner()
          Text("Loading...").foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      } else if let errorMessage = viewModel.errorMessage {
        VStack(spacing: 10) {
          Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red).font(.largeTitle)
          Text("Something went wrong.").font(.headline).foregroundColor(.red)
          if !errorMessage.isEmpty {
            Text(errorMessage).font(.caption).foregroundColor(.secondary)
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      } else if let info = viewModel.systemInfo {
        ZStack {
          RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color(.systemBackground).opacity(0.9))
            .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
          VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
              Image(systemName: "info.circle.fill").foregroundColor(.accentColor)
              Text("About Firefly")
                .font(.title2.bold())
            }
            Divider()
            Group {
              Text("System Details").font(.headline).padding(.bottom, 4)
              Label("Firefly Client Version: \(info.version ?? "-")", systemImage: "app.fill")
              Label("API Version: \(info.apiVersion ?? "-")", systemImage: "hammer.fill")
              Label("PHP Version: \(info.phpVersion ?? "-")", systemImage: "terminal.fill")
              Label("OS: \(info.os ?? "-")", systemImage: "desktopcomputer")
              Label("Driver: \(info.driver ?? "-")", systemImage: "externaldrive.fill")
            }
            .fontDesign(.monospaced)
            Divider().padding(.vertical, 4)
            Link(destination: URL(string: "https://github.com/firefly-iii/firefly-iii")!) {
              HStack {
                Image(systemName: "link")
                Text("Project on GitHub")
                  .fontWeight(.semibold)
              }
              .padding(.vertical, 10)
              .padding(.horizontal, 18)
              .background(Color.accentColor.opacity(0.1))
              .foregroundStyle(.blue)
              .clipShape(Capsule())
            }
            Spacer(minLength: 0)
          }
          .padding(24)
        }
        .padding([.horizontal, .top], 20)
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity, alignment: .center)
      } else {
        Text("No data available").foregroundColor(.secondary)
      }
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    .onAppear { viewModel.fetchSystemInfo() }
    .background(Color(.secondarySystemGroupedBackground).ignoresSafeArea())
  }
}

#Preview {
  SystemAbout()
}
