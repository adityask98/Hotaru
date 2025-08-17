//
//  AddButton.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2025/05/11.
//

import SwiftUI

public struct FloatingButton: View {
  public var action: () -> Void
  public var imageSystemName: String = "plus"
  public var padding: CGFloat = 16
  public var foregroundColor: Color = .white
  public var backgroundColor: Color = .blue
  public var fontSize: CGFloat = 20
  public var fontWeight: Font.Weight = .medium
  public var shadowRadius: CGFloat = 4
  public var accessibilityLabel: String = "Add"

  @State private var isTapped = false
  @State private var feedbackTrigger = 0

  public init(
    action: @escaping () -> Void,
    imageSystemName: String = "plus",
    padding: CGFloat = 16,
    foregroundColor: Color = .white,
    backgroundColor: Color = .blue,
    fontSize: CGFloat = 20,
    fontWeight: Font.Weight = .medium,
    shadowRadius: CGFloat = 4,
    accessibilityLabel: String = "Add"
  ) {
    self.action = action
    self.imageSystemName = imageSystemName
    self.padding = padding
    self.foregroundColor = foregroundColor
    self.backgroundColor = backgroundColor
    self.fontSize = fontSize
    self.fontWeight = fontWeight
    self.shadowRadius = shadowRadius
    self.accessibilityLabel = accessibilityLabel
  }

  public var body: some View {
    Button(action: {
      feedbackTrigger += 1
      action()
    }) {
      Image(systemName: imageSystemName)
        .font(.system(size: fontSize))
        .fontWeight(fontWeight)
        .foregroundColor(foregroundColor)
        .frame(width: fontSize * 1, height: fontSize * 1)
        .padding(padding)
        .background(backgroundColor)
        .clipShape(Circle())
        .shadow(radius: shadowRadius)
    }
    .glassEffect(.regular.interactive())
    .buttonStyle(PlainButtonStyle())
    .padding()
    .accessibilityLabel(accessibilityLabel)
    .hoverEffect(.highlight)
    .sensoryFeedback(.impact, trigger: feedbackTrigger)
  }
}

#Preview {
  ZStack {
    Color.gray.opacity(0.2).edgesIgnoringSafeArea(.all)

    VStack {
      Spacer()
      HStack {
        Spacer()
        FloatingButton(action: {})
          .padding()
      }
    }
  }
}
