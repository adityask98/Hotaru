import Foundation
import SwiftUI

extension View {
    func fontSize(_ size: CGFloat, _ weight: Font.Weight = .regular, design: Font.Design = .default)
    -> some View {
        font(.system(size: size, weight: weight, design: design))
    }
}
