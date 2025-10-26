import SwiftUI

struct SearchOption: View {
    var optionName: String
    var active: Bool
    var body: some View {
        Text(optionName)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Capsule(style: .continuous).fill(active ? Color.blue : Color.white))
            .foregroundStyle(active ? .red : .black)
            .contentShape(Capsule())
            .onTapGesture {
                withAnimation(.interactiveSpring()) {
                    print("tapped")
                }
            }
    }
}
