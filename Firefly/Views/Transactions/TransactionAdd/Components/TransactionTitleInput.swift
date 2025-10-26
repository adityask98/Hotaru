import SwiftUI

struct TransactionTitleInput: View {
    @Binding var bindingText: String
    var disabled = false
    @State private var showSuggestions = true
    @FocusState private var focused: Bool
    @StateObject private var viewModel = DescriptionInputViewModel()

    var body: some View {
        VStack {
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
                //      Text("This is title")
                TextField("", text: $bindingText)
                    .multilineTextAlignment(.trailing)
                    .focused($focused)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .disabled(disabled)
            }
            if showSuggestions {
                Spacer()
                VStack(alignment: .leading) {
                    Text("Suggestions").font(.caption).fontWeight(.light)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
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
        var body: some View {
            VStack {
                List {
                    TransactionTitleInput(bindingText: $text)
                    TransactionTitleInput(bindingText: $text)
                }
            }
            .background(.background.secondary)
        }
    }
    return PreviewContainer()
}
