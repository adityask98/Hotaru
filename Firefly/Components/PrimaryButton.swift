import SwiftUI

struct PrimaryButton: View {
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
    /// Shows a spinner and blocks further taps, without the greyed-out `disabled` look.
    var loading = false
    let action: () -> Void

    /// Dynamic Type scale factor applied to the fixed text size
    @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1

    var body: some View {
        Button(action: action) {
            HStack {
                if loading {
                    ProgressView()
                        .tint(textColor)
                        .controlSize(.small)
                        .transition(.opacity.combined(with: .scale(scale: 0.6)))
                }

                if let icon {
                    Image(systemName: icon)
                }
                if let label {
                    Text(label).fixedSize(horizontal: true, vertical: false)
                }
            }
            .fontSize(textSize * typeScale, textWeight, design: textDesign)
            .padding(.horizontal, 15)
            .foregroundStyle(textColor)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: height, alignment: align)
            .background(RoundedRectangle(cornerRadius: cornerRadius).fill(color))
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(disabled || loading)
        .saturation(disabled ? 0 : 1)
        .opacity(disabled ? 0.65 : 1)
        .animation(.snappy, value: loading)
    }
}

/// Slight shrink and dim while pressed, so custom-drawn buttons still feel tappable.
/// The shrink is dropped under Reduce Motion; the dim is kept as the press cue.
struct PressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    @Previewable @State var loading = false
    PrimaryButton(
        icon: "square.and.pencil", label: "Edit Transaction", disabled: false, loading: loading,
        action: { loading.toggle() }
    )
}
