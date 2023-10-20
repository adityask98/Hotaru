//
//  AccountView.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2023/10/20.
//

import SwiftUI

struct AccountView: View {
@StateObject var accountsAPIClient = AccountsAPIClient()
    var body: some View {
        VStack {
            if let account = accountsAPIClient.account {
                
            } else {
                Text("Loading")
            }
            Button("Fetch") {
                Task {
                    await accountsAPIClient.fetchData()
                }
            }
        }
        .padding()
    }
    
}


struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView()
    }
}
