import SwiftUI

struct TransactionTitleInput: View {
    @Binding var bindingText: String
    @Binding var showSuggestions: Bool
    var disabled = false
    var buttonText = "None"
    var buttonAction: () -> Void = {}

    @FocusState private var focused: Bool
    @StateObject private var viewModel = DescriptionInputViewModel()

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "list.bullet")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .padding(10)
                    .background(Color.gray.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Text("Title")
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(minWidth: 70, alignment: .leading)

                Spacer()

                TextField("", text: $bindingText)
                    .multilineTextAlignment(.trailing)
                    .focused($focused)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .disabled(disabled)
                    .keyboardType(.decimalPad)

                Divider()
                    .frame(height: 25)

                Button(action: buttonAction) {
                    Text(buttonText)
                        .foregroundStyle(.gray)
                }
            }

            if showSuggestions {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggestions")
                        .font(.caption)
                        .fontWeight(.light)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            SuggestionChip(label: "TEST")
                            SuggestionChip(label: "TESTTESTTEST")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    struct PreviewContainer: View {
        @State var text = "TestValue"
        @State var showSuggestions = true

        var body: some View {
            VStack(spacing: 16) {
                Button {
                    showSuggestions.toggle()
                } label: {
                    Label(
                        "Toggle Suggestions (\(showSuggestions ? "ON" : "OFF"))",
                        systemImage: showSuggestions ? "eye.fill" : "eye.slash.fill"
                    )
                }
                .buttonStyle(.bordered)
                .padding()

                List {
                    TransactionTitleInput(
                        bindingText: $text,
                        showSuggestions: $showSuggestions,
                        buttonText: "JPY (¥)",
                        buttonAction: {
                            print("Currency button tapped")
                        }
                    )

                    TransactionTitleInput(
                        bindingText: $text,
                        showSuggestions: $showSuggestions,
                        buttonText: "USD ($)",
                        buttonAction: {
                            print("USD selected")
                        }
                    )
                }
            }
            .background(.background.secondary)
        }
    }
    return PreviewContainer()
}
