//
//  AuthInfo.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/01/04.
//

import SwiftUI

struct AuthInfo: View {
    @AppStorage("Number String") var counter = 0
    var body: some View {
        VStack {
            Text("\(counter)")
                .onTapGesture {
                    counter += 1
                }
        }
    }
}

#Preview {
    AuthInfo()
}
