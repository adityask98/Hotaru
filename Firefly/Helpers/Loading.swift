import SwiftUI

struct LoadingSpinner: View {
    var body: some View {
        Spacer()
        HStack(alignment: .center) {
            Spacer()
            ProgressView()
            Spacer()
        }
        Spacer()
    }
}

#Preview {
    LoadingSpinner()
}
