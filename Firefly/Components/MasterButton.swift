import SwiftUI

struct MasterButton: View {
    var icon: String?
    var label: String? = ""
    var textSize: CGFloat = 16
    var textWeight: Font.Weight = .semibold
    var textDesign: Font.Design = .rounded
    var color: Color = .blue
    var textColor: Color = .white
    var padding: CGFloat = 16
    var height: CGFloat = 48
    var fullWidth = false
    var align: Alignment = .center
    var cornerRadius: CGFloat = 16
    var disabled = false
    var loading = false
    let action: () -> Void

    var body: some View {
        HStack {
            if loading {
                ProgressView().tint(textColor).scaleEffect(textSize * 0.05).padding(.trailing, 1)
            }

            if let icon = icon {
                Image(systemName: icon).contentTransition(.symbolEffect)
            }
            Group {
                if let label = label {
                    Text(label).fixedSize(horizontal: true, vertical: false)
                }
            }
        }
        .fontSize(textSize, textWeight, design: textDesign)
        .padding(.horizontal, 10 * 1.5)
        .foregroundStyle(textColor)
        .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: height, alignment: align)
        .background(RoundedRectangle(cornerRadius: cornerRadius).fill(color))
        .highPriorityGesture(TapGesture().onEnded { action() })
        .disabled(disabled)
        .saturation(disabled ? 0 : 1)
        .opacity(disabled ? 0.65 : 1)
        .animation(.spring(), value: loading)
        .accessibilityLabel(Text(label ?? "Button"))
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    @Previewable @State var loading = false
    MasterButton(
        icon: "square.and.pencil", label: "Edit Transaction", disabled: false, loading: loading,
        action: { loading.toggle() }
    )
}
