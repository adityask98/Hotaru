//
//  TransactionAddView.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2025/06/13.
//

import SwiftUI

struct TransactionAdd: View {
  @Environment(\.dismiss) var dismiss

  @StateObject private var viewModel = TransactionAddViewModel()

  var body: some View {

    NavigationView {
      VStack(alignment: .leading) {
        Picker(
          "",
          selection: Binding(
            get: { viewModel.transaction.type },
            set: { newValue in
              viewModel.updateTransaction { $0.type = newValue }
            }
          )

        ) {
          ForEach(TransactionTypeProperty.commonTypes, id: \.self) {
            Text($0.displayName)
          }
        }.pickerStyle(.segmented)
        TextField(
          "Description",
          text: Binding(
            get: { viewModel.transaction.description },
            set: { newValue in
              viewModel.updateTransaction { $0.description = newValue }
            }
          ))
        List {
          Section {
            TransactionTitleInput(bindingText: Binding(
              get: { viewModel.transaction.description },
              set: { newValue in
                viewModel.updateTransaction { $0.description = newValue }
              }
            ))

          }

        }

        Text(viewModel.transactionStore.transactions.first?.type.rawValue ?? "type error")
        Text(viewModel.transactionStore.transactions.first?.description ?? "error")
        Spacer()
      }
      .padding()
      .navigationTitle("Add Transaction").navigationBarTitleDisplayMode(.inline)
      .background(.background.secondary)
    }

  }
}
