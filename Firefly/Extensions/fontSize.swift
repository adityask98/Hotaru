//
//  fontSize.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/08/18.
//

import Foundation
import SwiftUI

extension View {
    func fontSize(_ size: CGFloat, _ weight: Font.Weight = .regular, design: Font.Design = .default)
        -> some View
    {
        self.font(.system(size: size, weight: weight, design: design))
    }
}
