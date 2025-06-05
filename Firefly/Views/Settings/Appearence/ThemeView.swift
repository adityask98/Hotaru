//
//  SwiftUIView.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2025/06/05.
//

import SwiftUI

enum ThemeMode: String, CaseIterable {
  case light = "Light"
  case dark = "Dark"
  case system = "System"
}

struct ThemeView: View {
  @AppStorage("selectedTheme") private var selectedTheme: ThemeMode = .system

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Theme")
        .font(.title2)
        .fontWeight(.semibold)
        .padding(.horizontal)

      VStack(spacing: 12) {
        ForEach(ThemeMode.allCases, id: \.self) { theme in
          HStack {
            Button(action: {
              selectedTheme = theme
            }) {
              HStack {
                Image(systemName: selectedTheme == theme ? "largecircle.fill.circle" : "circle")
                  .foregroundColor(selectedTheme == theme ? .blue : .gray)
                Text(theme.rawValue)
                  .foregroundColor(.primary)
                Spacer()
              }
              .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
          }
          .padding(.horizontal)
        }
      }

      Spacer()
    }
    .navigationTitle("Appearance")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  ThemeView()
}
