//
//  Loading.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/07/16.
//

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
